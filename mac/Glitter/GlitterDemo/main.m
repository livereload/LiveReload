
#import <Cocoa/Cocoa.h>
#import "Glitter.h"

Glitter *sharedGlitter;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        sharedGlitter = [[Glitter alloc] initWithMainBundle];
    }

    return NSApplicationMain(argc, argv);
}
