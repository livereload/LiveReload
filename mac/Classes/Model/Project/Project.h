
#import <Cocoa/Cocoa.h>
#import "eventbus.h"
#import "ActionList.h"


@class FSMonitor;
@class FSTree;
@class Compiler;
@class ImportGraph;
@class UserScript;
@class LRPackageResolutionContext;
@class ATPathSpec;
@class LRBuild;
@class LROperationResult;
@class LRProjectFile;


extern NSString *ProjectDidDetectChangeNotification;
extern NSString *ProjectMonitoringStateDidChangeNotification;
extern NSString *ProjectNeedsSavingNotification;
extern NSString *ProjectAnalysisDidFinishNotification;
extern NSString *ProjectBuildStartedNotification;
extern NSString *ProjectBuildFinishedNotification;


enum {
    ProjectUseCustomName = -1,
};


@interface Project : NSObject

- (id)initWithURL:(NSURL *)rootURL memento:(NSDictionary *)memento;

- (NSMutableDictionary *)memento;

@property(nonatomic, copy) NSURL *rootURL;
@property(nonatomic, readonly, copy) NSString *path;
@property(nonatomic, readonly, copy) NSString *displayName;
@property(nonatomic, readonly, copy) NSString *displayPath;
@property(nonatomic, readonly, copy) NSString *safeDisplayPath;

@property(nonatomic, copy) NSArray *urlMasks;
@property(nonatomic, copy) NSString *formattedUrlMaskList;

- (NSString *)proposedNameAtIndex:(NSInteger)index;

@property(nonatomic) NSInteger numberOfPathComponentsToUseAsName;
@property(nonatomic, copy) NSString *customName;

@property(nonatomic, readonly) BOOL exists;
@property(nonatomic, readonly) BOOL accessible;
- (void)updateAccessibility;

@property(nonatomic) BOOL enabled;

@property(nonatomic) BOOL disableLiveRefresh;
@property(nonatomic) BOOL enableRemoteServerWorkflow;
@property(nonatomic) NSTimeInterval eventProcessingDelay;
@property(nonatomic) NSTimeInterval fullPageReloadDelay;
@property(nonatomic) NSTimeInterval postProcessingGracePeriod;

@property(nonatomic) NSArray *superAdvancedOptions;
@property(nonatomic) NSString *superAdvancedOptionsString;
@property(nonatomic, readonly) NSArray *superAdvancedOptionsFeedback;
@property(nonatomic, readonly) NSString *superAdvancedOptionsFeedbackString;

@property(nonatomic, readonly) LRPackageResolutionContext *resolutionContext;

@property(nonatomic, readonly) FSTree *tree;
- (FSTree *)obtainTree;
- (void)rescanTree;

- (void)ceaseAllMonitoring;
- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key;

- (NSComparisonResult)compareByDisplayPath:(Project *)another;

- (NSString *)pathForRelativePath:(NSString *)relativePath;
- (BOOL)isPathInsideProject:(NSString *)path;
- (NSString *)relativePathForPath:(NSString *)path;

@property(nonatomic, copy) NSString *lastSelectedPane;

@property(nonatomic, getter = isDirty) BOOL dirty;

@property(nonatomic, copy) NSString *rubyVersionIdentifier;

- (void)checkBrokenPaths;

- (BOOL)isFileImported:(NSString *)path;

@property(nonatomic, readonly) NSArray *excludedPaths;

- (void)addExcludedPath:(NSString *)path;
- (void)removeExcludedPath:(NSString *)path;

@property(nonatomic, strong, readonly) ActionList *actionList;

@property(nonatomic, strong, readonly) NSArray *pathOptions;
@property(nonatomic, strong, readonly) NSArray *availableSubfolders;

- (BOOL)hackhack_shouldFilterFile:(LRProjectFile *)file;
- (void)hackhack_didFilterFile:(LRProjectFile *)file;
- (void)hackhack_didWriteCompiledFile:(LRProjectFile *)file;

@property(nonatomic, readonly, getter=isBuildInProgress) BOOL buildInProgress;
- (void)rebuildFilesAtRelativePaths:(NSArray *)relativePaths;
- (void)rebuildAll;

@property(nonatomic, readonly, getter=isAnalysisInProgress) BOOL analysisInProgress;
- (void)setAnalysisInProgress:(BOOL)analysisInProgress forTask:(id)task;

// public until we reimplement the notifications system based on listening for results
- (void)displayResult:(LROperationResult *)result key:(NSString *)key;

- (NSArray *)rootFilesForFiles:(id<NSFastEnumeration>)paths;

@property(nonatomic, readonly) ATPathSpec *forcedStylesheetReloadSpec;

@property(nonatomic, readonly) LRBuild *lastFinishedBuild;

- (NSArray *)compilerActionTypesForFile:(LRProjectFile *)file;

@end
