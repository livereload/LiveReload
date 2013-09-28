
#import <Foundation/Foundation.h>

#import "GlitterGlobals.h"


extern NSString *const GlitterStatusDidChangeNotification;
extern NSString *const GlitterUserInitiatedUpdateCheckDidFinishNotification;

#define GlitterCombinedNewsVersionKey @"version"
#define GlitterCombinedNewsVersionDisplayNameKey @"versionDisplayName"
#define GlitterCombinedNewsVersionNewsKey @"news"


typedef enum {
    GlitterDownloadStepNone = 0,
    GlitterDownloadStepDownload = 1,
    GlitterDownloadStepUnpack = 2,
} GlitterDownloadStep;


@interface Glitter : NSObject

- (id)initWithMainBundle;

@property(nonatomic, copy) NSString *channelName;
@property(nonatomic, getter=isChannelNameSet) BOOL channelNameSet;

- (void)checkForUpdatesWithOptions:(GlitterCheckOptions)options;
- (void)installUpdate;

@property(nonatomic, readonly, getter = isChecking) BOOL checking;
@property(nonatomic, readonly, getter = isCheckUserInitiated) BOOL checkIsUserInitiated;

@property(nonatomic, getter=isAutomaticCheckingEnabled) BOOL automaticCheckingEnabled;

@property(nonatomic, readonly, getter = isDownloading) BOOL downloading;
@property(nonatomic, readonly) GlitterDownloadStep downloadStep;
@property(nonatomic, readonly) double downloadProgress;
@property(nonatomic, readonly, copy) NSString *downloadingVersionDisplayName;

@property(nonatomic, readonly, getter = isReadyToInstall) BOOL readyToInstall;
@property(nonatomic, readonly, copy) NSString *readyToInstallVersionDisplayName;
@property(nonatomic, readonly, copy) NSArray *readyToInstallCombinedNews;

@end
