
#import <Foundation/Foundation.h>


@class Project;


@interface LRProjectFile : NSObject

+ (LRProjectFile *)fileWithRelativePath:(NSString *)relativePath project:(Project *)project;

@property(nonatomic, copy) NSString *relativePath;
@property(nonatomic, strong) Project *project;

@property(nonatomic, readonly) NSString *absolutePath;
@property(nonatomic, readonly) NSURL *absoluteURL;

@property(nonatomic, readonly) BOOL exists;

@end
