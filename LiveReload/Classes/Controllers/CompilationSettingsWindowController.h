
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


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController {
    CGFloat                _nextY;
    CGFloat                _lastControlY;
    ControlType            _lastControlType;
    BOOL                   _labelAdded;
    NSMutableArray        *_controls;
}

@end
