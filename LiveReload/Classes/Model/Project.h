
#import <Cocoa/Cocoa.h>


@interface Project : NSObject {
	NSString *_path;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly, copy) NSString *path;

@end
