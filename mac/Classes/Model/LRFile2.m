
#import "LRFile2.h"
#import "Project.h"

@implementation LRFile2

- (id)initWithRelativePath:(NSString *)relativePath project:(Project *)project {
    self = [super init];
    if (self) {
        _relativePath = [relativePath copy];
        _project = project;
    }
    return self;
}

+ (LRFile2 *)fileWithRelativePath:(NSString *)relativePath project:(Project *)project {
    return [[[self class] alloc] initWithRelativePath:relativePath project:project];
}

- (NSString *)absolutePath {
    return [_project.path stringByAppendingPathComponent:_relativePath];
}

- (NSURL *)absoluteURL {
    return [NSURL fileURLWithPath:self.absolutePath];
}

@end
