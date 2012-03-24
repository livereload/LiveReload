
#import <Foundation/Foundation.h>

// define APPSTORE for App Store builds

#define MASReceiptApplicationSupportReceiptsFolder @"LiveReload/Receipts"
#define MASReceiptFileExtension @"livereload-receipt"

void MASReceiptStartup();
BOOL MASReceiptIsAuthenticated();
