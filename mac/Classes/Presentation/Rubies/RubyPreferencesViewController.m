
#import "RubyPreferencesViewController.h"
#import "AddCustomRubySheet.h"


@interface RubyPreferencesViewController ()

@property(nonatomic, strong) NSWindowController *modalSheetController;

@end


@implementation RubyPreferencesViewController

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
    }
    return self;
}

- (NSString *)identifier {
    return @"rubies";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
    return @"Rubies";
}

- (IBAction)displayAddRubySheet:(id)sender {
    self.modalSheetController = [[AddCustomRubySheet alloc] init];
    [NSApp beginSheet:self.modalSheetController.window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(addRubySheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addRubySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];

    // at least on OS X 10.6, the window position is only persisted on quit
    [[NSUserDefaults standardUserDefaults] performSelector:@selector(synchronize) withObject:nil afterDelay:2.0];

    self.modalSheetController = nil;
}

@end
