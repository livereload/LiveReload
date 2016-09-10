#import <Foundation/Foundation.h>


@interface FSChange : NSObject

@property(nonatomic, strong) NSSet *changedFiles;
@property(nonatomic, readonly, getter=isFolderListChanged) BOOL folderListChanged;
@property(nonatomic, readonly, getter=isNonEmpty) BOOL isNonEmpty;

- (id)initWithChangedFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged;
+ (id)changeWithFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged;

@end
