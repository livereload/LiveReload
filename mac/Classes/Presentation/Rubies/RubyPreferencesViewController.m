
#import "RubyPreferencesViewController.h"
#import "AddCustomRubySheet.h"
#import "RuntimeObject.h"
#import "RubyRuntimeRepository.h"
#import "RuntimeInstance.h"
#import "RuntimeContainer.h"


@interface RubyPreferencesViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (assign) IBOutlet NSOutlineView *outlineView;

@property(nonatomic, strong) NSWindowController *modalSheetController;

@property(nonatomic, strong) RuntimeRepository *repository;
@property(nonatomic, strong) NSArray *topLevelItems;

@end


@implementation RubyPreferencesViewController

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        self.repository = [RubyRuntimeRepository sharedRubyManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runtimeRepositoryDidChange:) name:LRRuntimesDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runtimeRepositoryDidChange:) name:LRRuntimeContainerDidChangeNotification object:nil];
    }
    return self;
}

- (void)setView:(NSView *)view {
    [super setView:view];

    [self updateTopLevelItems];
}

- (NSString *)identifier {
    return @"rubies";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
    return @"Rubies";
}

- (IBAction)displayAddRubySheet:(id)sender {
    self.modalSheetController = [[AddCustomRubySheet alloc] init];
    [NSApp beginSheet:self.modalSheetController.window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(addRubySheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addRubySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];

    // at least on OS X 10.6, the window position is only persisted on quit
    [[NSUserDefaults standardUserDefaults] performSelector:@selector(synchronize) withObject:nil afterDelay:2.0];

    self.modalSheetController = nil;
}



#pragma mark - List of Instances and Containers

- (void)updateTopLevelItems {
    NSMutableArray *items = [NSMutableArray array];
    [items addObjectsFromArray:self.repository.instances];
    [items addObjectsFromArray:self.repository.containers];
    self.topLevelItems = [NSArray arrayWithArray:items];
    [self.outlineView reloadData];
}

- (void)runtimeRepositoryDidChange:(NSNotification *)notification {
    [self updateTopLevelItems];
}



#pragma mark - NSTableView

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return self.topLevelItems.count;
    if ([item isKindOfClass:[RuntimeContainer class]])
        return [[item instances] count];
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil)
        return self.topLevelItems[index];
    if ([item isKindOfClass:[RuntimeContainer class]])
        return [[item instances] objectAtIndex:index];
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil)
        return YES;
    if ([item isKindOfClass:[RuntimeContainer class]])
        return YES;
    return NO;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {

    if ([item isKindOfClass:[RuntimeInstance class]]) {
        RuntimeInstance *instance = item;

        NSTableCellView *view = [outlineView makeViewWithIdentifier:@"Main" owner:self];
        view.textField.stringValue = instance.title;
        return view;
    }
    
    if ([item isKindOfClass:[RuntimeContainer class]]) {
        RuntimeContainer *container = item;

        NSTableCellView *view = [outlineView makeViewWithIdentifier:@"Main" owner:self];
        view.textField.stringValue = container.title;
        return view;
    }

    return nil;
}


@end
