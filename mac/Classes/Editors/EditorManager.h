
#import <Foundation/Foundation.h>


@class Editor;


@interface EditorManager : NSObject

+ (EditorManager *)sharedEditorManager;

@property(nonatomic, readonly, strong) Editor *activeEditor;
@property(nonatomic, readonly, strong) NSArray *sortedEditors;

- (void)updateEditors;
- (void)moveEditorToFrontOfMostRecentlyUsedList:(Editor *)editor;

@end
