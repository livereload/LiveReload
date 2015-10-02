
#import "LRVersionSpec.h"
@import PiiVersionKit;


@interface LRVersionSpec ()

@property(nonatomic, readonly) NSString *versionString;

@property(nonatomic, readonly) NSUInteger major;
@property(nonatomic, readonly) NSUInteger minor;

@property(nonatomic, readonly) LRVersionSpace *versionSpace;
@property(nonatomic, readonly) LRVersion *version;

@end


@implementation LRVersionSpec

- (id)initWithType:(LRVersionSpecType)type versionString:(NSString *)versionString major:(NSUInteger)major minor:(NSUInteger)minor versionSpace:(LRVersionSpace *)versionSpace version:(LRVersion *)version {
    self = [super init];
    if (self) {
        _type = type;
        _versionString = [versionString copy];
        _major = major;
        _minor = minor;
        _versionSpace = versionSpace;
        _version = version;

        switch (_type) {
            case LRVersionSpecTypeUnknown:
                _matchingVersionSet = [LRVersionSet emptyVersionSet];
                _matchingVersionTags = LRVersionTagAll;
                break;
            case LRVersionSpecTypeSpecific:
                _matchingVersionSet = [LRVersionSet versionSetWithVersion:_version];
                _matchingVersionTags = LRVersionTagAll;
                break;
            case LRVersionSpecTypeMajorMinor:
                _matchingVersionSet = [LRVersionSet versionSetWithRange:[[LRVersionRange alloc] initWithStartingVersion:[_versionSpace versionWithMajor:_major minor:_minor] startIncluded:YES endingVersion:[_versionSpace versionWithMajor:_major minor:_minor+1] endIncluded:NO]];
                _matchingVersionTags = LRVersionTagAll;
                break;
            case LRVersionSpecTypeStableMajor:
                _matchingVersionSet = [LRVersionSet versionSetWithRange:[[LRVersionRange alloc] initWithStartingVersion:[_versionSpace versionWithMajor:_major minor:0] startIncluded:YES endingVersion:[_versionSpace versionWithMajor:_major+1 minor:0] endIncluded:NO]];
                _matchingVersionTags = LRVersionTagAllStable;
                break;
            case LRVersionSpecTypeStableAny:
                _matchingVersionSet = [LRVersionSet allVersionsSet];
                _matchingVersionTags = LRVersionTagAllStable;
                break;
            default:
                abort();
        }
    }
    return self;
}

+ (instancetype)versionSpecWithString:(NSString *)string inVersionSpace:(LRVersionSpace *)versionSpace {
    if ([string isEqualToString:@"*-stable"]) {
        return [[self alloc] initWithType:LRVersionSpecTypeStableAny versionString:string major:0 minor:0 versionSpace:versionSpace version:nil];
    } else if ([string hasSuffix:@".x"]) {
        NSScanner *scanner = [NSScanner scannerWithString:string];
        NSInteger major = 0, minor = 0;
        BOOL ok = YES;
        ok = ok && [scanner scanInteger:&major];
        ok = ok && [scanner scanString:@"." intoString:NULL];
        ok = ok && [scanner scanInteger:&minor];
        ok = ok && [scanner scanString:@".x" intoString:NULL];
        ok = ok && [scanner isAtEnd];
        if (ok) {
            return [[self alloc] initWithType:LRVersionSpecTypeMajorMinor versionString:string major:major minor:minor versionSpace:versionSpace version:nil];
        }
    } else if ([string hasSuffix:@".x-stable"]) {
        NSScanner *scanner = [NSScanner scannerWithString:string];
        NSInteger major = 0;
        BOOL ok = YES;
        ok = ok && [scanner scanInteger:&major];
        ok = ok && [scanner scanString:@".x-stable" intoString:NULL];
        ok = ok && [scanner isAtEnd];
        if (ok) {
            return [[self alloc] initWithType:LRVersionSpecTypeStableMajor versionString:string major:major minor:0 versionSpace:versionSpace version:nil];
        }
    } else {
        LRVersion *version = [versionSpace versionWithString:string];
        if (version) {
            return [[self alloc] initWithType:LRVersionSpecTypeSpecific versionString:string major:version.major minor:version.minor versionSpace:versionSpace version:version];
        }
    }
    return [[self alloc] initWithType:LRVersionSpecTypeUnknown versionString:string major:0 minor:0 versionSpace:versionSpace version:nil];
}

+ (instancetype)versionSpecMatchingVersion:(LRVersion *)version {
    return [[self alloc] initWithType:LRVersionSpecTypeSpecific versionString:version.description major:version.major minor:version.minor versionSpace:version.versionSpace version:version];
}

+ (instancetype)stableVersionSpecMatchingAnyVersionInVersionSpace:(LRVersionSpace *)versionSpace {
    return [[self alloc] initWithType:LRVersionSpecTypeStableAny versionString:@"*-stable" major:0 minor:0 versionSpace:versionSpace version:nil];
}

+ (instancetype)versionSpecMatchingMajorMinorFromVersion:(LRVersion *)version {
    return [[self alloc] initWithType:LRVersionSpecTypeMajorMinor versionString:[NSString stringWithFormat:@"%ld.%ld.x", (long)version.major, (long)version.minor] major:version.major minor:version.minor versionSpace:version.versionSpace version:nil];
}

+ (instancetype)stableVersionSpecWithMajorFromVersion:(LRVersion *)version {
    return [[self alloc] initWithType:LRVersionSpecTypeStableMajor versionString:[NSString stringWithFormat:@"%ld.x-stable", (long)version.major] major:version.major minor:0 versionSpace:version.versionSpace version:nil];
}

- (NSString *)stringValue {
    return _versionString;
}

- (NSString *)description {
    return _versionString;
}

- (BOOL)isValid {
    return _type != LRVersionSpecTypeUnknown;
}

- (BOOL)matchesVersion:(LRVersion *)version withTag:(LRVersionTag)tag {
    // "== tag" or "!= 0"? at this point, I'm not really sure if "tag" can ever be a bitmask
    return ((_matchingVersionTags & tag) == tag) && [_matchingVersionSet containsVersion:version];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    return ([object class] == [self class]) && [[object stringValue] isEqualToString:[self stringValue]];
}

- (NSUInteger)hash {
    return _versionString.hash;
}

- (NSString *)title {
    NSString *title = [self _title0];
    if (_changeLogSummary.length > 0)
        title = [NSString stringWithFormat:@"%@ (%@)", title, _changeLogSummary];
    return title;
}

- (NSString *)_title0 {
    switch (_type) {
        case LRVersionSpecTypeUnknown:
            return [NSString stringWithFormat:@"(unknown) %@", _versionString];
        case LRVersionSpecTypeSpecific:
            return [NSString stringWithFormat:@"%@", _version.description];
        case LRVersionSpecTypeMajorMinor:
            return [NSString stringWithFormat:@"%d.%d.x", (int)_major, (int)_minor];
        case LRVersionSpecTypeStableMajor:
            return [NSString stringWithFormat:@"%d.x stable", (int)_major];
        case LRVersionSpecTypeStableAny:
            return [NSString stringWithFormat:@"any stable"];
        default:
            abort();
    }
}

@end
