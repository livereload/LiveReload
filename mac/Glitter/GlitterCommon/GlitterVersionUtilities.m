
#import "GlitterVersionUtilities.h"

#include <assert.h>
#include <stdlib.h>


static NSComparisonResult glitter_compare_versions(const char *lhs, const char *rhs) {
    BOOL lhs_more, rhs_more;
    do {
        long lhs_component  = strtol(lhs,  (char **) &lhs, 10);
        long rhs_component = strtol(rhs, (char **) &rhs, 10);

        if (lhs_component > rhs_component)
            return NSOrderedDescending;
        if (lhs_component < rhs_component)
            return NSOrderedAscending;

        lhs_more  = (*lhs  == '.' && ++lhs  && 1);
        rhs_more = (*rhs == '.' && ++rhs && 1);
    } while (lhs_more && rhs_more);

    if (lhs_more)
        return NSOrderedDescending;
    if (rhs_more)
        return NSOrderedAscending;
    return NSOrderedSame;
}

NSComparisonResult GlitterCompareVersions(NSString *lhs, NSString *rhs) {
    return glitter_compare_versions([lhs UTF8String], [rhs UTF8String]);
}

static BOOL glitter_match_version_rule(const char *rule, const char *ver) {
    BOOL less = NO, equal = NO, greater = NO;
    if (*rule == '>') {
        greater = YES;
        ++rule;
    } else if (*rule == '<') {
        less = YES;
        ++rule;
    }
    if (*rule == '=') {
        equal = YES;
        ++rule;
    }
    if (!(less || equal || greater))
        equal = YES; // default

    NSComparisonResult cmp = glitter_compare_versions(ver, rule);
    switch (cmp) {
        case NSOrderedSame: return equal;
        case NSOrderedDescending: return greater;
        case NSOrderedAscending: return less;
        default: abort();
    }
}

static BOOL glitter_match_version_rule_set(const char *rule_set, const char *ver) {
    while (*rule_set) {
        while (*rule_set && *rule_set == ' ') ++rule_set;   // skip whitespace
        if (!glitter_match_version_rule(rule_set, ver))
            return NO;
        while (*rule_set && *rule_set != ' ') ++rule_set;   // skip to the next whitespace
    }
    return YES;
}

BOOL GlitterMatchVersionRange(NSString *range, NSString *ver) {
    return glitter_match_version_rule_set([range UTF8String], [ver UTF8String]);
}

void GlitterVersionComparisonSelfTest() {
    assert(glitter_match_version_rule("2.1", "2.1"));
    assert(!glitter_match_version_rule("2.1", "2.2"));
    assert(glitter_match_version_rule("=2.1", "2.1"));
    assert(!glitter_match_version_rule("=2.1", "2.2"));
    assert(!glitter_match_version_rule("=2.1", "2.1.0"));
    assert(!glitter_match_version_rule("=2.1.0", "2.1"));

    assert(glitter_match_version_rule(">2.1", "2.2"));
    assert(glitter_match_version_rule(">2.1", "2.1.1"));
    assert(glitter_match_version_rule(">2.1.4", "2.1.5"));
    assert(!glitter_match_version_rule(">2.1", "2.1"));
    assert(!glitter_match_version_rule(">2.1", "1.2"));
    assert(!glitter_match_version_rule(">2.3", "2.1"));
    assert(!glitter_match_version_rule(">2.1.4", "2.1.3"));

    assert(glitter_match_version_rule(">=2.3", "2.3"));
    assert(glitter_match_version_rule(">=2.3", "2.4"));
    assert(glitter_match_version_rule(">=2.3", "2.3.0"));
    assert(glitter_match_version_rule(">=2.3", "2.3.1"));
    assert(glitter_match_version_rule(">=2.3", "5.0"));
    assert(!glitter_match_version_rule(">=2.3", "2.2"));
    assert(!glitter_match_version_rule(">=2.3", "2.2.9"));
    assert(!glitter_match_version_rule(">=2.3", "1.9.9"));

    assert(glitter_match_version_rule("<3.0", "2.0"));
    assert(glitter_match_version_rule("<3.0", "2.9"));
    assert(glitter_match_version_rule("<3.0", "2.9.0"));
    assert(glitter_match_version_rule("<3.2", "3.1"));
    assert(glitter_match_version_rule("<3.2", "3.1.8"));
    assert(!glitter_match_version_rule("<3.2", "3.2"));
    assert(!glitter_match_version_rule("<3.2", "3.2.0"));

    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "1.9"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "2.0"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "2.2"));
    assert(glitter_match_version_rule_set(">=2.3 <2.8", "2.3"));
    assert(glitter_match_version_rule_set(">=2.3 <2.8", "2.3.0"));
    assert(glitter_match_version_rule_set(">=2.3 <2.8", "2.3.5"));
    assert(glitter_match_version_rule_set(">=2.3 <2.8", "2.6"));
    assert(glitter_match_version_rule_set(">=2.3 <2.8", "2.6.9"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "2.8"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "2.8.0"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "2.9"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "3.0"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "3.0.0"));
    assert(!glitter_match_version_rule_set(">=2.3 <2.8", "3.0.5"));
    assert(glitter_match_version_rule_set(">=2.0 <3.0", "2.0.0.35"));
}
