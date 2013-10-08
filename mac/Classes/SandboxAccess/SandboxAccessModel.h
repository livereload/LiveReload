
#import <Foundation/Foundation.h>

@interface SandboxAccessModel : NSObject

- (id)initWithDataFileURL:(NSURL *)dataFileURL;

@property(nonatomic, readonly, copy) NSURL *dataFileURL;
@property(nonatomic, readonly, copy) NSArray *accessibleURLs;

- (NSURL *)grantAccessToURL:(NSURL *)url writeAccess:(BOOL)writeAccess title:(NSString *)title message:(NSString *)message;

@end
