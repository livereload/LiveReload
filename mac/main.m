
#import <Cocoa/Cocoa.h>

#import "FSEventsFix.h"
#import "LicenseManager.h"

int main(int argc, char *argv[])
{
    FixFSEvents();
    @autoreleasepool {
        LicenseManagerStartup();
    }
    return NSApplicationMain(argc,  (const char **) argv);
}
