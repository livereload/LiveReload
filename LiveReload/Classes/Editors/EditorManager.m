
#import "EditorManager.h"

#import "CustomEditor.h"
#import "CodaEditor.h"
#import "EspressoEditor.h"
#import "SubEthaEditEditor.h"
#import "TextMateEditor.h"


@interface EditorManager ()
@end


@implementation EditorManager

static EditorManager *sharedEditorManager = nil;

+ (EditorManager *)sharedEditorManager {
    if (sharedEditorManager == nil) {
        sharedEditorManager = [[EditorManager alloc] init];
    }
    return sharedEditorManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _editorClasses = [[NSMutableArray alloc] init];
        [_editorClasses addObject:[CustomEditor class]];
        [_editorClasses addObject:[CodaEditor class]];
        [_editorClasses addObject:[EspressoEditor class]];
        [_editorClasses addObject:[SubEthaEditEditor class]];
        [_editorClasses addObject:[TextMateEditor class]];
    }
    return self;
}

- (Editor *)activeEditor {
    for (Class editorClass in _editorClasses) {
        Editor *editor = [editorClass detectEditor];
        if (editor)
            return editor;
    }
    return nil;
}

@end
