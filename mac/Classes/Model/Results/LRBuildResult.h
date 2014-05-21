
#import <Foundation/Foundation.h>


@class Project;
@class LRProjectFile;


@interface LRBuildResult : NSObject

- (instancetype)initWithProject:(Project *)project;

@property(nonatomic, readonly) Project *project;

- (void)addModifiedFiles:(NSArray *)files;

- (void)addReloadRequest:(NSDictionary *)reloadRequest;
- (BOOL)hasReloadRequests;
- (void)sendReloadRequests;

@property(nonatomic, readonly, copy) NSArray *reloadRequests;

- (void)markAsConsumedByCompiler:(LRProjectFile *)file;

@end
