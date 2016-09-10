#import <Cocoa/Cocoa.h>
#import "FSChange.h"


@class FSTreeDiffer;
@class FSTreeFilter;
@class FSTree;

@protocol FSMonitorDelegate;


@interface FSMonitor : NSObject {
    NSString *_path;
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

@property(nonatomic, strong) FSTreeFilter *filter;

@property(weak, nonatomic) id<FSMonitorDelegate> delegate;

@property(nonatomic, getter=isRunning) BOOL running;

@property(nonatomic, readonly, strong) FSTree *tree;

@property(nonatomic, assign) NSTimeInterval eventProcessingDelay;

- (FSTree *)obtainTree;

- (void)filterUpdated;

- (void)rescan;

@end


@protocol FSMonitorDelegate <NSObject>

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChange:(FSChange *)change;

@optional

- (void)fileSystemMonitorDidWorkAroundFSEventsBug:(FSMonitor *)monitor;
- (void)fileSystemMonitor:(FSMonitor *)monitor didFailToWorkAroundFSEventsBugWithRootBrokenFolderPath:(NSString *)rootBrokenFolderPath;

@end
