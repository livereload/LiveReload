
#import <Cocoa/Cocoa.h>


@class Project;


@interface PostProcessingSettingsWindowController : NSWindowController {
    Project               *_project;
}

- (id)initWithProject:(Project *)project;

- (IBAction)dismiss:(id)sender;
- (IBAction)showHelp:(id)sender;

@property (assign) IBOutlet NSTextField *commandField;

@end
