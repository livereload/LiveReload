
#import "GlitterFeed.h"
#import "GlitterGlobals.h"


#define GlitterFeedFormatVersionKey @"glitterFeedVersion"
#define GlitterFeedVersionsKey @"versions"
#define GlitterFeedVersionCodeKey @"versionCode"
#define GlitterFeedVersionDisplayNameKey @"versionDisplayName"
#define GlitterFeedVersionChannelsKey @"channels"
#define GlitterFeedVersionCompatibleVersionRangeKey @"requires"

#define GlitterFeedVersionDistKey @"dist"
#define GlitterFeedVersionDistURLKey @"url"
#define GlitterFeedVersionDistSizeKey @"size"
#define GlitterFeedVersionDistSha1Key @"sha1"


#define return_error(returnValue, outError, error)  \
    do { \
        if (outError) *outError = error; \
        return returnValue; \
    } while(0)



@implementation GlitterVersion

- (id)initWithVersion:(NSString *)version versionDisplayName:(NSString *)versionDisplayName channelNames:(NSArray *)channelNames source:(GlitterSource *)source {
    self = [super init];
    if (self) {
        _version = [version copy];
        _versionDisplayName = [versionDisplayName copy];
        _channelNames = [channelNames copy];
        _source = source;
        _identifier = [NSString stringWithFormat:@"%@:%@", _version, _source.sha1];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"v%@(%@, %@, at %@)", _version, _versionDisplayName, [_channelNames componentsJoinedByString:@"+"], _source.description];
}

@end



@implementation GlitterSource

- (id)initWithUrl:(NSURL *)url size:(unsigned long)size sha1:(NSString *)sha1 {
    self = [super init];
    if (self) {
        _url = url;
        _size = size;
        _sha1 = [sha1 copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"(%@)", _url];
}

@end



NSArray *GlitterParseFeedData(NSData *feedData, NSError **outError) {
    NSError * __autoreleasing error = nil;

    NSDictionary *feed = [NSJSONSerialization JSONObjectWithData:feedData options:0 error:&error];
    if (!feed)
        return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"failed to parse feed JSON: %@", error.localizedDescription], NSUnderlyingErrorKey: error}]));

    if (![feed isKindOfClass:[NSDictionary class]])
        return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed JSON is not a dictionary", NSUnderlyingErrorKey: error}]));

    // check format version
    NSNumber *formatVersionRaw = feed[GlitterFeedFormatVersionKey];
    if (![formatVersionRaw isKindOfClass:[NSNumber class]])
        return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedFormatVersionKey " is not a number", NSUnderlyingErrorKey: error}]));
    if ([formatVersionRaw intValue] != 1)
        return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedFormatVersionKey " is not 1", NSUnderlyingErrorKey: error}]));

    NSArray *versionsRaw = feed[GlitterFeedVersionsKey];
    if (![versionsRaw isKindOfClass:[NSArray class]])
        return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionsKey " is missing or not an array", NSUnderlyingErrorKey: error}]));

    NSMutableArray *availableVersions = [[NSMutableArray alloc] init];
    for (NSDictionary *versionRaw in versionsRaw) {
        NSString *versionNumber = versionRaw[GlitterFeedVersionCodeKey];
        if (![versionNumber isKindOfClass:[NSString class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionCodeKey " is missing or not a string", NSUnderlyingErrorKey: error}]));

        NSString *versionDisplayName = versionRaw[GlitterFeedVersionDisplayNameKey];
        if (![versionDisplayName isKindOfClass:[NSString class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionDisplayNameKey " is missing or not a string", NSUnderlyingErrorKey: error}]));

        NSString *versionCompatibleRange = versionRaw[GlitterFeedVersionCompatibleVersionRangeKey];
        if (![versionCompatibleRange isKindOfClass:[NSString class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionCompatibleVersionRangeKey " is missing or not a string", NSUnderlyingErrorKey: error}]));

        NSArray *versionChannelNames = versionRaw[GlitterFeedVersionChannelsKey];
        if (![versionChannelNames isKindOfClass:[NSArray class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionChannelsKey " is missing or not an array", NSUnderlyingErrorKey: error}]));

        NSDictionary *distRaw = versionRaw[GlitterFeedVersionDistKey];
        if (![distRaw isKindOfClass:[NSDictionary class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionDistKey " is missing or not a dictionary", NSUnderlyingErrorKey: error}]));

        NSString *distURL = distRaw[GlitterFeedVersionDistURLKey];
        if (![distURL isKindOfClass:[NSString class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionDistURLKey " is missing or not a string", NSUnderlyingErrorKey: error}]));

        NSNumber *distSize = distRaw[GlitterFeedVersionDistSizeKey];
        if (![distSize isKindOfClass:[NSNumber class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionDistSizeKey " is missing or not a number", NSUnderlyingErrorKey: error}]));

        NSString *distSha1 = distRaw[GlitterFeedVersionDistSha1Key];
        if (![distSha1 isKindOfClass:[NSString class]])
            return_error(nil, outError, ([NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedInvalidFeedFormat userInfo:@{NSLocalizedDescriptionKey:@"feed format error - " GlitterFeedVersionDistSha1Key " is missing or not a string", NSUnderlyingErrorKey: error}]));

        GlitterSource *source = [[GlitterSource alloc] initWithUrl:[NSURL URLWithString:distURL] size:[distSize longValue] sha1:distSha1];
        GlitterVersion *version = [[GlitterVersion alloc] initWithVersion:versionNumber versionDisplayName:versionDisplayName channelNames:versionChannelNames source:source];
        version.compatibleVersionRange = versionCompatibleRange;
        [availableVersions addObject:version];
    }

    return availableVersions;
}
