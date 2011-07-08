
#import <Cocoa/Cocoa.h>


@class FSMonitor;
@class Compiler;
@class CompilationOptions;

extern NSString *ProjectDidDetectChangeNotification;


@interface Project : NSObject {
    NSString *_path;

    FSMonitor *_monitor;

    NSMutableDictionary     *_compilerOptions;
}

- (id)initWithPath:(NSString *)path;

- (id)initWithMemento:(NSDictionary *)memento;
- (NSDictionary *)memento;

@property(nonatomic, readonly, copy) NSString *path;

@property(nonatomic, getter=isMonitoringEnabled) BOOL monitoringEnabled;

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create;

@end
