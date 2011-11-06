
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"


typedef enum {
    ControlTypeNone,
    ControlTypeCheckBox,
    ControlTypePopUp,
    ControlTypeEdit,
} ControlType;
enum { ControlTypeCount = 4 };


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController {
    CGFloat                _nextY;
    CGFloat                _lastControlY;
    ControlType            _lastControlType;
    BOOL                   _labelAdded;
    NSMutableArray        *_controls;
}

@end
