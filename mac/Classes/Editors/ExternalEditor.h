
#import "Editor.h"
#import "LRPluginCommons.h"

@interface ExternalEditor : Editor

- (id)initWithScript:(SingleFilePlugin*)aScript;

@property(nonatomic, readonly, strong) SingleFilePlugin *script;

@end
