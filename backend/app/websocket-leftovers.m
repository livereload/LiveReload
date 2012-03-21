
- (void)displayProtocol6UpgradePrompt {
    static BOOL warningDisplayed = NO;
    if (!warningDisplayed) {
        warningDisplayed = YES;

        NSInteger reply = [[NSAlert alertWithMessageText:@"Update browser extensions" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"Update your browser extensions to version 2.0 to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more."] runModal];
        if (reply == NSAlertDefaultReturn) {
            [[ExtensionsController sharedExtensionsController] installExtension:self];
        }
    }
}

- (void)displayUpgradePromptForBrowser:(NSString *)browser extVersion:(NSString *)version {
    static NSMutableDictionary *promptsDisplayed = nil;

    if ([promptsDisplayed objectForKey:browser])
        return;

    NSDictionary *latestVersions = [NSDictionary dictionaryWithObjectsAndKeys:@"2.0.2", @"safari", @"2.0.2", @"chrome", @"2.0.2", @"firefox", nil];
    NSString *latestVersion = [latestVersions objectForKey:[browser lowercaseString]];
    if (VersionNumberFromNSString(version) < VersionNumberFromNSString(latestVersion)) {
        if (promptsDisplayed == nil)
            promptsDisplayed = [[NSMutableDictionary alloc] init];
        [promptsDisplayed setObject:latestVersion forKey:browser];

        NSInteger reply = [[NSAlert alertWithMessageText:@"Update browser extension" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"The latest version of %@ extension is %@, you currently have version %@. Please consider installing the new version.", browser, latestVersion, version] runModal];
        if (reply == NSAlertDefaultReturn) {
            ExtensionsController *ec = [ExtensionsController sharedExtensionsController];
            if ([browser isEqualToString:@"Safari"])
                [ec installSafariExtension:self];
            else if ([browser isEqualToString:@"Chrome"])
                [ec installChromeExtension:self];
            else if ([browser isEqualToString:@"Firefox"])
                [ec installFirefoxExtension:self];
            else
                [ec installExtension:self];
        }
    }
}

- (void)webSocketServerDidFailToInitialize:(WebSocketServer *)server {
    NSInteger result = [[NSAlert alertWithMessageText:@"Failed to start: port occupied" defaultButton:@"Quit" alternateButton:nil otherButton:@"More Info" informativeTextWithFormat:@"LiveReload cannot listen on port %d. You probably have another copy of LiveReload 2.x, a command-line LiveReload 1.x or an alternative tool like guard-livereload running.\n\nPlease quit any other live reloaders and rerun LiveReload.", (int)_portNumber] runModal];
    if (result == NSAlertOtherReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/kb/troubleshooting/failed-to-start-port-occupied"]];
    }
    [NSApp terminate:nil];
}

if (_connections.count > 0) {
   AppNewsKitGoodTimeToDeliverMessages();
}
