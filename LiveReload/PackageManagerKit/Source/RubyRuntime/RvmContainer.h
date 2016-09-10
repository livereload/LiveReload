
#import "RuntimeContainer.h"


NSString *GetDefaultRvmPath();


@interface RvmContainer : RuntimeContainer

+ (NSString *)containerTypeIdentifier;

@property(nonatomic, readonly) NSURL *rootUrl;
@property(nonatomic, readonly) NSString *rootPath;
@property(nonatomic, readonly) NSString *rubiesPath;
@property(nonatomic, readonly) NSURL *environmentsURL;
@property(nonatomic, readonly) NSString *binPath;

@end
