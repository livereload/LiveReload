
#import "FSChange.h"

@implementation FSChange

- (id)initWithChangedFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged {
    self = [super init];
    if (self) {
        _changedFiles = [changedFiles copy];
        _folderListChanged = folderListChanged;
    }
    return self;
}

+ (id)changeWithFiles:(NSSet *)changedFiles folderListChanged:(BOOL)folderListChanged {
    return [[[self class] alloc] initWithChangedFiles:changedFiles folderListChanged:folderListChanged];
}

- (BOOL)isNonEmpty {
    return _changedFiles.count > 0 || _folderListChanged;
}

@end
