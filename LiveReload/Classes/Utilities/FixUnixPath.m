
#import "FixUnixPath.h"

#import "NSTask+OneLineTasksWithOutput.h"

void FixUnixPath() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
        NSLog(@"User's shell is %@", userShell);

        // avoid executing stuff like /sbin/nologin as a shell
        BOOL isValidShell = NO;
        for (NSString *validShell in [[NSString stringWithContentsOfFile:@"/etc/shells" encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            if ([[validShell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:userShell]) {
                isValidShell = YES;
                break;
            }
        }

        if (!isValidShell) {
            NSLog(@"Shell %@ is not in /etc/shells, won't continue.", userShell);
            return;
        }
        NSString *userPath = [[NSTask stringByLaunchingPath:userShell withArguments:[NSArray arrayWithObjects:@"--login", @"-c", @"echo $PATH", nil] error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (userPath.length > 0 && [userPath rangeOfString:@":"].length > 0 && [userPath rangeOfString:@"/usr/bin"].length > 0) {
            // BINGO!
            NSLog(@"User's PATH as reported by %@ is %@", userShell, userPath);
            setenv("PATH", [userPath fileSystemRepresentation], 1);
        }
    });
}
