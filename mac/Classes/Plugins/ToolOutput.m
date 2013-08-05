
#import "ToolOutput.h"
#import "Compiler.h"


@implementation ToolOutput

@synthesize compiler=_compiler;
@synthesize project=_project;
@synthesize type=_type;
@synthesize sourcePath=_sourcePath;
@synthesize line=_line;
@synthesize message=_message;
@synthesize output=_output;


- (id)initWithCompiler:(Compiler *)compiler type:(enum ToolOutputType)type sourcePath:(NSString *)sourcePath line:(NSInteger)line message:(NSString *)message output:(NSString *)output {
    self = [super init];
    if (self) {
        _compiler = [compiler retain];
        _type = type;
        _sourcePath = [sourcePath copy];
        _line = line;
        _message = [message copy];
        _output = [output copy];
    }
    return self;
}

@end
