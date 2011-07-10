
#import <Foundation/Foundation.h>


@class FSTreeFilter;


@interface FSTree : NSObject {
    NSString *_rootPath;
    FSTreeFilter *_filter;
    struct FSTreeItem *_items;
    NSInteger _count;
}

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter;

@property (nonatomic, readonly, copy) NSString *rootPath;

- (NSSet *)differenceFrom:(FSTree *)previous;

- (BOOL)containsFileNamed:(NSString *)fileName;
- (NSString *)pathOfFileNamed:(NSString *)fileName;
- (NSArray *)pathsOfFilesMatching:(BOOL (^)(NSString *name))filter;

@end
