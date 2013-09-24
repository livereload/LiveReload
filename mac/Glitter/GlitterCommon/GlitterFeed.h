
#import <Foundation/Foundation.h>


@interface GlitterSource : NSObject

@property(nonatomic, readonly, copy) NSURL *url;
@property(nonatomic, readonly) unsigned long size;
@property(nonatomic, readonly, copy) NSString *sha1;

- (id)initWithUrl:(NSURL *)url size:(unsigned long)size sha1:(NSString *)sha1;

@end


@interface GlitterVersion : NSObject

@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly, copy) NSString *version;
@property(nonatomic, copy) NSString *versionDisplayName;
@property(nonatomic, copy) NSArray *channelNames;
@property(nonatomic, copy) NSString *compatibleVersionRange;
@property(nonatomic, readonly, strong) GlitterSource *source;

- (id)initWithVersion:(NSString *)version versionDisplayName:(NSString *)versionDisplayName channelNames:(NSArray *)channelNames source:(GlitterSource *)source;

@end


NSArray *GlitterParseFeedData(NSData *feedData, NSError **error);
