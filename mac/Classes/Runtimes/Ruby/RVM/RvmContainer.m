
#import "RvmContainer.h"
#import "ATSandboxing.h"



NSString *GetDefaultRvmPath() {
    return [ATRealHomeDirectory() stringByAppendingPathComponent:@".rvm"];
}



@implementation RvmContainer

@end
