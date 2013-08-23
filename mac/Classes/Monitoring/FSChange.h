
#import <Foundation/Foundation.h>


@interface FSChange : NSObject

@property(nonatomic, strong) NSSet *changedFiles;
@property(nonatomic, assign, getter=isFolderListChanged) BOOL folderListChanged;
@property(nonatomic, assign, getter=isNonEmpty) BOOL isNonEmpty;

- (id)initWithChangedFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged;
+ (id)changeWithFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged;

@end
