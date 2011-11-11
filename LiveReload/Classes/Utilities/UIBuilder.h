
#import <Foundation/Foundation.h>


@interface UIBuilder : NSObject


- (id)initWithWindow:(NSWindow *)window;

- (void)buildUIWithTopInset:(CGFloat)topInset bottomInset:(CGFloat)bottomInset block:(void(^)())block;


@property(nonatomic, readonly) BOOL labelAdded;

- (NSTextField *)addLabel:(NSString *)label;
- (NSTextField *)addFullWidthLabel:(NSString *)label;
- (NSTextField *)addRightLabel:(NSString *)label;


- (NSPopUpButton *)addPopUpButton;
- (NSButton *)addCheckboxWithTitle:(NSString *)title;
- (NSTextField *)addTextField;


- (void)addVisualBreak;


@end
