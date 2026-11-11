#import "exploit/bad_query.h"
#import "exploit/mcm_bridge.h"
#import "kexploit/kexploit_opa334.h"
#import "kexploit/sandbox_escape.h"
#import "kexploit/kutils.h"
#import "helpers/AppIconHelper.h"
#import "helpers/DisplayIdentity.h"

#include <stdint.h>
// Hardened runtime shield surface (implemented in helpers/AntiDetection.m).
uint32_t TGTamperCount(void);
uint64_t TGIntegrityFingerprint(void);
