
#import "EditorManager.h"
#import "ATGlobals.h"
#import "ATFunctionalStyle.h"
#import "RegexKitLite.h"
#import "EditorKit.h"
#import "ExternalEditor.h"
#import "LRPluginCommons.h"
#import "ATModelDiff.h"


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

- (EKEditor *)activeEditor {
    EKEditor *topEditor = _sortedEditors[0];
    if (topEditor.isRunning)
        return topEditor;
    else
        return nil;
}

- (NSArray *)loadBundledEditors {
    NSURL *editorsFileURL = [[NSBundle mainBundle] URLForResource:@"editors.json" withExtension:nil];
    if (!editorsFileURL)
        abort();
    NSError *error = nil;
    NSDictionary *editorsData = [NSDictionary LR_dictionaryWithContentsOfJSONFileURL:editorsFileURL error:nil];
    NSAssert1(editorsData, @"Failed to parse editors.json: %@", error.localizedDescription);
    return editorsData[@"editors"];
}

- (NSArray *)loadExternalEditors {
    return [LRFindPluginsInFolder([ATUserScriptsDirectoryURL() URLByAppendingPathComponent:@"Editors"], @[@"editor-v1"]) arrayByMappingElementsUsingBlock:^id(SingleFilePlugin *script) {
        return [script.properties[@"editor"] dictionaryByAddingEntriesFromDictionary:@{@"script": script}];
    }];
}

- (void)updateEditors {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDictionary *editorClasses = @{
            @"com.sublimetext.2": [SublimeText2Editor class],
            @"com.sublimetext.3": [SublimeText3Editor class],
            @"com.panic.Coda2": [Coda2Editor class],
        };

        NSArray *plugins1 = [self loadBundledEditors];
        NSArray *plugins2 = [self loadExternalEditors];
        NSArray *plugins3 = [[editorClasses allKeys] arrayByMappingElementsUsingBlock:^id(NSString *identifier) {
            return @{@"id": identifier};
        }];
        NSArray *plugins12 = [plugins1 arrayByMergingDictionaryValuesWithArray:plugins2 groupedByKeyPath:@"id"];
        NSArray *plugins = [plugins12 arrayByMergingDictionaryValuesWithArray:plugins3 groupedByKeyPath:@"id"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [ModelDiffs updateMutableObjectsArray:_editors usingAttributesPropertyWithNewAttributeValueDictionaries:plugins identityKeyPath:@"identifier" identityAttributeKey:@"id" create:^(NSDictionary *attributes) {
                Class klass = editorClasses[attributes[@"id"]] ?: [ExternalEditor class];
                EKEditor *editor = [[klass alloc] init];
                [editor addObserver:self forKeyPath:@"state" options:0 context:NULL];
                return editor;
            } delete:^(ExternalEditor *editor) {
                [editor removeObserver:self forKeyPath:@"state"];
            }];
            for (EKEditor *editor in _editors) {
                [editor updateStateSoon];
            }
            [self updateMruPositions];
            [self resortEditors];
        });
    });
}

- (void)updateMruPositions {
    for (EKEditor *editor in _editors) {
        editor.mruPosition = [_mostRecentlyUsedEditorIdentifiers indexOfObject:editor.identifier];
    }
}

- (void)resortEditors {
    NSLog(@"resortEditors");
    for (EKEditor *editor in _editors) {
        NSLog(@"editor %@: effectivePriority=%d, defaultPriority=%d, mruPosition=%d", editor.displayName, (int)editor.effectivePriority, (int)editor.defaultPriority, (int)editor.mruPosition);
    }
    _sortedEditors = [[_editors sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"effectivePriority" ascending:NO]]] copy];
}

- (void)moveEditorToFrontOfMostRecentlyUsedList:(EKEditor *)editor {
    NSString *identifier = editor.identifier;
    if (_mostRecentlyUsedEditorIdentifiers.count > 0 && [_mostRecentlyUsedEditorIdentifiers[0] isEqual:identifier])
        return;
    [_mostRecentlyUsedEditorIdentifiers removeObject:identifier];
    [_mostRecentlyUsedEditorIdentifiers insertObject:identifier atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:_mostRecentlyUsedEditorIdentifiers forKey:@"EditorMRU"];

    [self updateMruPositions];
    [self resortEditors];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self resortEditors];
}

@end
