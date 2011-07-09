
#import "ProjectOptionsSheetController.h"
#import "PaneViewController.h"
#import "CompilerPaneViewController.h"

#import "PluginManager.h"
#import "Compiler.h"
#import "Project.h"


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
        _project = [project retain];
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

- (NSString *)description {
    return [NSString stringWithFormat:@"ProjectOptionsSheetController(%@)", [_project displayPath]];
}


#pragma mark - Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [_servicesArrayController addObserver:self forKeyPath:@"selection" options:0 context:kSelectionObservation];
    [self updateSelectedPane];
}


#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
    self.selectedPaneViewController = nil;
    [NSApp endSheet:[self window]];
}


#pragma mark - Pane selection

- (void)updateSelectedPane {
    NSArray *selection = [_servicesArrayController selectedObjects];
    self.selectedPaneViewController = ([selection count] > 0 ? [selection objectAtIndex:0] : nil);
}

- (void)setSelectedPaneViewController:(PaneViewController *)newViewController {
    if (_selectedPaneViewController != newViewController) {
        PaneViewController *oldViewController = _selectedPaneViewController;
        _selectedPaneViewController = [newViewController retain];

        [oldViewController paneWillHide];
        [newViewController paneWillShow];

        [oldViewController.view removeFromSuperview];

        NSView *newView = newViewController.view;
        if (newView) {
            [newView setFrame:[_placeholderBox frame]];
            [[[self window] contentView] addSubview:newView positioned:NSWindowAbove relativeTo:_placeholderBox];
            [_placeholderBox setHidden:YES];
        } else {
            [_placeholderBox setHidden:NO];
        }

        [oldViewController paneDidHide];
        [newViewController paneDidShow];

        [oldViewController release];
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kSelectionObservation) {
        [self updateSelectedPane];
    }
}

@end
