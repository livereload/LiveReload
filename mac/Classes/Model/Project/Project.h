
#import <Cocoa/Cocoa.h>
#import "eventbus.h"
#import "ActionList.h"


@class FSMonitor;
@class FSTree;
@class Compiler;
@class CompilationOptions;
@class LRFile;
@class ImportGraph;
@class UserScript;
@class LRPackageResolutionContext;


extern NSString *ProjectDidDetectChangeNotification;
extern NSString *ProjectWillBeginCompilationNotification;
extern NSString *ProjectDidEndCompilationNotification;
extern NSString *ProjectMonitoringStateDidChangeNotification;
extern NSString *ProjectNeedsSavingNotification;
extern NSString *ProjectAnalysisDidFinishNotification;
extern NSString *ProjectBuildFinishedNotification;


enum {
    ProjectUseCustomName = -1,
};


@interface Project : NSObject {
    NSURL                   *_rootURL;
    NSString                *_path;
    BOOL                     _accessible;
    BOOL                     _accessingSecurityScopedResource;

    FSMonitor *_monitor;

    BOOL _clientsConnected;
    BOOL                    _enabled;

    NSMutableSet            *_monitoringRequests;

    NSString                *_lastSelectedPane;
    BOOL                     _dirty;

    NSString                *_postProcessingCommand;
    NSString                *_postProcessingScriptName;
    BOOL                     _postProcessingEnabled;
    NSTimeInterval           _postProcessingGracePeriod;

    NSString                *_rubyVersionIdentifier;

    NSMutableDictionary     *_compilerOptions;
    BOOL                     _compilationEnabled;
    BOOL                     _legacyCompilationEnabled;

    ImportGraph             *_importGraph;
    BOOL                     _compassDetected;

    BOOL                     _disableLiveRefresh;
    BOOL                     _enableRemoteServerWorkflow;
    NSTimeInterval           _fullPageReloadDelay;
    NSTimeInterval           _eventProcessingDelay;

    BOOL                     _brokenPathReported;

    NSMutableArray          *_excludedFolderPaths;
    
    NSInteger                _numberOfPathComponentsToUseAsName;
    NSString                *_customName;
    
    NSArray                 *_urlMasks;
    
    NSMutableSet            *_pendingChanges;
    BOOL                     _processingChanges;

    BOOL                     _runningPostProcessor;
    BOOL                     _pendingPostProcessing;
    NSTimeInterval           _lastPostProcessingRunDate;

    NSInteger                _buildsRunning;

    NSMutableDictionary     *_fileDatesHack;

    NSMutableSet            *_runningAnalysisTasks;

    BOOL                     _quuxMode;
    ATPathSpec              *_forcedStylesheetReloadSpec;
}

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
@property(nonatomic) BOOL compilationEnabled;

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

@property(nonatomic, readonly) NSArray *compilersInUse;

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create;

- (LRFile *)optionsForFileAtPath:(NSString *)sourcePath in:(CompilationOptions *)compilationOptions;

- (void)ceaseAllMonitoring;
- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key;

- (NSComparisonResult)compareByDisplayPath:(Project *)another;

- (NSString *)pathForRelativePath:(NSString *)relativePath;
- (BOOL)isPathInsideProject:(NSString *)path;
- (NSString *)relativePathForPath:(NSString *)path;

@property(nonatomic, copy) NSString *lastSelectedPane;

@property(nonatomic, getter = isDirty) BOOL dirty;

@property(nonatomic, strong) NSString *postProcessingCommand;
@property(nonatomic, strong) NSString *postProcessingScriptName;
@property(nonatomic, readonly) UserScript *postProcessingScript;
@property(nonatomic) BOOL postProcessingEnabled;

@property(nonatomic, copy) NSString *rubyVersionIdentifier;

- (void)checkBrokenPaths;

- (BOOL)isFileImported:(NSString *)path;

@property(nonatomic, readonly) NSArray *excludedPaths;

- (void)addExcludedPath:(NSString *)path;
- (void)removeExcludedPath:(NSString *)path;

@property(nonatomic, strong, readonly) ActionList *actionList;

@property(nonatomic, strong, readonly) NSArray *pathOptions;
@property(nonatomic, strong, readonly) NSArray *availableSubfolders;

- (BOOL)hackhack_shouldFilterFile:(LRFile2 *)file;
- (void)hackhack_didFilterFile:(LRFile2 *)file;
- (void)hackhack_didWriteCompiledFile:(LRFile2 *)file;

@property(nonatomic, readonly, getter=isBuildInProgress) BOOL buildInProgress;
- (void)rebuildAll;

@property(nonatomic, readonly, getter=isAnalysisInProgress) BOOL analysisInProgress;
- (void)setAnalysisInProgress:(BOOL)analysisInProgress forTask:(id)task;

@end
