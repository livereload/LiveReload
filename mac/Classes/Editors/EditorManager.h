
#import <Foundation/Foundation.h>


@class EKEditor;


@interface EditorManager : NSObject

+ (EditorManager *)sharedEditorManager;

@property(nonatomic, readonly, strong) EKEditor *activeEditor;
@property(nonatomic, readonly, strong) NSArray *sortedEditors;

- (void)updateEditors;
- (void)moveEditorToFrontOfMostRecentlyUsedList:(EKEditor *)editor;

@end
