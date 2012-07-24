
#import <Foundation/Foundation.h>


extern NSString *RubyVersionsDidChangeNotification;


@interface RvmInstance : NSObject

+ (NSArray *)rvmInstances;

+ (void)addRvmInstanceAtPath:(NSString *)path;

- (NSArray *)availableRubyVersions;

@end


@interface RubyVersion : NSObject

+ (RubyVersion *)rubyVersionWithIdentifier:(NSString *)identifier;
+ (NSArray *)availableRubyVersions;

@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *displayTitle;
@property(nonatomic, readonly) NSString *executablePath;
@property(nonatomic, readonly) NSDictionary *environmentModifications;
@property(nonatomic, readonly, getter=isValid) BOOL valid;

@end
