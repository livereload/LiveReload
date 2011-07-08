
#import "ProjectOptionsSheetController.h"
#import "PaneViewController.h"
#import "CompilerPaneViewController.h"

#import "PluginManager.h"
#import "Compiler.h"


static NSString *kSelectionObservation = @"kSelectionObservation";


@interface ProjectOptionsSheetController ()

- (void)updateSelectedPane;

@property(nonatomic, retain) PaneViewController *selectedPaneViewController;

@end



@implementation ProjectOptionsSheetController

@synthesize servicesArrayController = _servicesArrayController;
@synthesize selectedPaneViewController=_selectedPaneViewController;
@synthesize placeholderBox = _placeholderBox;


#pragma mark init/dealloc

- (id)initWithProject:(Project *)project {
    self = [super initWithWindowNibName:@"ProjectOptionsSheet"];
    if (self) {
        NSMutableArray *panes = [NSMutableArray array];
//        [panes addObject:[[[Pane alloc] initWithProject:project name:@"Live JavaScript"] autorelease]];
//        [panes addObject:[[[Pane alloc] initWithProject:project name:@"Exclusions"] autorelease]];
        for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
            [panes addObject:[[[CompilerPaneViewController alloc] initWithProject:project compiler:compiler] autorelease]];
        }
        _panes = [panes copy];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


#pragma mark - Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [_servicesArrayController addObserver:self forKeyPath:@"selection" options:0 context:kSelectionObservation];
}


#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
    NSLog(@"dismiss");
    [NSApp endSheet:[self window]];
}


#pragma mark - Pane selection

- (void)updateSelectedPane {
    NSLog(@"updateSelectedPane");
    NSArray *selection = [_servicesArrayController selectedObjects];
    self.selectedPaneViewController = ([selection count] > 0 ? [selection objectAtIndex:0] : nil);
}

- (void)setSelectedPaneViewController:(PaneViewController *)viewController {
    if (_selectedPaneViewController != viewController) {
        [_selectedPaneViewController.objectController commitEditing];
        NSView *oldView = _selectedPaneViewController.view;
        [oldView removeFromSuperview];
        [_selectedPaneViewController release];

        _selectedPaneViewController = [viewController retain];
        NSView *newView = _selectedPaneViewController.view;
        if (newView) {
            NSLog(@"Switching to view for compiler %@", [[(id)_selectedPaneViewController compiler] name]);
            [newView setFrame:[_placeholderBox frame]];
            [[[self window] contentView] addSubview:newView positioned:NSWindowAbove relativeTo:_placeholderBox];
            [_placeholderBox setHidden:YES];
        } else {
            NSLog(@"Switching to nil view");
            [_placeholderBox setHidden:NO];
        }
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath:", keyPath);
    if (context == kSelectionObservation) {
        [self updateSelectedPane];
    }
}

@end
