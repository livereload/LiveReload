
#import <Cocoa/Cocoa.h>
#include <xpc/xpc.h>
#include <sys/xattr.h>

static xpc_object_t reloadRequest = NULL;

#define GlitterQuarantineAttributeName "com.apple.quarantine"

// borrowed from Sparkle
int GlitterRemoveXAttr(const char *name, NSString *file, int options) {
	const char *path = NULL;
	@try {
		path = [file fileSystemRepresentation];
	}
	@catch (id exception) {
		// -[NSString fileSystemRepresentation] throws an exception if it's
		// unable to convert the string to something suitable.  Map that to
		// EDOM, "argument out of domain", which sort of conveys that there
		// was a conversion failure.
		errno = EDOM;
		return -1;
	}

	return removexattr(path, name, options);
}

// borrowed from Sparkle
void GlitterReleaseFromQuarantine(NSString *root) {
	GlitterRemoveXAttr(GlitterQuarantineAttributeName, root, XATTR_NOFOLLOW);

	NSDictionary* rootAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:root error:nil];
	NSString* rootType = [rootAttributes objectForKey:NSFileType];

	if (rootType == NSFileTypeDirectory) {
		// The NSDirectoryEnumerator will avoid recursing into any contained
		// symbolic links, so no further type checks are needed.
		NSDirectoryEnumerator* directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:root];
		NSString* file = nil;
		while ((file = [directoryEnumerator nextObject])) {
            GlitterRemoveXAttr(GlitterQuarantineAttributeName, [root stringByAppendingPathComponent:file], XATTR_NOFOLLOW);
		}
	}
}


static void GlitterInstallationService_peer_event_handler(xpc_connection_t peer, xpc_object_t event) {
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID || event == XPC_ERROR_TERMINATION_IMMINENT) {
            if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSLog(@"GlitterInstallationService: XPC_ERROR_CONNECTION_INVALID");
            } else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
                NSLog(@"GlitterInstallationService: XPC_ERROR_TERMINATION_IMMINENT");
            }
            if (reloadRequest) {
            }
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
        NSString *bundlePath = [NSString stringWithUTF8String:xpc_dictionary_get_string(event, "bundlePath")];
        NSString *updatePath = [NSString stringWithUTF8String:xpc_dictionary_get_string(event, "updatePath")];
        NSURL *bundleURL = [NSURL fileURLWithPath:bundlePath];
        NSURL *updateURL = [NSURL fileURLWithPath:updatePath];

        NSLog(@"GlitterInstallationService: bundlePath = %@, updatePath = %@", bundlePath, updatePath);

//        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
//        pid_t pid = xpc_connection_get_pid(remote);

        xpc_transaction_begin();

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            NSLog(@"GlitterInstallationService: installing %@", updatePath);

            NSLog(@"GlitterInstallationService: releasing from quarantine...");
            GlitterReleaseFromQuarantine(updatePath);

            NSLog(@"GlitterInstallationService: moving old bundle (%@) to trash", bundlePath);
            [[NSWorkspace sharedWorkspace] recycleURLs:@[bundleURL] completionHandler:^(NSDictionary *newURLs, NSError *recyceError) {
                if (recyceError) {
                    NSLog(@"GlitterInstallationService: error moving to trash: %@", recyceError.localizedDescription);
                }

                NSError * __autoreleasing error;
                BOOL ok = [[NSFileManager defaultManager] removeItemAtURL:bundleURL error:&error];
                if (!ok) {
                    NSLog(@"GlitterInstallationService: error deleting old bundle: %@", error.localizedDescription);
                }

                ok = [[NSFileManager defaultManager] moveItemAtURL:updateURL toURL:bundleURL error:&error];
                if (!ok) {
                    NSLog(@"GlitterInstallationService: error deleting old bundle: %@", error.localizedDescription);
                    goto finish;
                }

                NSLog(@"GlitterInstallationService: launching %@", bundlePath);
                [[NSWorkspace sharedWorkspace] openFile:bundlePath];

            finish:
                NSLog(@"GlitterInstallationService: done");
                xpc_transaction_end();
            }];
        });
	}
}

static void GlitterInstallationService_event_handler(xpc_connection_t peer)  {
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		GlitterInstallationService_peer_event_handler(peer, event);
	});
	
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[]) {
	xpc_main(GlitterInstallationService_event_handler);
	return 0;
}
