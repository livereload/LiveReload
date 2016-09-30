
#import <Foundation/Foundation.h>


@class Compiler;
@class Project;

typedef NS_ENUM(NSInteger, ToolOutputType) {
    ToolOutputTypeLog,
    ToolOutputTypeError,
    ToolOutputTypeErrorRaw
};

@interface ToolOutput : NSObject

- (instancetype)initWithCompiler:(Compiler *)compiler type:(ToolOutputType)type sourcePath:(NSString *)sourcePath line:(NSInteger)line message:(NSString *)message output:(NSString *)output;

@property (nonatomic, readonly, retain) Compiler *compiler;
@property (nonatomic, retain) Project *project;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic) NSInteger line;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *output;

@property (nonatomic) enum ToolOutputType type;

@end
