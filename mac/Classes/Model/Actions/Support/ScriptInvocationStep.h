
#import <Foundation/Foundation.h>


@class Project;
@class LRFile2;
@class RuntimeInstance;
@class LROperationResult;


typedef void (^ScriptInvocationOutputLineBlock)(NSString *line);


@interface ScriptInvocationStep : NSObject

@property(nonatomic, retain) Project *project;  // for collapsing the paths in the console log

@property(nonatomic, copy) NSArray *commandLine;
@property(nonatomic) LROperationResult *result;

@property(nonatomic, retain) RuntimeInstance *rubyInstance;

- (void)addValue:(id)value forSubstitutionKey:(NSString *)key;
- (void)addFileValue:(LRFile2 *)file forSubstitutionKey:(NSString *)key;

- (void)invoke;

- (LRFile2 *)fileForKey:(NSString *)key;

@property(nonatomic) BOOL finished;
@property(nonatomic, retain) NSError *error;

typedef void (^ScriptInvocationStepCompletionHandler)(ScriptInvocationStep *step);
@property(nonatomic, copy) ScriptInvocationStepCompletionHandler completionHandler;

@property(nonatomic, copy) ScriptInvocationOutputLineBlock outputLineBlock;

@end
