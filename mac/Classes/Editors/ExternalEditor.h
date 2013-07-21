
#import "Editor.h"
#import "LRPluginCommons.h"

@interface ExternalEditor : Editor

@property(nonatomic, strong) SingleFilePlugin *script;
@property(nonatomic, copy) NSString *cocoaBundleId;

@end
