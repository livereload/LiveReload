
#import <Foundation/Foundation.h>


@interface FileCompilationOptions : NSObject {
@private
    NSString              *_sourcePath;
    NSString              *_destinationDirectory;
    NSMutableDictionary   *_additionalOptions;
}

- (id)initWithFile:(NSString *)sourcePath;

@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *destinationDirectory;
@property (nonatomic, readonly, retain) NSMutableDictionary *additionalOptions;

@end
