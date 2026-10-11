//
//  AntiDetection.m
//  3105
//
//  Hardened Kernel-Level Anti-Debugging, Anti-Hooking & Anti-Tamper Shield
//

#import "AntiDetection.h"
#import <unistd.h>
#import <errno.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/task.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

// PT_DENY_ATTACH ptrace request constant
#ifndef PT_DENY_ATTACH
#define PT_DENY_ATTACH 31
#endif

typedef int (*ptrace_ptr_t)(int request, pid_t pid, caddr_t addr, int data);

static dispatch_source_t s_watchdog_timer = NULL;
static BOOL s_hardened_enforced = NO;

// Any fork() call from this process fails immediately.
// This defeats jailbreak-detection tests that check whether fork() succeeds.
pid_t fork(void) {
    errno = EAGAIN;
    return -1;
}

@implementation AntiDetection

+ (void)enforceHardenedSecurity {
    if (s_hardened_enforced) return;
    s_hardened_enforced = YES;

    // 1. Immediate Anti-Debug via dynamic ptrace PT_DENY_ATTACH
    [self applyPtraceDenyAttach];

    // 2. Immediate check
    if ([self isDeviceTampered]) {
        _exit(0xDEAD);
    }

    // 3. Periodic Background Security Watchdog (every 2.5 seconds)
    dispatch_queue_t queue = dispatch_queue_create("com.threeoneosfive.security.watchdog", DISPATCH_QUEUE_SERIAL);
    s_watchdog_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (s_watchdog_timer) {
        dispatch_source_set_timer(s_watchdog_timer, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), 2500 * NSEC_PER_MSEC, 200 * NSEC_PER_MSEC);
        dispatch_source_set_event_handler(s_watchdog_timer, ^{
            if ([AntiDetection isDeviceTampered]) {
                _exit(0xDEAD);
            }
        });
        dispatch_resume(s_watchdog_timer);
    }
}

+ (void)applyPtraceDenyAttach {
    void *handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
    if (handle) {
        ptrace_ptr_t ptrace_func = (ptrace_ptr_t)dlsym(handle, "ptrace");
        if (ptrace_func) {
            ptrace_func(PT_DENY_ATTACH, 0, 0, 0);
        }
        dlclose(handle);
    }
}

+ (BOOL)isDeviceTampered {
    if ([self isDebuggerAttached]) {
        return YES;
    }
    if ([self hasInjectedDylibs]) {
        return YES;
    }
    if ([self hasFridaActive]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isDebuggerAttached {
    // 1. Sysctl check for P_TRACED
    int mib[4];
    struct kinfo_proc info;
    size_t size;

    info.kp_proc.p_flag = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    size = sizeof(info);

    if (sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0) == 0) {
        if ((info.kp_proc.p_flag & P_TRACED) != 0) {
            return YES;
        }
    }

    // 2. Exception Ports Check (typical of LLDB / DebugServer hooking)
    mach_msg_type_number_t count = 0;
    exception_mask_t masks[EXC_TYPES_COUNT];
    mach_port_t ports[EXC_TYPES_COUNT];
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];

    kern_return_t kr = task_get_exception_ports(
        mach_task_self(),
        EXC_MASK_BAD_ACCESS | EXC_MASK_BREAKPOINT,
        masks,
        &count,
        ports,
        behaviors,
        flavors
    );

    if (kr == KERN_SUCCESS) {
        for (mach_msg_type_number_t i = 0; i < count; i++) {
            if (MACH_PORT_VALID(ports[i])) {
                // An active debug handler has been attached
                return YES;
            }
        }
    }

    return NO;
}

+ (BOOL)hasInjectedDylibs {
    // 1. Check DYLD_INSERT_LIBRARIES environment variable
    char *dyld_insert = getenv("DYLD_INSERT_LIBRARIES");
    if (dyld_insert != NULL && strlen(dyld_insert) > 0) {
        return YES;
    }

    // 2. Blacklist of known hooking, debugging, and interception frameworks
    static const char *blacklisted[] = {
        "FridaGadget",
        "frida-agent",
        "cydiasubstrate",
        "libhooker",
        "SubstrateLoader",
        "SSLKillSwitch",
        "Shadow.dylib",
        "FLEX.dylib",
        "Cycript",
        "tweakloader",
        "Cephei",
        "insert_dylib",
        "SubstrateBootstrap",
        "libsparkapplist"
    };
    const size_t blacklist_count = sizeof(blacklisted) / sizeof(blacklisted[0]);

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (!image_name) continue;

        for (size_t b = 0; b < blacklist_count; b++) {
            if (strcasestr(image_name, blacklisted[b]) != NULL) {
                return YES;
            }
        }
    }

    return NO;
}

+ (BOOL)hasFridaActive {
    // Probe default Frida listening socket on localhost:27042
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return NO;

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 25000; // 25ms timeout
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char *)&tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (const char *)&tv, sizeof(tv));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(27042);
    inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

    BOOL connected = NO;
    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
        connected = YES;
    }
    close(sock);
    return connected;
}

@end
