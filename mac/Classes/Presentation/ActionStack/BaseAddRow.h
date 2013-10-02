
#import "ATStackView.h"

@interface BaseAddRow : ATStackViewRow

@property(nonatomic, strong) NSPopUpButton *menuPullDown;
@property(nonatomic, readonly) NSMenu *menu;

// override point
- (void)updateMenu;

- (IBAction)addActionClicked:(NSMenuItem *)sender;

@end
