
#import <Cocoa/Cocoa.h>
#import "eventbus.h"


@class FSMonitor;
@class FSTree;
@class Compiler;
@class CompilationOptions;
@class FileCompilationOptions;
@class ImportGraph;
@class UserScript;


extern NSString *ProjectDidDetectChangeNotification;
extern NSString *ProjectWillBeginCompilationNotification;
extern NSString *ProjectDidEndCompilationNotification;
extern NSString *ProjectMonitoringStateDidChangeNotification;
extern NSString *ProjectNeedsSavingNotification;


enum {
    ProjectUseCustomName = -1,
};


EVENTBUS_DECLARE_EVENT(project_fs_change_event);


@interface Project : NSObject {
    NSString *_path;

    FSMonitor *_monitor;

    BOOL _clientsConnected;
    BOOL                    _enabled;

    NSMutableSet            *_monitoringRequests;

    NSString                *_lastSelectedPane;
    BOOL                     _dirty;

    NSString                *_postProcessingCommand;
    NSString                *_postProcessingScriptName;
    BOOL                     _postProcessingEnabled;
    NSTimeInterval           _lastPostProcessingRunDate;
    NSTimeInterval           _postProcessingGracePeriod;
    BOOL                     _runningPostProcessor;

    NSString                *_rubyVersionIdentifier;

    NSMutableDictionary     *_compilerOptions;
    BOOL                     _compilationEnabled;

    ImportGraph             *_importGraph;
    BOOL                     _compassDetected;

    BOOL                     _disableLiveRefresh;
    BOOL                     _enableRemoteServerWorkflow;
    NSTimeInterval           _fullPageReloadDelay;
    NSTimeInterval           _eventProcessingDelay;
    struct reload_session_t *_session;

    BOOL                     _brokenPathReported;

    NSMutableArray          *_excludedFolderPaths;
    
    NSInteger                _numberOfPathComponentsToUseAsName;
    NSString                *_customName;
    
    NSMutableSet            *_pendingChanges;
    BOOL                     _pendingPostProcessing;
    BOOL                     _processingChanges;
}

- (id)initWithPath:(NSString *)path memento:(NSDictionary *)memento;

- (NSMutableDictionary *)memento;

@property(nonatomic, readonly, copy) NSString *path;
@property(nonatomic, readonly, copy) NSString *displayName;
@property(nonatomic, readonly, copy) NSString *displayPath;
@property(nonatomic, readonly, copy) NSString *safeDisplayPath;

- (NSString *)proposedNameAtIndex:(NSInteger)index;

@property(nonatomic) NSInteger numberOfPathComponentsToUseAsName;
@property(nonatomic, copy) NSString *customName;

@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL compilationEnabled;

@property(nonatomic) BOOL disableLiveRefresh;
@property(nonatomic) BOOL enableRemoteServerWorkflow;
@property(nonatomic) NSTimeInterval eventProcessingDelay;
@property(nonatomic) NSTimeInterval fullPageReloadDelay;
@property(nonatomic) NSTimeInterval postProcessingGracePeriod;

@property(nonatomic, readonly) FSTree *tree;

@property(nonatomic, readonly) NSArray *compilersInUse;

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)sourcePath in:(CompilationOptions *)compilationOptions;

- (void)ceaseAllMonitoring;
- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key;

- (NSComparisonResult)compareByDisplayPath:(Project *)another;

- (NSString *)pathForRelativePath:(NSString *)relativePath;
- (BOOL)isPathInsideProject:(NSString *)path;
- (NSString *)relativePathForPath:(NSString *)path;

@property(nonatomic, copy) NSString *lastSelectedPane;

@property(nonatomic, getter = isDirty) BOOL dirty;

@property(nonatomic, retain) NSString *postProcessingCommand;
@property(nonatomic, retain) NSString *postProcessingScriptName;
@property(nonatomic, readonly) UserScript *postProcessingScript;
@property(nonatomic) BOOL postProcessingEnabled;

@property(nonatomic, copy) NSString *rubyVersionIdentifier;

- (void)checkBrokenPaths;

- (BOOL)isFileImported:(NSString *)path;

@property(nonatomic, readonly) NSArray *excludedPaths;

- (void)addExcludedPath:(NSString *)path;
- (void)removeExcludedPath:(NSString *)path;

@end
