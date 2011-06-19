
#import <Foundation/Foundation.h>


@class FSTreeFilter;


@interface FSTree : NSObject {
    FSTreeFilter *_filter;
    struct FSTreeItem *_items;
    NSInteger _count;
}

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter;

- (NSSet *)differenceFrom:(FSTree *)previous;

- (BOOL)containsFileNamed:(NSString *)fileName;

@end
