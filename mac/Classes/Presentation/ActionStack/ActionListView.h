
#import <Cocoa/Cocoa.h>
#import "ATStackView.h"

@class Project;
@class ActionList;

@interface ActionListView : ATStackView

@property(nonatomic, strong) Project *project;
@property(nonatomic, strong) ActionList *actionList;

@end
