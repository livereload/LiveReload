
#import "Editor.h"

@interface ExternalEditor : Editor

- (id)initWithScriptFileURL:(NSURL*)aScriptFileURL properties:(NSDictionary*)aProperties;

@property(nonatomic, readonly, copy) NSURL *scriptFileURL;
@property(nonatomic, readonly, copy) NSDictionary *properties;

@end
