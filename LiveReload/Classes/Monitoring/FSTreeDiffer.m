
#import "FSTreeDiffer.h"
#import "FSTree.h"
#import "FSTreeFilter.h"


@interface FSTreeDiffer ()

@end


@implementation FSTreeDiffer

- (id)initWithPath:(NSString *)path filter:(FSTreeFilter *)filter {
    if ((self = [super init])) {
        _path = [path copy];
        _filter = [filter retain];
        _previousTree = [[FSTree alloc] initWithPath:_path filter:_filter];
    }
    return self;
}

- (void)dealloc {
    [_path release], _path = nil;
    [_filter release], _filter = nil;
    [_previousTree release], _previousTree = nil;
    [super dealloc];
}

- (NSSet *)allFiles {
    NSTimeInterval start = [[NSDate date] timeIntervalSinceReferenceDate];
    NSSet *result = [NSSet setWithArray:[[NSFileManager defaultManager] subpathsOfDirectoryAtPath:_path error:nil]];
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceReferenceDate] - start;
    NSLog(@"Scanning of %@ took %0.3lf sec.", _path, elapsed);
    return result;
}

- (NSSet *)changedPathsByRescanningSubfolders:(NSSet *)subfolderPathes {
    FSTree *currentTree = [[FSTree alloc] initWithPath:_path filter:_filter];

    NSSet *changedPaths = [currentTree differenceFrom:_previousTree];

    [_previousTree release];
    _previousTree = currentTree;

    return changedPaths;
}

- (FSTree *)savedTree {
    return _previousTree;
}

@end
