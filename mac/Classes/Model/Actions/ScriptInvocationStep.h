
#import <Foundation/Foundation.h>


@class Project;
@class LRFile2;
@class ToolOutput;
@class RuntimeInstance;


@interface ScriptInvocationStep : NSObject

@property(nonatomic, retain) Project *project;  // for collapsing the paths in the console log

@property(nonatomic, copy) NSArray *commandLine;
@property(nonatomic, copy) NSDictionary *manifest;

@property(nonatomic, retain) RuntimeInstance *rubyInstance;

- (void)addValue:(id)value forSubstitutionKey:(NSString *)key;
- (void)addFileValue:(LRFile2 *)file forSubstitutionKey:(NSString *)key;

- (void)invoke;

- (LRFile2 *)fileForKey:(NSString *)key;

@property(nonatomic) BOOL finished;
@property(nonatomic, retain) NSError *error;
@property(nonatomic, retain) ToolOutput *output;

typedef void (^ScriptInvocationStepCompletionHandler)(ScriptInvocationStep *step);
@property(nonatomic, copy) ScriptInvocationStepCompletionHandler completionHandler;

@end
