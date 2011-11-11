
#import <Foundation/Foundation.h>


@class Compiler;
@class Project;
@class UIBuilder;


@interface ToolOption : NSObject

+ (ToolOption *)toolOptionWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo;

@property(nonatomic, readonly) NSString *identifier;

- (void)renderWithBuilder:(UIBuilder *)builder;

- (void)save;

@end
