
#import <Foundation/Foundation.h>


@interface FileCompilationOptions : NSObject {
@private
    NSString              *_sourcePath;
    NSString              *_destinationDirectory;
    NSMutableDictionary   *_additionalOptions;
}

- (id)initWithFile:(NSString *)sourcePath memento:(NSDictionary *)memento;

- (NSDictionary *)memento;

@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *destinationDirectory;
@property (nonatomic, readonly, retain) NSMutableDictionary *additionalOptions;

+ (NSString *)commonOutputDirectoryFor:(NSArray *)fileOptions;  // nil if files have different output directories, or no files configured

@end
