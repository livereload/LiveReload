@import Foundation;
@import LRActionKit;


@interface Plugin : NSObject <LRManifestErrorSink, ActionContainer> {
@private
    NSString         *_path;
    NSDictionary     *_info;
    NSArray          *_compilers;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly) NSURL *folderURL;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) NSArray *compilers;
@property(nonatomic, readonly) NSArray *actions;

@property(nonatomic, readonly) NSArray *errors;
- (void)addErrorMessage:(NSString *)message;

@property(nonatomic, readonly) NSArray *bundledPackageContainers;

@end
