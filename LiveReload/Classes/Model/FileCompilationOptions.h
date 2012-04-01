
#import <Foundation/Foundation.h>


@class Project;

@interface FileCompilationOptions : NSObject {
@private
    BOOL                   _enabled;
    NSString              *_sourcePath;
    NSString              *_destinationDirectory;
    NSString              *_destinationNameMask;
    NSMutableDictionary   *_additionalOptions;
}

- (id)initWithFile:(NSString *)sourcePath memento:(NSDictionary *)memento;

- (NSDictionary *)memento;

@property (nonatomic) BOOL enabled;
@property (nonatomic, readonly, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *destinationDirectory;
@property (nonatomic, copy) NSString *destinationDirectoryForDisplay;
@property (nonatomic, copy) NSString *destinationPath;
@property (nonatomic, copy) NSString *destinationPathForDisplay;
@property (nonatomic, copy) NSString *destinationName;
@property (nonatomic, copy) NSString *destinationNameMask;
@property (nonatomic, readonly, retain) NSMutableDictionary *additionalOptions;

- (NSString *)destinationNameForMask:(NSString *)destinationNameMask;
- (NSString *)destinationDisplayPathForMask:(NSString *)destinationNameMask;

+ (NSString *)commonOutputDirectoryFor:(NSArray *)fileOptions inProject:(Project *)project;  // nil if files have different output directories, or no files configured
+ (NSString *)commonDestinationNameMaskFor:(NSArray *)fileOptions inProject:(Project *)project;

@end
