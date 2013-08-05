
#import <Cocoa/Cocoa.h>


@class FSTreeDiffer;
@class FSTreeFilter;
@class FSTree;

@protocol FSMonitorDelegate;


@interface FSMonitor : NSObject {
    NSString *_path;
    id<FSMonitorDelegate> _delegate;
    FSTreeFilter *_filter;

    BOOL _running;

    FSEventStreamRef _streamRef;
    FSTreeDiffer *_treeDiffer;

    NSMutableSet *_eventCache;
    NSTimeInterval _cacheWaitingTime;
    NSTimeInterval _eventProcessingDelay;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly, copy) NSString *path;

@property(nonatomic, retain) FSTreeFilter *filter;

@property(nonatomic) __weak id<FSMonitorDelegate> delegate;

@property(nonatomic, getter=isRunning) BOOL running;

@property(nonatomic, readonly, retain) FSTree *tree;

@property(nonatomic, assign) NSTimeInterval eventProcessingDelay;

- (FSTree *)obtainTree;

- (void)filterUpdated;

- (void)rescan;

@end


@protocol FSMonitorDelegate <NSObject>

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes;

@end
