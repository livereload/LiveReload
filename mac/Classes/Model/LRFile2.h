
#import <Foundation/Foundation.h>


@class Project;


@interface LRFile2 : NSObject

+ (LRFile2 *)fileWithRelativePath:(NSString *)relativePath project:(Project *)project;

@property(nonatomic, copy) NSString *relativePath;
@property(nonatomic, strong) Project *project;

@property(nonatomic, readonly) NSString *absolutePath;
@property(nonatomic, readonly) NSURL *absoluteURL;

@end
