
#import "VersionChecks.h"

#import <CoreServices/CoreServices.h>

BOOL IsOSX107LionOrLater() {
    SInt32 major = 0;
    SInt32 minor = 0;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    return ((major == 10 && minor >= 7) || major >= 11);
}
