
#import <Foundation/Foundation.h>


@class Project;
@class LRProjectFile;
@class LRTargetResult;
@class LROperationResult;


extern NSString *const LRBuildDidFinishNotification;


@interface LRBuildResult : NSObject

- (instancetype)initWithProject:(Project *)project actions:(NSArray *)actions;

@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly, copy) NSArray *actions;

- (void)addModifiedFiles:(NSArray *)files;

- (void)addReloadRequest:(NSDictionary *)reloadRequest;
- (BOOL)hasReloadRequests;
- (void)sendReloadRequests;

@property(nonatomic, readonly, copy) NSArray *reloadRequests;

- (void)markAsConsumedByCompiler:(LRProjectFile *)file;

@property(nonatomic, readonly, getter = isStarted) BOOL started;
@property(nonatomic, readonly, getter = isFinished) BOOL finished;
@property(nonatomic, readonly, getter = isFailed) BOOL failed;
@property(nonatomic, readonly) LROperationResult *firstFailure;

- (void)start;

- (void)addOperationResult:(LROperationResult *)result forTarget:(LRTargetResult *)target key:(NSString *)key;

@end
