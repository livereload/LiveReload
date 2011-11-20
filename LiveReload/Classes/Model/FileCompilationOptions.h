
#import <Foundation/Foundation.h>


@interface FileCompilationOptions : NSObject {
@private
    BOOL                   _enabled;
    NSString              *_sourcePath;
    NSString              *_destinationDirectory;
    NSMutableDictionary   *_additionalOptions;
}

- (id)initWithFile:(NSString *)sourcePath memento:(NSDictionary *)memento;

- (NSDictionary *)memento;

@property (nonatomic) BOOL enabled;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *destinationDirectory;
@property (nonatomic, copy) NSString *destinationDirectoryForDisplay;
@property (nonatomic, readonly, retain) NSMutableDictionary *additionalOptions;

+ (NSString *)commonOutputDirectoryFor:(NSArray *)fileOptions;  // nil if files have different output directories, or no files configured

@end
