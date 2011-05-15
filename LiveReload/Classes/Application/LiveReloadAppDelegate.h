
#import <Cocoa/Cocoa.h>

@class StatusItemController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
}

@property(nonatomic, retain) IBOutlet StatusItemController *statusItemController;

@end
