
#import <Cocoa/Cocoa.h>


@class FSMonitor;
@class FSTree;
@class Compiler;
@class CompilationOptions;
@class FileCompilationOptions;
@class ImportGraph;

extern NSString *ProjectDidDetectChangeNotification;
extern NSString *ProjectWillBeginCompilationNotification;
extern NSString *ProjectDidEndCompilationNotification;
extern NSString *ProjectMonitoringStateDidChangeNotification;
extern NSString *ProjectNeedsSavingNotification;


@interface Project : NSObject {
    NSString *_path;

    FSMonitor *_monitor;

    BOOL _clientsConnected;
    BOOL                    _enabled;

    NSMutableSet            *_monitoringRequests;

    NSString                *_lastSelectedPane;
    BOOL                     _dirty;

    NSString                *_postProcessingCommand;
    BOOL                     _postProcessingEnabled;
    NSTimeInterval           _lastPostProcessingRunDate;

    NSMutableDictionary     *_compilerOptions;
    BOOL                     _compilationEnabled;

    ImportGraph             *_importGraph;
    BOOL                     _compassDetected;

    BOOL                     _disableLiveRefresh;
    NSTimeInterval           _fullPageReloadDelay;
    NSMutableSet            *_changesToBroadcast;

    BOOL                     _brokenPathReported;
}

- (id)initWithPath:(NSString *)path memento:(NSDictionary *)memento;

- (NSDictionary *)memento;

@property(nonatomic, readonly, copy) NSString *path;
@property(nonatomic, readonly, copy) NSString *displayPath;
@property(nonatomic, readonly, copy) NSString *safeDisplayPath;

@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL compilationEnabled;

@property(nonatomic) BOOL disableLiveRefresh;
@property(nonatomic) NSTimeInterval fullPageReloadDelay;

@property(nonatomic, readonly) FSTree *tree;

@property(nonatomic, readonly) NSArray *compilersInUse;

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)sourcePath in:(CompilationOptions *)compilationOptions;

- (void)ceaseAllMonitoring;
- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key;

- (NSComparisonResult)compareByDisplayPath:(Project *)another;

- (NSString *)relativePathForPath:(NSString *)path;

@property(nonatomic, copy) NSString *lastSelectedPane;

@property(nonatomic, getter = isDirty) BOOL dirty;

@property(nonatomic, retain) NSString *postProcessingCommand;
@property(nonatomic) BOOL postProcessingEnabled;

- (void)checkBrokenPaths;

@end
