
#import <Cocoa/Cocoa.h>


@class FSMonitor;
@class FSTree;
@class Compiler;
@class CompilationOptions;

extern NSString *ProjectDidDetectChangeNotification;
extern NSString *ProjectMonitoringStateDidChangeNotification;


@interface Project : NSObject {
    NSString *_path;

    FSMonitor *_monitor;

    NSMutableDictionary     *_compilerOptions;
    BOOL _clientsConnected;

    NSMutableSet            *_monitoringRequests;
}

- (id)initWithPath:(NSString *)path;

- (id)initWithMemento:(NSDictionary *)memento;
- (NSDictionary *)memento;

@property(nonatomic, readonly, copy) NSString *path;
@property(nonatomic, readonly, copy) NSString *displayPath;

@property(nonatomic, readonly) FSTree *tree;

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create;

- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key;

- (NSComparisonResult)compareByDisplayPath:(Project *)another;

@end
