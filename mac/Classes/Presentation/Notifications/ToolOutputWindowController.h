
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class ToolOutput;


@interface ToolOutputWindowController : NSWindowController

- (id)initWithCompilerOutput:(ToolOutput *)compilerOutput key:(NSString *)key;

- (void)show;

+ (void)hideOutputWindowWithKey:(NSString *)key;

@end
