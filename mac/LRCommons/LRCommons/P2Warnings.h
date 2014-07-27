
#import <Foundation/Foundation.h>


#define P2PushWarnings() _Pragma("clang diagnostic push")
#define P2PopWarnings() _Pragma("clang diagnostic pop")

// see http://stackoverflow.com/questions/8724644/how-do-i-implement-a-macro-that-creates-a-quoted-string-for-pragma
#define __P2SetWarningIgnored0(x) #x
#define __P2SetWarningIgnored1(x) __P2SetWarningIgnored0(clang diagnostic ignored x)
#define __P2SetWarningIgnored2(y) __P2SetWarningIgnored1(#y)
#define _P2SetWarningIgnored(warning) _Pragma(__P2SetWarningIgnored2(warning))

#define P2DisableWarning(warning) P2PushWarnings() _P2SetWarningIgnored(warning)
#define P2ReenableWarning() P2PopWarnings()

#define P2DisableARCRetainCyclesWarning() P2DisableWarning(-Warc-retain-cycles)
#define P2DisablePerformSelectorLeaksWarning() P2DisableWarning(-Warc-performSelector-leaks)
