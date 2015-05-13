
#import <Cocoa/Cocoa.h>

#import "FSEventsFix.h"
#import "LicenseManager.h"

int main(int argc, char *argv[])
{
    FSEventsFixApply();
    @autoreleasepool {
        LicenseManagerStartup();
    }
    return NSApplicationMain(argc,  (const char **) argv);
}
