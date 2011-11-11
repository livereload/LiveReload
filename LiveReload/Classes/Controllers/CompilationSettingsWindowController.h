
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"


typedef enum {
    ControlTypeNone,
    ControlTypeCheckBox,
    ControlTypePopUp,
    ControlTypeEdit,
    ControlTypeFullWidthLabel,
    ControlTypeRightLabel,
} ControlType;
enum { ControlTypeCount = 6 };


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController

@property (assign) IBOutlet NSPopUpButton *nodeVersionsPopUpButton;

@property (assign) IBOutlet NSPopUpButton *rubyVersionsPopUpButton;

@end
