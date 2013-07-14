
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


@interface EditorManager ()

@property(nonatomic, readonly, strong) NSMutableArray *editors;

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
        [self detectEditors];
    }
    return self;
}

- (Editor *)activeEditor {
//    for (Class editorClass in _editorClasses) {
//        Editor *editor = [editorClass detectEditor];
//        if (editor)
//            return editor;
//    }
    return nil;
}

- (void)detectEditors {
    [_editors removeAllObjects];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *plugins = LRFindPluginsInFolder([ATUserScriptsDirectoryURL() URLByAppendingPathComponent:@"Editors"], @[@"editor v1"]);
        dispatch_async(dispatch_get_main_queue(), ^{
            for (SingleFilePlugin *script in plugins) {
                Editor *editor = [[ExternalEditor alloc] initWithScript:script];
                [_editors addObject:editor];
                [editor updateStateSoon];
            }
        });
    });
}

@end
