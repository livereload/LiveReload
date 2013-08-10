
#import <Cocoa/Cocoa.h>
#import "ATStackView.h"


@class Project;
@class Action;
@protocol ActionRowViewDelegate;


@interface ActionRowView : ATStackViewRow

@property (nonatomic, strong) Project *project;
@property (nonatomic, weak) IBOutlet id<ActionRowViewDelegate> delegate;

@end


@protocol ActionRowViewDelegate <NSObject>

- (void)didInvokeAddInActionRowView:(ActionRowView *)rowView;
- (void)didInvokeRemoveInActionRowView:(ActionRowView *)rowView;

@end
