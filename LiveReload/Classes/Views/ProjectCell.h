
#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"


@protocol ProjectCellDelegate;


@interface ProjectCell : PXListViewCell {
    id<ProjectCellDelegate> delegate;
    NSTextField *titleLabel;
    NSButton *compileCoffeeScriptCheckbox;
}

@property (nonatomic, assign) __weak id<ProjectCellDelegate> delegate;

@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;

@property (assign) IBOutlet NSButton *compileCoffeeScriptCheckbox;

- (IBAction)compileCoffeeScriptChanged:(id)sender;

@end


@protocol ProjectCellDelegate <NSObject>
@required

- (void)checkboxClickedForLanguage:(NSString *)language inCell:(ProjectCell *)cell;

@end