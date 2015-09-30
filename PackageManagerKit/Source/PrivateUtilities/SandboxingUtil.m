#import "SandboxingUtil.h"

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <assert.h>

NSString *ATRealHomeDirectory() {
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    return [NSString stringWithUTF8String:pw->pw_dir];
}

BOOL ATIsSandboxed() {
    return [NSHomeDirectory() compare:ATRealHomeDirectory() options:NSCaseInsensitiveSearch] != NSOrderedSame;
}
