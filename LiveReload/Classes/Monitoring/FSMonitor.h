
#import <Cocoa/Cocoa.h>


@class FSTreeDiffer;

@protocol FSMonitorDelegate;


@interface FSMonitor : NSObject {
    NSString *_path;

    BOOL _running;

    FSEventStreamRef _streamRef;
    FSTreeDiffer *_treeDiffer;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly, copy) NSString *path;

@property(nonatomic, assign) __weak id<FSMonitorDelegate> delegate;

@property(nonatomic, getter=isRunning) BOOL running;

@end


@protocol FSMonitorDelegate <NSObject>

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes;

@end
