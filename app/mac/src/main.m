
#import <Cocoa/Cocoa.h>

#include "nodeapp_licensing.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        nodeapp_licensing_startup();
    }
    return NSApplicationMain(argc,  (const char **) argv);
}
