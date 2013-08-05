
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

@property (nonatomic, readonly, strong) Compiler *compiler;
@property (nonatomic, strong) Project *project;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic) NSInteger line;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *output;

@property (nonatomic) enum ToolOutputType type;

@end
