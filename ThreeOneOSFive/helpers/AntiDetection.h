//
//  AntiDetection.h
//  3105
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AntiDetection : NSObject

/// Starts the kernel-level anti-debugging & anti-tamper security guardian.
+ (void)enforceHardenedSecurity;

/// Returns YES if active debugging, hooking frameworks, or injected dylibs are detected.
+ (BOOL)isDeviceTampered;

/// Checks sysctl and exception ports for debugger presence.
+ (BOOL)isDebuggerAttached;

/// Scans Mach-O loaded images for Frida, Substrate, and reverse-engineering frameworks.
+ (BOOL)hasInjectedDylibs;

@end

NS_ASSUME_NONNULL_END
