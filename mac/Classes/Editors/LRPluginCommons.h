
#import <Foundation/Foundation.h>
#import "PlainUnixTask.h"


@class SingleFilePlugin;


NSDictionary *LRExtractMetadata(NSString *content);
NSDictionary *LRExtractFileMetadata(NSURL *file);
NSArray *LRFindPluginsInFolder(NSURL *folder, NSArray *validApiValues);
NSDictionary *LRParseKeyValueOutput(NSString *output);


@interface SingleFilePlugin : NSObject

- (id)initWithScriptFileURL:(NSURL *)aScriptFileURL properties:(NSDictionary *)aProperties;

@property(nonatomic, readonly, copy) NSURL *scriptFileURL;
@property(nonatomic, readonly, copy) NSDictionary *properties;

- (id)invokeWithArguments:(NSArray *)arguments options:(LaunchUnixTaskAndCaptureOutputOptions)options completionHandler:(LaunchUnixTaskAndCaptureOutputCompletionHandler)completionHandler;

- (BOOL)updateProperties:(NSDictionary *)newProperties;

@end
