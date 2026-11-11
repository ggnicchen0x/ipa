//
//  AntiDetection.m
//  3105
//
//  Hardened runtime shield.
//  - fork() denial: defeats common jailbreak-detection probes (safe; app never forks).
//  - Anti-debug: PT_DENY_ATTACH + sysctl P_TRACED poll; raises tamper flag.
//  - Integrity: hashes Info.plist and the main bundle identifier on launch
//    and exposes the fingerprint so Swift can gate protected logic.
//  - Symbol obfuscation via visibility=hidden for internal helpers.
//
//  All checks fail-open for the UI (never crash the app) but set a monotonically
//  increasing tamper counter that AuthService consults before trusting sessions.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/proc.h>
#import <unistd.h>
#import <errno.h>
#import <dlfcn.h>
#import <stdatomic.h>
#import <CommonCrypto/CommonDigest.h>

#define TG_HIDDEN  __attribute__((visibility("hidden")))
#define TG_NOINLINE __attribute__((noinline))

// ---------------------------------------------------------------------------
// fork() denial (retained from previous build)
// ---------------------------------------------------------------------------
pid_t fork(void) {
    errno = EAGAIN;
    return -1;
}

// ---------------------------------------------------------------------------
// Tamper state — exposed read-only to Swift
// ---------------------------------------------------------------------------
static atomic_uint_fast32_t g_tamperCount = 0;
static atomic_uint_fast64_t g_integrityFingerprint = 0;

uint32_t TGTamperCount(void) {
    return (uint32_t)atomic_load_explicit(&g_tamperCount, memory_order_relaxed);
}

uint64_t TGIntegrityFingerprint(void) {
    return (uint64_t)atomic_load_explicit(&g_integrityFingerprint, memory_order_relaxed);
}

TG_HIDDEN TG_NOINLINE
static void tg_bump_tamper(uint32_t reason_tag) {
    (void)reason_tag;
    atomic_fetch_add_explicit(&g_tamperCount, 1, memory_order_relaxed);
}

// ---------------------------------------------------------------------------
// Anti-debug: ptrace(PT_DENY_ATTACH, ...)
// Rejects most userland debuggers. PT_DENY_ATTACH == 31 on Darwin.
// Linked via dlsym to avoid static symbol exposure in the binary.
// ---------------------------------------------------------------------------
typedef int (*ptrace_ptr_t)(int, pid_t, caddr_t, int);

TG_HIDDEN TG_NOINLINE
static void tg_arm_ptrace_shield(void) {
    void *handle = dlopen(0, RTLD_NOW);
    if (!handle) return;
    // Obfuscated symbol literal; reassembled at runtime so plain `strings` misses it.
    char sym[8];
    sym[0] = 'p'; sym[1] = 't'; sym[2] = 'r';
    sym[3] = 'a'; sym[4] = 'c'; sym[5] = 'e';
    sym[6] = 0;
    ptrace_ptr_t pt = (ptrace_ptr_t)dlsym(handle, sym);
    if (pt) {
        pt(31 /* PT_DENY_ATTACH */, 0, 0, 0);
    }
}

// ---------------------------------------------------------------------------
// sysctl-based P_TRACED probe (defense in depth; detects attach after launch)
// ---------------------------------------------------------------------------
TG_HIDDEN TG_NOINLINE
static int tg_is_being_traced(void) {
    struct kinfo_proc info;
    size_t size = sizeof(info);
    memset(&info, 0, sizeof(info));
    int mib[4];
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    if (sysctl(mib, 4, &info, &size, NULL, 0) != 0) {
        return 0;
    }
    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

// ---------------------------------------------------------------------------
// Integrity: SHA-256 Info.plist + bundle identifier fingerprint
// ---------------------------------------------------------------------------
TG_HIDDEN TG_NOINLINE
static uint64_t tg_fold_sha256(const uint8_t *digest) {
    uint64_t folded = 0;
    for (int i = 0; i < 8; ++i) {
        folded ^= ((uint64_t)digest[i * 4 + 0]) << ((i * 8) & 63);
        folded ^= ((uint64_t)digest[i * 4 + 1]) << (((i * 8) + 16) & 63);
    }
    return folded;
}

TG_HIDDEN TG_NOINLINE
static void tg_compute_integrity_fingerprint(void) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        if (!bundle) return;

        // 1. Info.plist bytes (located at the bundle root, not via pathForResource)
        NSString *plistPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Info.plist"];
        NSData *plistData = [NSData dataWithContentsOfFile:plistPath];

        // 2. Bundle identifier
        NSString *bid = [bundle bundleIdentifier] ?: @"";
        NSData *bidData = [bid dataUsingEncoding:NSUTF8StringEncoding];

        // 3. Executable path existence (the .app/<binary> that signatures sign over)
        NSString *execPath = [[bundle executablePath] lastPathComponent] ?: @"";
        NSData *execData = [execPath dataUsingEncoding:NSUTF8StringEncoding];

        CC_SHA256_CTX ctx;
        CC_SHA256_Init(&ctx);
        if (plistData.length > 0) {
            CC_SHA256_Update(&ctx, plistData.bytes, (CC_LONG)plistData.length);
        } else {
            tg_bump_tamper(1);
        }
        if (bidData.length > 0) {
            CC_SHA256_Update(&ctx, bidData.bytes, (CC_LONG)bidData.length);
        }
        if (execData.length > 0) {
            CC_SHA256_Update(&ctx, execData.bytes, (CC_LONG)execData.length);
        }

        uint8_t digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(digest, &ctx);
        uint64_t folded = tg_fold_sha256(digest);
        atomic_store_explicit(&g_integrityFingerprint, folded, memory_order_relaxed);

        // 4. Validate _CodeSignature exists — missing signature on a tampered IPA
        NSString *sigDir = [[bundle bundlePath] stringByAppendingPathComponent:@"_CodeSignature"];
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:sigDir isDirectory:&isDir] || !isDir) {
            tg_bump_tamper(2);
        }
    }
}

// ---------------------------------------------------------------------------
// Periodic re-check: late attach, repackaging mid-session
// ---------------------------------------------------------------------------
TG_HIDDEN
static void tg_schedule_periodic_check(void) {
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    if (!timer) return;
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)),
                              (uint64_t)(20 * NSEC_PER_SEC),
                              (uint64_t)(2 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(timer, ^{
        if (tg_is_being_traced()) {
            tg_bump_tamper(3);
        }
    });
    dispatch_resume(timer);
    // Intentionally retain by not releasing — lifetime matches process.
}

// ---------------------------------------------------------------------------
// Load-time entry — runs before main(), no explicit call needed
// ---------------------------------------------------------------------------
__attribute__((constructor))
TG_HIDDEN
static void tg_shield_init(void) {
    tg_arm_ptrace_shield();
    if (tg_is_being_traced()) {
        tg_bump_tamper(4);
    }
    tg_compute_integrity_fingerprint();
    tg_schedule_periodic_check();
}
