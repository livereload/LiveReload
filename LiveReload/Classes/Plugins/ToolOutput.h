
#import <Foundation/Foundation.h>


@class Compiler;
@class Project;

enum ToolOutputType {
    ToolOutputTypeLog,
    ToolOutputTypeError,
    ToolOutputTypeErrorRaw
};

@interface ToolOutput : NSObject

- (id)initWithCompiler:(Compiler *)compiler type:(enum ToolOutputType)type sourcePath:(NSString *)sourcePath line:(NSInteger)line message:(NSString *)message output:(NSString *)output;

@property (nonatomic, readonly, retain) Compiler *compiler;
@property (nonatomic, retain) Project *project;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, readonly) NSInteger line;
@property (nonatomic, readonly, copy) NSString *message;
@property (nonatomic, readonly, copy) NSString *output;

@property (nonatomic, readonly) enum ToolOutputType type;

@end
