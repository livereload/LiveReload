
#import "EditorManager.h"
#import "ATSandboxing.h"
#import "RegexKitLite.h"

#import "CustomEditor.h"
#import "CodaEditor.h"
#import "EspressoEditor.h"
#import "SublimeText2Editor.h"
#import "SubEthaEditEditor.h"
#import "TextMateEditor.h"
#import "BBEditEditor.h"
#import "ExternalEditor.h"
#import "LRPluginCommons.h"
#import "ArrayDiff.h"


@interface EditorManager ()

@property(nonatomic, readonly, strong) NSMutableArray *editors;
@property(nonatomic, readonly, strong) NSMutableArray *mostRecentlyUsedEditorIdentifiers;

@end


@implementation EditorManager

@synthesize editors = _editors;

+ (EditorManager *)sharedEditorManager {
    static dispatch_once_t onceQueue;
    static EditorManager *editorManager = nil;

    dispatch_once(&onceQueue, ^{ editorManager = [[self alloc] init]; });
    return editorManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _editors = [[NSMutableArray alloc] init];
        _mostRecentlyUsedEditorIdentifiers = [[NSMutableArray alloc] init];

        NSArray *mru = [[NSUserDefaults standardUserDefaults] arrayForKey:@"EditorMRU"];
        if (mru) {
            [_mostRecentlyUsedEditorIdentifiers addObjectsFromArray:mru];
        }

        [self updateEditors];
    }
    return self;
}

- (Editor *)activeEditor {
    Editor *topEditor = _sortedEditors[0];
    if (topEditor.isRunning)
        return topEditor;
    else
        return nil;
}

- (void)updateEditors {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *plugins = LRFindPluginsInFolder([ATUserScriptsDirectoryURL() URLByAppendingPathComponent:@"Editors"], @[@"editor v1"]);
        dispatch_async(dispatch_get_main_queue(), ^{
            ArrayDiffWithKeyCallbacks(_editors, plugins, ^id(id object) {
                return ((ExternalEditor *)object).script.scriptFileURL;
            }, ^id(id object) {
                SingleFilePlugin *script = (SingleFilePlugin *)object;
                return script.scriptFileURL;
            }, ^(id newObject) {
                SingleFilePlugin *script = (SingleFilePlugin *)newObject;
                Editor *editor = [[ExternalEditor alloc] initWithScript:script];
                [_editors addObject:editor];
            }, ^(id oldObject) {
                [_editors removeObject:oldObject];
            }, ^(id oldObject, id newObject) {
                ExternalEditor *editor = (ExternalEditor *)oldObject;
                [editor updateScript:(SingleFilePlugin *)newObject];
            });
            for (Editor *editor in _editors) {
                [editor updateStateSoon];
            }
            [self updateMruPositions];
            [self resortEditors];
        });
    });
}

- (void)updateMruPositions {
    for (Editor *editor in _editors) {
        editor.mruPosition = [_mostRecentlyUsedEditorIdentifiers indexOfObject:editor.identifier];
    }
}

- (void)resortEditors {
    _sortedEditors = [[_editors sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"effectivePriority" ascending:NO]]] copy];
}

- (void)moveEditorToFrontOfMostRecentlyUsedList:(Editor *)editor {
    NSString *identifier = editor.identifier;
    if (_mostRecentlyUsedEditorIdentifiers.count > 0 && [_mostRecentlyUsedEditorIdentifiers[0] isEqual:identifier])
        return;
    [_mostRecentlyUsedEditorIdentifiers removeObject:identifier];
    [_mostRecentlyUsedEditorIdentifiers insertObject:identifier atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:_mostRecentlyUsedEditorIdentifiers forKey:@"EditorMRU"];

    [self resortEditors];
}

@end
