
#import <Foundation/Foundation.h>


@class Plugin;

@interface Compiler : NSObject {
@private
    __weak Plugin    *_plugin;
    NSString         *_name;
    NSArray          *_commandLine;
    NSArray          *_extensions;
    NSString         *_destinationExtension;
    NSArray          *_errorFormats;
}

- (id)initWithDictionary:(NSDictionary *)info plugin:(Plugin *)plugin;

@property(nonatomic, readonly) NSArray *extensions;
@property(nonatomic, readonly) NSString *destinationExtension;

- (NSString *)derivedNameForFile:(NSString *)path;

- (void)compile:(NSString *)sourcePath into:(NSString *)destinationPath;

@end
