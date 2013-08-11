
#import <Cocoa/Cocoa.h>
#import "ATStackView.h"

@class ActionList;

@interface ActionListView : ATStackView

@property(nonatomic, strong) ActionList *actionList;

@end
