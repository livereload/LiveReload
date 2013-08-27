
#import <Foundation/Foundation.h>
#import "ActionType.h"
#import "UserScript.h"
#import "ATPathSpec.h"
#import "FilterOption.h"


@class Project;
@class LRFile2;


@interface Action : NSObject

- (id)initWithType:(ActionType *)type memento:(NSDictionary *)memento;

@property(nonatomic, readonly) ActionType *type;
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

- (BOOL)shouldInvokeForModifiedFiles:(NSSet *)paths inProject:(Project *)project;

- (void)analyzeFile:(LRFile2 *)file inProject:(Project *)project;
- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler;

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler;

//- (void)invokeForFileAtPath:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler;

@end
