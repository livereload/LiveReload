
#import <Cocoa/Cocoa.h>
#import "ATStackView.h"

@class Project;
@class Rulebook;

@interface RulebookView : ATStackView

@property(nonatomic, strong) Project *project;
@property(nonatomic, strong) Rulebook *rulebook;

@end
