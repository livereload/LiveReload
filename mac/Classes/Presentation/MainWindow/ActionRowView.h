
#import <Cocoa/Cocoa.h>

@class Project;
@class Action;
@protocol ActionRowViewDelegate;


@interface ActionRowView : NSView

@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) IBOutlet Action *representedObject;
@property (nonatomic, weak) IBOutlet id<ActionRowViewDelegate> delegate;

@end


@protocol ActionRowViewDelegate <NSObject>

- (void)didInvokeAddInActionRowView:(ActionRowView *)rowView;
- (void)didInvokeRemoveInActionRowView:(ActionRowView *)rowView;

@end
