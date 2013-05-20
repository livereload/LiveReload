
#import "RuntimeContainer.h"

@interface HomebrewContainer : RuntimeContainer

+ (NSString *)containerTypeIdentifier;

@property(nonatomic, readonly) NSURL *rootUrl;
@property(nonatomic, readonly) NSString *rootPath;
@property(nonatomic, readonly) NSString *rubiesPath;
@property(nonatomic, readonly) NSString *binPath;

@end
