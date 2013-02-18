
#import <Foundation/Foundation.h>


@class Editor;


@interface EditorManager : NSObject {
    NSMutableArray        *_editorClasses;
}

+ (EditorManager *)sharedEditorManager;

- (Editor *)activeEditor;

@end
