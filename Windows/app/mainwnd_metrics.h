#ifndef LiveReload_mainwnd_metrics_h
#define LiveReload_mainwnd_metrics_h

//#define kOuterShadowLeft   57
//#define kOuterShadowTop    35
//#define kOuterShadowRight  57
//#define kOuterShadowBottom 78
#define kOuterShadowLeft   0
#define kOuterShadowTop    0
#define kOuterShadowRight  0
#define kOuterShadowBottom 0

#define kTitleBarHeight  22
#define kBottomBarHeight 22
#define kWindowWidth     738
#define kWindowHeight    514
#define kClientAreaX kOuterShadowLeft
#define kClientAreaY (kOuterShadowTop + kTitleBarHeight)
#define kClientAreaWidth  kWindowWidth
#define kClientAreaHeight (kWindowHeight - kTitleBarHeight)

#define kProjectListX kClientAreaX
#define kProjectListY kClientAreaY
#define kProjectListW 202
#define kProjectListH (kClientAreaHeight - kBottomBarHeight)
#define kProjectListItemHeight 20

#define kProjectPaneX (kProjectListX + kProjectListW)
#define kProjectPaneY kClientAreaY
#define kProjectPaneW (kClientAreaWidth - kProjectListW)
#define kProjectPaneH kProjectListH

#endif
