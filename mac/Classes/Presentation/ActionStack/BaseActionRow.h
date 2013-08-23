
#import "ATStackView.h"
#import "LROptionsView.h"
#import "Action.h"


@class Project;
@class OptionsRow;


@interface BaseActionRow : ATStackViewRow

@property (nonatomic, strong) IBOutlet NSButton *checkbox;
@property (nonatomic, strong) IBOutlet NSButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;

@property (nonatomic, strong, readonly) OptionsRow *optionsRow;

@property (nonatomic, strong, readonly) Action *action;
@property (nonatomic, strong) Project *project;

- (void)loadOptionsIntoView:(LROptionsView *)container;  // override point

// override points
- (void)stopObservingProject;
- (void)startObservingProject;

- (void)updateFilterOptionsPopUp:(NSPopUpButton *)popUp selectedOption:(FilterOption *)selectedOption;

@end



@protocol BaseActionRowDelegate <NSObject>

- (void)removeActionClicked:(id)action;

@end