
#import <Foundation/Foundation.h>


@class FSTree;
@class FSTreeFilter;


@interface FSTreeDiffer : NSObject {
    NSString *_path;
    NSSet *_savedFileList;
    FSTreeFilter *_filter;
    FSTree *_previousTree;
}

- (id)initWithPath:(NSString *)path;

- (NSSet *)changedPathsByRescanningSubfolder:(NSString *)subfolderPath;

@end
