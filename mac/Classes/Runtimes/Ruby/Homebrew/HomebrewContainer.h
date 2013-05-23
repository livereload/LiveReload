
#import "RuntimeContainer.h"


NSString *GetDefaultHomebrewPath();


@interface HomebrewContainer : RuntimeContainer

+ (NSString *)containerTypeIdentifier;

@property(nonatomic, readonly) NSURL *rootUrl;
@property(nonatomic, readonly) NSString *rootPath;

@property(nonatomic, readonly) NSURL *cellarUrl;
@property(nonatomic, readonly) NSURL *rubiesUrl;

@end
