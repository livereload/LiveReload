
#import <Cocoa/Cocoa.h>
#import "PXListViewCell.h"

@interface ProjectCell : PXListViewCell {
    NSTextField *titleLabel;
}

@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;

@end
