
#import "RuntimeContainer.h"

@interface HomebrewContainer : RuntimeContainer

+ (NSString *)containerTypeIdentifier;

@property(nonatomic, readonly) NSURL *rootUrl;
@property(nonatomic, readonly) NSString *rootPath;

@end
