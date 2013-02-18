
#import <Foundation/Foundation.h>

@interface Editor : NSObject

+ (NSString *)editorDisplayName;
@property (nonatomic, readonly) NSString *name;

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line;

+ (Editor *)detectEditor;

@end
