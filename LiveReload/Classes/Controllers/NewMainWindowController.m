
#import "NewMainWindowController.h"

#import "Workspace.h"

@implementation NewMainWindowController

- (id)init {
    self = [super initWithWindowNibName:@"NewMainWindow"];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (NSArray *)projects {
    return [Workspace sharedWorkspace].sortedProjects;
}

@end
