
#import <Cocoa/Cocoa.h>


@interface FSMonitor : NSObject {
    NSString *_path;

    BOOL _running;

    FSEventStreamRef _streamRef;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly, copy) NSString *path;

@property(nonatomic, getter=isRunning) BOOL running;

@end
