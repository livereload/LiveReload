
#import "StatusItemController.h"


@interface StatusItemController ()

@property(nonatomic, retain) NSStatusItem *statusItem;

@end


@implementation StatusItemController

@synthesize statusItem=_statusItem;

- (void)showStatusBarIcon {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setTitle:@"LR"];
    [self.statusItem setTarget:self];
    [self.statusItem setAction:@selector(statusIconClicked)];
    [self.statusItem setHighlightMode:YES];
}

- (IBAction)statusIconClicked {
    NSLog(@"Clicked!");
}

@end
