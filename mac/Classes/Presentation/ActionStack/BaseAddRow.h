
#import "ATStackView.h"

@interface BaseAddRow : ATStackViewRow

@property(nonatomic, strong) NSPopUpButton *menuPullDown;

- (IBAction)addActionClicked:(NSMenuItem *)sender;

@end
