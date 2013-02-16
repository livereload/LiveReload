# File-grained cross-platform FS monitoring for Node.js

**Wait, wait, how's it different from `fs.watch`?** Unlike `fs.watch`, fsmonitor:

* monitors an entire subtree (`fs.watch` only monitors a single folder)
* gives you the entire list of added, removed and modified files and folders (e.g. when you add or delete a non-empty folder, the change event will contain a list of all files in that folder)

Here's what happens when you call `fsmonitor.watch(path)`:

* The specified file system subtree is scanned, and the stat data is kept in memory.
* `fs.watch` is called to start monitoring every subfolder encountered.
* When change events are reported, the subtree is rescanned to determine the list of changes.
* `fs.watch` is called for the new subfolders, and the watchers are shut down for the removed ones.


## Status

Alpha stage. Seems to work, waiting for feedback, shipping as part of LiveReload 0.5 for Windows.

Planned features:

* only reporting changes in the files matching .gitignore-style masks you specify (using pathspec module for handling masks)
* more efficient native code implementations on Mac and Windows
* offloading per-folder monitoring backends to child processes to avoid hitting the limit on the number of file handles


## Installation

    npm install fsmonitor

or, to use fsmonitor command-line tool (see below):

    npm install -g fsmonitor


## Usage

    fsmonitor = require('fsmonitor');
    fsmonitor.watch('/some/folder', ['*.js'], function(change) {
        console.log("Change detected:\n" + change);  # has a nice toString

        console.log("Added files:    %j", change.addedFiles);
        console.log("Modified files: %j", change.modifiedFiles);
        console.log("Removed files:  %j", change.removedFiles);

        console.log("Added folders:    %j", change.addedFolders);
        console.log("Modified folders: %j", change.modifiedFolders);
        console.log("Removed folders:  %j", change.removedFolders);
    });


## Command-line tool

Includes a command-line tool that can report changes and/or run a specified command on every change.

For example, to invoke `npm test` when any JavaScript file is modified:

    fsmonitor -s -p '+*.js' npm test

Usage:

    Usage: fsmonitor [-d <folder>] [-p] [-s] [-q] [<mask>]... [<command> <arg>...]

    Options:
      -d <folder>        Specify the folder to monitor (defaults to the current folder)
      -p                 Print changes to console (default if no command specified)
      -s                 Run the provided command once on start up
      -q                 Quiet mode (don't print the initial banner)

    Masks:
      +<mask>            Include only the files matching the given mask
      !<mask>            Exclude files matching the given mask

      If no inclusion masks are provided, all files not explicitly excluded will be included.

    General options:
      --help             Display this message
      --version          Display fsmonitor version number
