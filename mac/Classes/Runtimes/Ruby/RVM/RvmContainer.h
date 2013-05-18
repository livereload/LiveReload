
#import "RuntimeContainer.h"


NSString *GetDefaultRvmPath();


@interface RvmContainer : RuntimeContainer

@property(nonatomic, copy) NSURL *rootUrl;
@property(nonatomic, strong) NSString *version;

@property(nonatomic, readonly) NSString *rootPath;
@property(nonatomic, readonly) NSString *rubiesPath;
@property(nonatomic, readonly) NSString *binPath;

@end
