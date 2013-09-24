
#import <Foundation/Foundation.h>


#define GlitterFeedURLKey @"GlitterFeedURL"
#define GlitterApplicationSupportSubfolderKey @"GlitterApplicationSupportSubfolder"
#define GlitterDefaultChannelNameKey @"GlitterDefaultChannelName"

#define GlitterChannelNameStable @"stable"
#define GlitterChannelNameBeta @"beta"


typedef enum {
    GlitterCheckOptionUserInitiated = 0x01,
} GlitterCheckOptions;


typedef enum {
    GlitterErrorCodeNone = 0,

    GlitterErrorCodeCheckFailedConnection,
    GlitterErrorCodeCheckFailedInvalidFeedFormat,
} GlitterErrorCode;
