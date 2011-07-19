
#import <Foundation/Foundation.h>


@class Compiler;
@class Project;


@interface ToolError : NSObject

- (id)initWithCompiler:(Compiler *)compiler sourcePath:(NSString *)sourcePath line:(NSInteger)line message:(NSString *)message output:(NSString *)output;

@property (nonatomic, readonly, retain) Compiler *compiler;
@property (nonatomic, retain) Project *project;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, readonly) NSInteger line;
@property (nonatomic, readonly, copy) NSString *message;
@property (nonatomic, readonly, copy) NSString *output;

@end
