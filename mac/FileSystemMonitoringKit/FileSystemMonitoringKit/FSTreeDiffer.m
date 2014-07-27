
#import "FSTreeDiffer.h"
#import "FSTree.h"
#import "FSTreeFilter.h"
#import "FSChange.h"


@interface FSTreeDiffer ()

@end


@implementation FSTreeDiffer

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter {
    if ((self = [super init])) {
        _path = [path copy];
        _filter = filter;
        _previousTree = [[FSTree alloc] initWithPath:_path filter:_filter];
    }
    return self;
}

- (NSSet *)allFiles {
    NSTimeInterval start = [[NSDate date] timeIntervalSinceReferenceDate];
    NSSet *result = [NSSet setWithArray:[[NSFileManager defaultManager] subpathsOfDirectoryAtPath:_path error:nil]];
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceReferenceDate] - start;
    NSLog(@"Scanning of %@ took %0.3lf sec.", _path, elapsed);
    return result;
}

- (FSChange *)changedPathsByRescanningSubfolders:(NSSet *)subfolderPathes {
    FSTree *currentTree = [[FSTree alloc] initWithPath:_path filter:_filter];

    NSSet *changedPaths = [currentTree differenceFrom:_previousTree];
    BOOL folderListChanged = ![currentTree.folderPaths isEqualToArray:_previousTree.folderPaths];

    _previousTree = currentTree;

    return [FSChange changeWithFiles:changedPaths folderListChanged:folderListChanged];
}

- (FSTree *)savedTree {
    return _previousTree;
}

@end
