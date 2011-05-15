
#import "StatusItemController.h"


@interface StatusItemController ()

@property(nonatomic, retain) NSStatusItem *statusItem;

@end


@implementation StatusItemController

@synthesize statusItem=_statusItem;

- (id)init {
    if ((self = [super init])) {
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [self.statusItem setTitle:@"LR"];
        [self.statusItem setTarget:self];
        [self.statusItem setAction:@selector(statusIconClicked)];
        [self.statusItem setHighlightMode:YES];
    }
    return self;
}

- (IBAction)statusIconClicked {
    NSLog(@"Clicked!");
}

@end
