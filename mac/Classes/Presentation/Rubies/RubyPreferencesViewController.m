
#import "RubyPreferencesViewController.h"

@interface RubyPreferencesViewController ()


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
}

- (IBAction)displayAddRvmSheet:(id)sender {
}

@end
