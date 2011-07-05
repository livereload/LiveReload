
#import "CoffeeOptionsSheetController.h"


@implementation CoffeeOptionsSheetController

- (id)init {
    self = [super initWithWindowNibName:@"CoffeeOptionsSheet"];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)dismiss:(id)sender {
    [NSApp endSheet:[self window]];
}

@end
