
#import "AppDelegate.h"

#include "nodeapp_ui.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [super applicationDidFinishLaunching:aNotification];

    NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
    [folderImage setSize:NSMakeSize(16,16)];
    nodeapp_ui_image_register("folder", folderImage);
}

@end
