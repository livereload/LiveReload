
#import <Cocoa/Cocoa.h>

// just to make descendants' life easier
#import "Project.h"
#import "ShitHappens.h"


@interface BaseProjectSettingsWindowController : NSWindowController {
@protected
    Project               *_project;
}

- (id)initWithProject:(Project *)project;

- (IBAction)dismiss:(id)sender;
- (IBAction)showHelp:(id)sender;

// override points
- (void)render;
- (void)save;

@end
