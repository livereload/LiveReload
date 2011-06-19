
#import <Foundation/Foundation.h>


@class FSTree;
@class FSTreeFilter;


@interface FSTreeDiffer : NSObject {
    NSString *_path;
    NSSet *_savedFileList;
    FSTreeFilter *_filter;
    FSTree *_previousTree;
}

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter;

- (NSSet *)changedPathsByRescanningSubfolder:(NSString *)subfolderPath;

@property(nonatomic, readonly, retain) FSTree *savedTree;

@end
