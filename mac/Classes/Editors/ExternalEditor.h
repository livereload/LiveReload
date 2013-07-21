
#import "Editor.h"
#import "LRPluginCommons.h"

@interface ExternalEditor : Editor

@property(nonatomic, strong) SingleFilePlugin *script;
@property(nonatomic, copy) NSString *cocoaBundleId;
@property(nonatomic, copy) NSString *magicURL1;
@property(nonatomic, copy) NSString *magicURL2;
@property(nonatomic, copy) NSString *magicURL3;

@end
