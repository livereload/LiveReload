# Glitter: a modern, GitHub-style automatic updater for Mac

Work in progress, although test app updates already work.

Features:

* sandbox-friendly (contains a non-sandboxed XPC service that installs the updates)
* automatic background downloading of updates
* no built-in UI, but very easy to integrate your own one (see GlitterDemoAppDelegate for an example)
* XML-free feed format (uses JSON; see example-feed.json)
* automatically checks for updates on launch plus every 24 hours (retries every hour if the last check has failed)
* automatic installation of pending updates on next launch
* automatic cleanup of downloaded updates

Upcoming features:

* UI for “What's New” screen
* verification of the new versions's code signature against the previous version's designated requirements
* reporting for failed checks, downloads and installations
* automatic update installation when the app is not in use
* verification of the size and SHA1 sum of the downloaded update

Future ideas:

* roll back failed updates automatically (e.g. if the new version quits within the first ~10 seconds after the first launch, roll back the update)


## How it should work

1. Glitter downloads a JSON feed at the given URL.

2. Glitter picks the _first_ release mentioned in the JSON feed that is greater than the current version and matches the selected channel name.

3. Glitter downloads and unpacks the update in background (without asking the user).

4. When the update is ready to install, the app displays some subtle sort of affordance (perhaps a titlebar icon) that, when clicked, displays the change log and has a button to initiate the update.

5. If the user never initiates the update manually, it will be installed on the next app launch (or perhaps when the app is not in use).


## Example

There's an example app, GlitterDemo, in this repository. See [GlitterDemo/GlitterDemoAppDelegate](GlitterDemo/GlitterDemoAppDelegate.m).


## API reference

### Info.plist keys

The bundle you update using Glitter can/needs to define the following keys in Info.plist:

* `GlitterFeedURL` (required) — a URL of the JSON feed file to use (`https` strongly recommended)

* `GlitterApplicationSupportSubfolder` (required) — a subfolder of `Library/Application Support` to store the updater state and pending update files. Normally you would specify something like `MyAppName/Updates` here.

* `GlitterDefaultChannelName` (optional, defaults to `stable`) — the default update channel name


### Primary APIs

* `glitter = [[Glitter alloc] initWithMainBundle]`

    Creates a new instance of Glitter. Unlike Sparkle, Glitter is not a singleton, so you need to save the result somewhere.

    You bundle Info.plist needs to have


* `[glitter checkForUpdatesWithOptions:GlitterCheckOptionUserInitiated]`

    Checks for updates

    If `GlitterCheckOptionUserInitiated` is passed in, `GlitterUserInitiatedUpdateCheckDidFinishNotification` is posted when the check completes, so that you can display some kind of alert if you want to.

* `[glitter installUpdate]`

    Installs the currently pending update.


### Querying Glitter status

* `glitter.checking` — YES if Glitter is currently checking for updates

* `glitter.downloadStep` — one of `GlitterDownloadStepNone` (not downloading an update), or `GlitterDownloadStepDownload` (downloading an update), `GlitterDownloadStepUnpack` (unpacking an update)

* `glitter.downloading` — YES if Glitter is currently downloading an update, same as `glitter.downloadStep != GlitterDownloadStepNone`

* `glitter.readyToInstall` — YES if there's an update ready to install (i.e. downloaded and unpacked)

When `glitter.checking == YES`, you can use:

* `glitter.checkIsUserInitiated` — YES if the current update check has been initiated with `GlitterCheckOptionUserInitiated` option

When `glitter.downloading == YES`, you can use:

* `glitter.downloadProgress` — 0.0 to 100.0, the percentage progress of the current download operation

* `glitter.downloadingVersionDisplayName` — version number of the release that is being downloaded (for UI purposes)

When `glitter.readyToInstall == YES`, you can use:

* `glitter.readyToInstallVersionDisplayName` — version number of the release that is being downloaded (for UI purposes)


### Notifications

* `GlitterStatusDidChangeNotification` — posted when some of the properties (might) have changed their values

* `GlitterUserInitiatedUpdateCheckDidFinishNotification` — posted when a user-initiated update check is completed

