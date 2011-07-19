
#import <Cocoa/Cocoa.h>
#import "PXListView.h"


@class ProjectOptionsSheetController;
@class Project;


@interface MainWindowController : NSWindowController <PXListViewDelegate> {
    NSTextField *_connectionStateLabel;
    BOOL _inProjectEditorMode;
    NSTextField *_clickToAddFolderLabel;
    NSTextField *_folderListLabel;

    ProjectOptionsSheetController *projectEditorController;

    PXListView *_listView;
    NSButton *_addProjectButton;
    NSButton *_removeProjectButton;

    NSInteger _sheetRow;
}


@property(nonatomic, retain) IBOutlet PXListView *listView;

@property(nonatomic, retain) IBOutlet NSButton *addProjectButton;

@property(nonatomic, retain) IBOutlet NSButton *removeProjectButton;
@property (assign) IBOutlet NSTextField *clickToAddFolderLabel;
@property (assign) IBOutlet NSTextField *folderListLabel;

- (void)willShow;

- (IBAction)addProjectClicked:(id)sender;
- (IBAction)removeProjectClicked:(id)sender;

@property (assign) IBOutlet NSTextField *connectionStateLabel;

- (void)projectAdded:(Project *)project;

@end
