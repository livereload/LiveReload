
#import "NpmPackageContainer.h"
#import "NpmPackage.h"
#import "LRPackageType.h"
#import "LRVersionSpace.h"


@interface NpmPackageContainer ()

@end


@implementation NpmPackageContainer

- (instancetype)initWithPackageType:(LRPackageType *)packageType folderURL:(NSURL *)folderURL {
    self = [super initWithPackageType:packageType];
    if (self) {
        _folderURL = [folderURL copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"NpmPackageContainer(%@)", _folderURL.path];
}

- (void)doUpdate {
    LRVersionSpace *versionSpace = self.packageType.versionSpace;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        NSArray *subfolderURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_folderURL includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (!subfolderURLs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFailedWithError:error];
            });
            return;
        }

        NSMutableArray *packages = [NSMutableArray new];

        for (NSURL *packageFolderURL in subfolderURLs) {
            NSDictionary *values = [packageFolderURL resourceValuesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] error:&error];
            if (![values[NSURLIsDirectoryKey] boolValue])
                continue;

            NSURL *packageJsonURL = [packageFolderURL URLByAppendingPathComponent:@"package.json"];
            NSData *packageJsonData = [NSData dataWithContentsOfURL:packageJsonURL options:0 error:&error];
            if (!packageJsonData)
                continue;

            NSDictionary *packageInfo = [NSJSONSerialization JSONObjectWithData:packageJsonData options:0 error:&error];
            if (!packageInfo)
                continue;
            if (![packageInfo isKindOfClass:NSDictionary.class])
                continue;

            NSString *nameString = packageInfo[@"name"];
            if (!nameString || ![nameString isKindOfClass:NSString.class])
                continue;

            NSString *versionString = packageInfo[@"version"];
            if (!versionString || ![versionString isKindOfClass:NSString.class])
                continue;

            LRVersion *version = [versionSpace versionWithString:versionString];

            NpmPackage *package = [[NpmPackage alloc] initWithName:nameString version:version container:self sourceFolderURL:packageFolderURL];
            [packages addObject:package];
        }

        [self updateSucceededWithPackages:packages];
    });
}

@end
