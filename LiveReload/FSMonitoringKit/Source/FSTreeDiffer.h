#import <Foundation/Foundation.h>


@class FSTree;
@class FSTreeFilter;
@class FSChange;


@interface FSTreeDiffer : NSObject {
    NSString *_path;
    NSSet *_savedFileList;
    FSTreeFilter *_filter;
    FSTree *_previousTree;
}

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter;

- (FSChange *)changedPathsByRescanningSubfolders:(NSSet *)subfolderPathes;

@property(nonatomic, readonly, strong) FSTree *savedTree;

@end
