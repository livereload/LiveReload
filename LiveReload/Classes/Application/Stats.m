
#import "Stats.h"
#include "jansson.h"

#include <stdlib.h>
#include <time.h>
#include <assert.h>


#define AppNewsKitDebugKey               @"AppNewsKitDebug"
#define AppNewsKitLastPingTimeKey        @"AppNewsKitLastPingTime"
#define AppNewsKitLastDeliveryTimeKey    @"AppNewsKitLastDeliveryTime"
#define AppNewsKitQueuedMessageKey       @"AppNewsKitQueuedMessage"
#define AppNewsKitClickedMessageIdsKey   @"AppNewsKitClickedMessageIds"
#define AppNewsKitDeliveredMessageIdsKey @"AppNewsKitDeliveredMessageIds"
#define AppNewsKitIgnoredMessageIdsKey   @"AppNewsKitIgnoredMessageIds"
#define AppNewsKitFailedRecentlyKey      @"AppNewsKitFailedRecently"
#define AppNewsKitRemindLaterClickTimeKeyFmt @"AppNewsKitRemindLaterClickTime.%@"

#define AppNewsKitPingInterval           (24*60*60)
#define AppNewsKitCheckInterval          (30*60)
#define AppNewsKitDebugPingInterval      (60)
#define AppNewsKitDebugCheckInterval     (10)


static BOOL                      AppNewsKitDebug;
static BOOL                      AppNewsKitMessageDeliveryQueued;
static NSString                 *AppNewsKitPingURL;
static AppNewsKitParamBlock_t    AppNewsKitParamBlock;
static dispatch_source_t         AppNewsKitTimerSource;


static void AppNewsKitQueueMessageDelivery();


#pragma mark - Version matching utilities

static BOOL appnewskit_match_version_rule(const char *rule, const char *ver) {
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

    BOOL ver_more, rule_more;
    do {
        long ver_component  = strtol(ver,  (char **) &ver, 10);
        long rule_component = strtol(rule, (char **) &rule, 10);

        if (ver_component > rule_component)
            return greater;
        if (ver_component < rule_component)
            return less;

        ver_more  = (*ver  == '.' && ++ver  && 1);
        rule_more = (*rule == '.' && ++rule && 1);
    } while (ver_more && rule_more);

    if (ver_more)
        return greater;
    if (rule_more)
        return less;
    return equal;
}

static BOOL appnewskit_match_version_rule_set(const char *rule_set, const char *ver) {
    while (*rule_set) {
        while (*rule_set && *rule_set == ' ') ++rule_set;   // skip whitespace
        if (!appnewskit_match_version_rule(rule_set, ver))
            return NO;
        while (*rule_set && *rule_set != ' ') ++rule_set;   // skip to the next whitespace
    }
    return YES;
}

static void appnewskit_match_version_self_test() {
    assert(appnewskit_match_version_rule("2.1", "2.1"));
    assert(!appnewskit_match_version_rule("2.1", "2.2"));
    assert(appnewskit_match_version_rule("=2.1", "2.1"));
    assert(!appnewskit_match_version_rule("=2.1", "2.2"));
    assert(!appnewskit_match_version_rule("=2.1", "2.1.0"));
    assert(!appnewskit_match_version_rule("=2.1.0", "2.1"));

    assert(appnewskit_match_version_rule(">2.1", "2.2"));
    assert(appnewskit_match_version_rule(">2.1", "2.1.1"));
    assert(appnewskit_match_version_rule(">2.1.4", "2.1.5"));
    assert(!appnewskit_match_version_rule(">2.1", "2.1"));
    assert(!appnewskit_match_version_rule(">2.1", "1.2"));
    assert(!appnewskit_match_version_rule(">2.3", "2.1"));
    assert(!appnewskit_match_version_rule(">2.1.4", "2.1.3"));

    assert(appnewskit_match_version_rule(">=2.3", "2.3"));
    assert(appnewskit_match_version_rule(">=2.3", "2.4"));
    assert(appnewskit_match_version_rule(">=2.3", "2.3.0"));
    assert(appnewskit_match_version_rule(">=2.3", "2.3.1"));
    assert(appnewskit_match_version_rule(">=2.3", "5.0"));
    assert(!appnewskit_match_version_rule(">=2.3", "2.2"));
    assert(!appnewskit_match_version_rule(">=2.3", "2.2.9"));
    assert(!appnewskit_match_version_rule(">=2.3", "1.9.9"));

    assert(appnewskit_match_version_rule("<3.0", "2.0"));
    assert(appnewskit_match_version_rule("<3.0", "2.9"));
    assert(appnewskit_match_version_rule("<3.0", "2.9.0"));
    assert(appnewskit_match_version_rule("<3.2", "3.1"));
    assert(appnewskit_match_version_rule("<3.2", "3.1.8"));
    assert(!appnewskit_match_version_rule("<3.2", "3.2"));
    assert(!appnewskit_match_version_rule("<3.2", "3.2.0"));

    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "1.9"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "2.0"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "2.2"));
    assert(appnewskit_match_version_rule_set(">=2.3 <2.8", "2.3"));
    assert(appnewskit_match_version_rule_set(">=2.3 <2.8", "2.3.0"));
    assert(appnewskit_match_version_rule_set(">=2.3 <2.8", "2.3.5"));
    assert(appnewskit_match_version_rule_set(">=2.3 <2.8", "2.6"));
    assert(appnewskit_match_version_rule_set(">=2.3 <2.8", "2.6.9"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "2.8"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "2.8.0"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "2.9"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "3.0"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "3.0.0"));
    assert(!appnewskit_match_version_rule_set(">=2.3 <2.8", "3.0.5"));
    assert(appnewskit_match_version_rule_set(">=2.0 <3.0", "2.0.0.35"));
}


#pragma mark - Statistics

NSString *StatItemKey(NSString *name, NSString *item) {
    return [name stringByAppendingFormat:@".%@", item];
}

void StatIncrement(NSString *name, NSInteger delta) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[defaults integerForKey:name] + delta forKey:name];
    [defaults synchronize];
    AppNewsKitQueueMessageDelivery();
}

void StatGroupIncrement(NSString *name, NSString *item, NSInteger delta) {
    StatIncrement(name, delta);
    StatIncrement(StatItemKey(name, item), delta);
}

NSArray *StatGroupItems(NSString *name) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    NSString *prefix = StatItemKey(name, @"");

    NSMutableArray *result = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([[key substringToIndex:[prefix length]] isEqualToString:prefix]) {
            [result addObject:[key substringFromIndex:[prefix length]]];
        }
    }];
    return [NSArray arrayWithArray:result];
}

NSInteger StatGet(NSString *name) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:name];
}

NSInteger StatGetItem(NSString *name, NSString *item) {
    return StatGet(StatItemKey(name, item));
}

void StatAllToParams(NSMutableDictionary *params) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    NSString *prefix = @"stat.";

    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([[key substringToIndex:[prefix length]] isEqualToString:prefix]) {
            StatToParams(key, params);
        }
    }];
}

void StatToParams(NSString *name, NSMutableDictionary *params) {
    NSInteger value = StatGet(name);
    [params setObject:[NSString stringWithFormat:@"%ld", value] forKey:name];
}

void StatGroupToParams(NSString *name, NSMutableDictionary *params) {
    StatToParams(name, params);
    for (NSString *item in StatGroupItems(name)) {
        StatToParams(StatItemKey(name, item), params);
    }
}


#pragma mark - Internal messaging utilities

static BOOL AppNewsKitAppVersionMatchesSpec(const char *rule_set) {
    NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return appnewskit_match_version_rule_set(rule_set, [internalVersion UTF8String]);
}

static BOOL AppNewsKitMessageBelongsToSet(NSString *messageId, NSString *key) {
    return [[[[NSUserDefaults standardUserDefaults] objectForKey:key] componentsSeparatedByString:@","] containsObject:messageId];
}

static void AppNewsKitAddMessageToSet(NSString *messageId, NSString *key) {
    NSArray *items = [[[NSUserDefaults standardUserDefaults] objectForKey:key] componentsSeparatedByString:@","];
    if (!items)
        items = [NSArray array];
    if ([items containsObject:messageId])
        return;
    items = [items arrayByAddingObject:messageId];
    [[NSUserDefaults standardUserDefaults] setObject:[items componentsJoinedByString:@","] forKey:key];
}

static BOOL AppNewsKitMessageSatisfiesQueueingConditions(json_t *message_json, const char **error_key) {
    json_t *item;

    item = json_object_get(message_json, "id");
    if (!json_is_string(item))
        return (*error_key = "id"), NO;
    NSString *messageId = [NSString stringWithUTF8String:json_string_value(item)];

    if (AppNewsKitMessageBelongsToSet(messageId, AppNewsKitIgnoredMessageIdsKey)) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit: Message %@ is not considered because it is ignored.", messageId);
        return NO;
    }
    if (AppNewsKitMessageBelongsToSet(messageId, AppNewsKitClickedMessageIdsKey)) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit: Message %@ is not considered because it has been clicked.", messageId);
        return NO;
    }

    if (!!(item = json_object_get(message_json, "version"))) {
        if (!json_is_array(item))
            return (*error_key = "version"), NO;

        BOOL found = NO;
        size_t count = json_array_size(item);
        for (int i = 0; i < count; ++i) {
            const char *rule = json_string_value(json_array_get(item, i));
            if (AppNewsKitAppVersionMatchesSpec(rule)) {
                found = YES;
                if (AppNewsKitDebug)
                    NSLog(@"AppNewsKit: Message %@ matched version condition '%s'.", messageId, rule);
                break;
            }
        }

        if (!found) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: Message %@ is not considered because it does not match any of the version conditions.", messageId);
            return NO;
        }
    }

    if (!!(item = json_object_get(message_json, "status"))) {
        if (!json_is_array(item))
            return (*error_key = "status"), NO;

        const char *status = "unregistered";
        BOOL found = NO;

        size_t count = json_array_size(item);
        for (int i = 0; i < count; ++i) {
            const char *rule = json_string_value(json_array_get(item, i));
            if (0 == strcmp(status, rule)) {
                found = YES;
                break;
            }
        }

        if (!found) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: Message %@ is not considered because its status '%s' does not match any of the status conditions.", messageId, status);
            return NO;
        }
    }

    if (!!(item = json_object_get(message_json, "stats"))) {
        if (!json_is_object(item))
            return (*error_key = "stats"), NO;

        for (void *iter = json_object_iter(item); iter; iter = json_object_iter_next(item, iter)) {
            const char *key = json_object_iter_key(iter);
            json_int_t value = (json_int_t) StatGet([NSString stringWithUTF8String:key]);

            json_t *rule = json_object_iter_value(iter);
            if (!json_is_object(rule))
                return (*error_key = "stats"), NO;

            json_t *min_rule = json_object_get(rule, "min");
            if (min_rule) {
                if (!json_is_integer(min_rule))
                    return (*error_key = "stats"), NO;
                json_int_t min_val = json_integer_value(min_rule);
                if (value < min_val) {
                    if (AppNewsKitDebug)
                        NSLog(@"AppNewsKit: Message %@ is not considered because the current value %d of stat %s is less than %d.", messageId, (int)value, key, (int)min_val);
                    return NO;
                }
            }

            json_t *max_rule = json_object_get(rule, "max");
            if (max_rule) {
                if (!json_is_integer(max_rule))
                    return (*error_key = "stats"), NO;
                json_int_t max_val = json_integer_value(max_rule);
                if (value > max_val) {
                    if (AppNewsKitDebug)
                        NSLog(@"AppNewsKit: Message %@ is not considered because the current value %d of stat %s is greater than %d.", messageId, (int)value, key, (int)max_val);
                    return NO;
                }
            }
        }
    }

    return YES;
}

static BOOL AppNewsKitMessageSatisfiesDeliveryConditions(json_t *message_json) {
    NSString *messageId = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "id"))];

    const char *dummy_error_key = NULL;
    if (!AppNewsKitMessageSatisfiesQueueingConditions(message_json, &dummy_error_key))
        return NO;

    const char *deliver_after_fmt = json_string_value(json_object_get(message_json, "deliver_after"));
    if (deliver_after_fmt) {
        int year, month, day, hour = 0, minute = 0, second = 0;
        int result = sscanf(deliver_after_fmt, "%d-%d-%d %d:%d", &year, &month, &day, &hour, &minute);
        if (result < 3) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: Invalid date format for deliver_after of %@.", messageId);
            return NO;
        }

        struct tm tm;
        memset(&tm, 0, sizeof(tm));
        tm.tm_year = year - 1900; tm.tm_mon = month - 1; tm.tm_mday = day;
        tm.tm_hour = hour; tm.tm_min = minute; tm.tm_sec = second;
        tm.tm_isdst = -1;
        time_t deliver_after = timegm(&tm);
        if (deliver_after > time(NULL)) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: Not delivering yet because deliver_after date hasn't been reached: %@.", messageId);
            return NO;
        }
    }

    NSInteger postponed_at = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:AppNewsKitRemindLaterClickTimeKeyFmt, messageId]];
    if (postponed_at > 0) {
        json_t *json = json_object_get(message_json, "remind_later_in_days");
        int days = (json_is_integer(json) ? json_integer_value(json) : 5);
        if (time(NULL) < postponed_at + 24 * 60 * 60 * days) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: Not delivering yet because remind_later_in_days haven't passed yet: %@.", messageId);
            return NO;
        }
    }

    NSInteger last_at = [[NSUserDefaults standardUserDefaults] integerForKey:AppNewsKitLastDeliveryTimeKey];
    if (last_at > 0) {
        json_t *json = json_object_get(message_json, "delay_if_nagged_within_days");
        int days = (json_is_integer(json) ? json_integer_value(json) : 5);
        if (days > 0) {
            if (time(NULL) < last_at + 24 * 60 * 60 * days) {
                if (AppNewsKitDebug)
                    NSLog(@"AppNewsKit: Not delivering yet because delay_if_nagged_within_days haven't passed yet: %@.", messageId);
                return NO;
            }
        }
    }

    return YES;
}

static void AppNewsKitDeliverMessage(json_t *message_json) {
    NSString *messageId = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "id"))];

    if (!AppNewsKitMessageSatisfiesDeliveryConditions(message_json))
        return;

    if (AppNewsKitDebug)
        NSLog(@"AppNewsKit: Delivering %@.", messageId);

    NSString *title = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "title"))];
    NSString *message = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "message"))];
    NSString *defaultButtonTitle = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "primary_button_title"))];
    NSString *defaultButtonUrl = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "primary_button_url"))];

    NSInteger reply = [[NSAlert alertWithMessageText:title defaultButton:defaultButtonTitle alternateButton:@"Remind Later" otherButton:@"Ignore" informativeTextWithFormat:@"%@", message] runModal];

    AppNewsKitAddMessageToSet(messageId, AppNewsKitDeliveredMessageIdsKey);
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)time(NULL) forKey:AppNewsKitLastDeliveryTimeKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:AppNewsKitRemindLaterClickTimeKeyFmt, messageId]];

    if (reply == NSAlertDefaultReturn) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit: Response to %@ is 'clicked'.", messageId);
        AppNewsKitAddMessageToSet(messageId, AppNewsKitClickedMessageIdsKey);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:defaultButtonUrl]];
    } else if (reply == NSAlertAlternateReturn) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit: Response to %@ is 'remind later'.", messageId);
        [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)time(NULL) forKey:[NSString stringWithFormat:AppNewsKitRemindLaterClickTimeKeyFmt, messageId]];
    } else if (reply == NSAlertOtherReturn) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit: Response to %@ is 'ignore'.", messageId);
        AppNewsKitAddMessageToSet(messageId, AppNewsKitIgnoredMessageIdsKey);
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static void AppNewsKitDeliverNextMessage() {
    NSString *nextMessage = [[NSUserDefaults standardUserDefaults] objectForKey:AppNewsKitQueuedMessageKey];
    if (nextMessage) {
        json_t *message_json = json_loads([nextMessage UTF8String], 0, NULL);
        if (message_json) {
            AppNewsKitDeliverMessage(message_json);
        }
    }
}

static void AppNewsKitQueueMessageDelivery() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (AppNewsKitMessageDeliveryQueued)
            return;
        AppNewsKitMessageDeliveryQueued = YES;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2ull * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            AppNewsKitMessageDeliveryQueued = NO;
            AppNewsKitDeliverNextMessage();
        });
    });
}

static BOOL AppNewsKitPickMessageToDeliver(const char *raw_response, char **next_message_string) {
    json_error_t error;
    json_t *manifest_json = json_loads(raw_response, 0, &error);
    if (!manifest_json) {
        NSLog(@"AppNewsKit: Failed to parse incoming manifest file: %s (line %d).", error.text, error.line);
        return NO;
    }

    json_t *next_message_json = NULL;
    json_t *messages_json = json_object_get(manifest_json, "messages");
    size_t count = json_array_size(messages_json);
    if (AppNewsKitDebug)
        NSLog(@"AppNewsKit: Choosing matching message among %d candidates.", (int)count);
    for (int i = 0; i < count; ++i) {
        json_t *message_json = json_array_get(messages_json, i);

        const char *error_key = NULL;
        BOOL matched = AppNewsKitMessageSatisfiesQueueingConditions(message_json, &error_key);

        if (error_key) {
            NSLog(@"AppNewsKit: Failed to parse incoming manifest file: error in key %s of message %d.", error_key, i);
            json_decref(manifest_json);
            return NO;
        }

        if (matched) {
            if (AppNewsKitDebug) {
                NSString *messageId = [NSString stringWithUTF8String:json_string_value(json_object_get(message_json, "id"))];
                NSLog(@"AppNewsKit: All conditions of message %@ have been satisfied, the message will be queued for delivery.", messageId);
            }
            next_message_json = message_json;
            break;
        }
    }

    if (next_message_json) {
        *next_message_string = json_dumps(next_message_json, 0);
    } else {
        if (AppNewsKitDebug && count > 0)
            NSLog(@"AppNewsKit: No messages have their conditions satisfied.");
        *next_message_string = NULL;
    }

    json_decref(manifest_json);
    return YES;
}

static void AppNewsKitDoPingServer(BOOL scheduled) {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:version forKey:@"v"];
    [params setObject:internalVersion forKey:@"iv"];
    [params setObject:(scheduled ? @"1" : @"0") forKey:@"scheduled"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:AppNewsKitFailedRecentlyKey])
        [params setObject:"1" forKey:"appnewskit.failed"];
    if ([defaults objectForKey:AppNewsKitDeliveredMessageIdsKey])
        [params setObject:[defaults objectForKey:AppNewsKitDeliveredMessageIdsKey] forKey:@"appnewskit.delivered"];
    if ([defaults objectForKey:AppNewsKitClickedMessageIdsKey])
        [params setObject:[defaults objectForKey:AppNewsKitDeliveredMessageIdsKey] forKey:@"appnewskit.delivered"];

    StatAllToParams(params);

    if (AppNewsKitParamBlock)
        AppNewsKitParamBlock(params);

    if (AppNewsKitDebug)
        NSLog(@"AppNewsKit: Sending ping with parameters:");
    NSMutableString *qs = [NSMutableString string];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (AppNewsKitDebug)
            NSLog(@"AppNewsKit:   %@=%@", key, obj);
        if ([qs length] > 0)
            [qs appendString:@"&"];
        [qs appendFormat:@"%@=%@", key, [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *response = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", AppNewsKitPingURL, qs]] encoding:NSUTF8StringEncoding error:NULL];
        if (!response) {
            if (AppNewsKitDebug)
                NSLog(@"AppNewsKit: No response to ping, probably offline.");
            return;
        }

        char *next_message_string = NULL;
        BOOL success = AppNewsKitPickMessageToDeliver([response UTF8String], &next_message_string);

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)time(NULL) forKey:AppNewsKitLastPingTimeKey];

            [[NSUserDefaults standardUserDefaults] setBool:!success forKey:AppNewsKitFailedRecentlyKey];
            if (success) {
                if (next_message_string) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:next_message_string] forKey:AppNewsKitQueuedMessageKey];
                    free(next_message_string);
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:AppNewsKitQueuedMessageKey];
                }
            }

            [[NSUserDefaults standardUserDefaults] synchronize];

            AppNewsKitDeliverNextMessage();
        });
    });
}

static void AppNewsKitPingServer(BOOL force) {
    time_t lastPingTime = (time_t) [[NSUserDefaults standardUserDefaults] integerForKey:AppNewsKitLastPingTimeKey];
    BOOL schedule = (lastPingTime == 0 || time(NULL) - lastPingTime > AppNewsKitPingInterval);
    if (AppNewsKitDebug && (lastPingTime != 0) && (time(NULL) - lastPingTime > AppNewsKitDebugPingInterval)) {
        force = YES;  // can't simply modify pingInterval to avoid skewing server statistics
    }
    if (schedule || force) {
        AppNewsKitDoPingServer(schedule);
    }
}

void AppNewsKitStartup(NSString *pingURL, AppNewsKitParamBlock_t pingParamBlock) {
    appnewskit_match_version_self_test();

    AppNewsKitPingURL    = [pingURL copy];
    AppNewsKitParamBlock = [pingParamBlock copy];
    AppNewsKitDebug      = [[NSUserDefaults standardUserDefaults] boolForKey:AppNewsKitDebugKey];

    AppNewsKitPingServer(YES);

    AppNewsKitTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    int64_t interval = (AppNewsKitDebug ? AppNewsKitDebugCheckInterval : AppNewsKitCheckInterval) * 1ull * NSEC_PER_SEC;
    dispatch_source_set_timer(AppNewsKitTimerSource, dispatch_time(DISPATCH_TIME_NOW, interval), interval, interval / 10);
    dispatch_source_set_event_handler(AppNewsKitTimerSource, ^{
        AppNewsKitPingServer(NO);
        AppNewsKitDeliverNextMessage();
    });
    dispatch_resume(AppNewsKitTimerSource);
}
