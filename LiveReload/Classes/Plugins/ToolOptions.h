
#import <Foundation/Foundation.h>


@class Compiler;
@class Project;
@class UIBuilder;


@interface ToolOption : NSObject

+ (ToolOption *)toolOptionWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo;

@property(nonatomic, readonly) NSString *identifier;

@property(nonatomic, readonly) NSArray *currentCompilerArguments;

- (void)renderWithBuilder:(UIBuilder *)builder;

- (void)save;

@end
