
#import <Cocoa/Cocoa.h>


@class FSTreeDiffer;
@class FSTreeFilter;

@protocol FSMonitorDelegate;


@interface FSMonitor : NSObject {
    NSString *_path;
    id<FSMonitorDelegate> _delegate;
    FSTreeFilter *_filter;

    BOOL _running;

    FSEventStreamRef _streamRef;
    FSTreeDiffer *_treeDiffer;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly, copy) NSString *path;

@property(nonatomic, retain) FSTreeFilter *filter;

@property(nonatomic, assign) __weak id<FSMonitorDelegate> delegate;

@property(nonatomic, getter=isRunning) BOOL running;

- (void)filterUpdated;

@end


@protocol FSMonitorDelegate <NSObject>

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes;

@end
