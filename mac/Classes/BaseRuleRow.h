
#import "ATStackView.h"
#import "LROptionsView.h"
#import "LiveReload-Swift-x.h"


@class Project;
@class OptionsRow;


@interface BaseRuleRow : ATStackViewRow

@property (nonatomic, strong) IBOutlet NSButton *checkbox;
@property (nonatomic, strong) IBOutlet NSButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;

@property (nonatomic, strong, readonly) OptionsRow *optionsRow;

@property (nonatomic, strong, readonly) Rule *rule;
@property (nonatomic, strong) Project *project;

- (void)loadOptionsIntoView:(LROptionsView *)container;  // override point

// override points
- (void)stopObservingProject;
- (void)startObservingProject;

- (void)updateFilterOptions; // override point

- (void)updateFilterOptionsPopUp:(NSPopUpButton *)popUp selectedOption:(FilterOption *)selectedOption;

@end



@protocol BaseActionRowDelegate <NSObject>

- (void)removeActionClicked:(id)rule;

@end