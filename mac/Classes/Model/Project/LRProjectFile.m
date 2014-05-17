
#import "LRProjectFile.h"
#import "Project.h"

@implementation LRProjectFile

- (id)initWithRelativePath:(NSString *)relativePath project:(Project *)project {
    self = [super init];
    if (self) {
        _relativePath = [relativePath copy];
        _project = project;
    }
    return self;
}

+ (LRProjectFile *)fileWithRelativePath:(NSString *)relativePath project:(Project *)project {
    return [[[self class] alloc] initWithRelativePath:relativePath project:project];
}

- (NSString *)absolutePath {
    return [_project.path stringByAppendingPathComponent:_relativePath];
}

- (NSURL *)absoluteURL {
    return [NSURL fileURLWithPath:self.absolutePath];
}

- (BOOL)exists {
    return [self.absoluteURL checkResourceIsReachableAndReturnError:NULL];
}

@end
