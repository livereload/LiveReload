
#import <Cocoa/Cocoa.h>

#import "LicenseManager.h"
#import "FSEventsFix.h"

int main(int argc, char *argv[])
{
    FSEventsFixInstall();
    @autoreleasepool {
        LicenseManagerStartup();
    }
    return NSApplicationMain(argc,  (const char **) argv);
}
