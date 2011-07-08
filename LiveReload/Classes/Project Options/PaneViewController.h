
#import <Cocoa/Cocoa.h>


@class Project;


@interface PaneViewController : NSViewController {
@protected
    Project             *_project;
    NSObjectController  *_objectController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil project:(Project *)project;

@property(nonatomic, readonly) NSString *title;
@property(nonatomic, getter=isActive) BOOL active;

@property (assign) IBOutlet NSObjectController *objectController;

@end
