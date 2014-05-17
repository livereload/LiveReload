
#import <Foundation/Foundation.h>
#import "ActionType.h"
#import "UserScript.h"
#import "ATPathSpec.h"
#import "FilterOption.h"


@class Project;
@class LRProjectFile;
@class LRContextActionType;
@class LRActionVersion;
@class LRVersionSpec;
@class ScriptInvocationStep;
@class LRTargetResult;
@class LROperationResult;


extern NSString *const LRActionPrimaryEffectiveVersionDidChangeNotification;


@interface Action : NSObject

- (id)initWithContextActionType:(LRContextActionType *)contextActionType memento:(NSDictionary *)memento;

@property(nonatomic, readonly) ActionType *type;
@property(nonatomic, readonly) LRContextActionType *contextActionType;
@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly) ActionKind kind; // derived from type
@property(nonatomic, copy) NSDictionary *memento;

@property(nonatomic, readonly, strong) NSString *label;

// automatically invoked when reading
- (void)loadFromMemento:(NSDictionary *)memento;
- (void)updateMemento:(NSMutableDictionary *)memento;

@property(nonatomic) BOOL enabled;

@property(nonatomic, readonly, getter = isNonEmpty) BOOL nonEmpty;

@property(nonatomic, strong) FilterOption *inputFilterOption;
@property(nonatomic, readonly, strong) ATPathSpec *inputPathSpec;

@property(nonatomic, strong) ATPathSpec *intrinsicInputPathSpec;

- (LRTargetResult *)targetForModifiedFiles:(NSSet *)paths;

- (NSArray *)fileTargetsForModifiedFiles:(NSSet *)paths;

- (BOOL)shouldInvokeForFile:(LRProjectFile *)file;
- (void)analyzeFile:(LRProjectFile *)file inProject:(Project *)project;
- (void)compileFile:(LRProjectFile *)file inProject:(Project *)project result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler;
- (void)handleDeletionOfFile:(LRProjectFile *)file inProject:(Project *)project;

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSSet *)paths result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler;

//- (void)invokeForFileAtPath:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project completionHandler:(dispatch_block_t)completionHandler;

// custom options
@property(nonatomic, copy) NSString *customArgumentsString;
@property(nonatomic, copy) NSArray *customArguments;
@property(nonatomic, copy) NSDictionary *options;
- (id)optionValueForKey:(NSString *)key;
- (void)setOptionValue:(id)value forKey:(NSString *)key;

- (NSArray *)createOptions;

@property(nonatomic) LRVersionSpec *primaryVersionSpec;
@property(nonatomic, readonly) LRActionVersion *effectiveVersion;
@property(nonatomic, readonly) NSError *missingEffectiveVersionError;

// for overriders
- (void)didChange;
- (BOOL)inputPathSpecMatchesPaths:(NSSet *)paths;
- (BOOL)supportsFileTargets;
- (LRTargetResult *)fileTargetForRootFile:(LRProjectFile *)file;

// override points / for overriders
- (void)configureStep:(ScriptInvocationStep *)step;
- (void)configureResult:(LROperationResult *)result;

@end
