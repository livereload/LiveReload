
#import "EKEditor.h"
#import "LRPluginCommons.h"

@interface ExternalEditor : EKEditor

@property(nonatomic, strong) SingleFilePlugin *script;
@property(nonatomic, copy) NSString *magicURL1;
@property(nonatomic, copy) NSString *magicURL2;
@property(nonatomic, copy) NSString *magicURL3;

@end
