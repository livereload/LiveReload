LiveReload 3
============

LiveReload is an essential tool for web developers, and is currently the top paid developer tool on the Mac App Store in many countries.


License
-------

Copyright 2012 Andrey Tarantsov — andrey@tarantsov.com

**Purchasing policy notice:** All users of the software are expected to purchase a license from Andrey Tarantsov unless they have a good reason not to pay. Users that don't purchase a license are encouraged to apply for a free one at support@livereload.com. The users are free to:

* download, build and modify the app;
* share the modified source code;
* share the purchased or custom-built binaries (with unmodified license and contact info), provided that the purchasing policy is explained to all potential users.


This software is available under the **Open Community Indie Software License**:

Permission to use, copy, modify, and/or distribute this software for any purpose is hereby granted, free of charge, subject to the following conditions:

* all copies retain the above copyright notice, the above purchasing policy notice and this permission notice unmodified;

* all copies retain the name of the software (LiveReload), the name of the author (Andrey Tarantsov) and the contact information (including, but not limited to, pointers to support@livereload.com and livereload.com URLs) unmodified;

* no fee is charged for distribution of the software;

* the best effort is made to explain the purchasing policy to all users of the software.

In the event that no new official binary releases of the software are published for two consecutive years, the above conditions are permanently waived, and the software is additionally made available under the terms of the MIT license.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


Building LiveReload for Windows
-------------------------------

1. Build the backend using the instructions below (“Building the backend for the Windows version”).

2. Follow [windows/README.md](windows/README.md).


Building LiveReload for Mac
---------------------------

Note: right now this branch is in a transitional state; I'm doing active development of Mac v3.0.x. See the ‘master’ branch for the latest stable Mac version (v2.3.x).

Prerequisites:

* Xcode 5.0
* Node 0.10
* CoffeeScript 1.6.x: `npm install -g coffee-script`
* underscore.js: `npm install -g underscore`
* grunt
* optionally, Ruby 1.8.7 with Rake for running Rake tasks

For running tests:

* Mocha 1.7.0: `npm install -g mocha`
* Cucumber.js 0.3.0: `npm install -g cucumber`
* fsmonitor 0.2.2: `npm install -g fsmonitor` (warning: don't rely on `--version`, it lies)

Building:

1. Don’t forget to pull all submodules after getting the source code.

1. Install and compile the backend modules:

        cd node_modules/livereload-new     && npm install && grunt &&
        cd ../livereload-service-dummy     && npm install && grunt
        cd ../livereload-service-server    && npm install && grunt
        cd ../livereload-service-reloader  && npm install && grunt
        cd ../livereload-soa               && npm install && grunt
        cd ../livereload-server            && coffee -c lib
        cd ../livereload-protocol          && coffee -c lib
        cd ../pathspec                     && coffee -c lib

1. Package the backend modules into `mac/backend`:

        cd scripts && npm install
        cd ..
        scripts/node_modules/.bin/_coffee scripts/package-backend.coffee_ node_modules/livereload-new mac/backend

    During development, use override mode instead — open Xcode scheme settings and set LRBackendOverride env var to the full path of `node_modules/livereload-new/bin/livereload.js`.

1. Open `LiveReload/LiveReload.xcodeproj` and build it with Xcode.

    *(Alternatively, use `rake mac:release` or a similar task. See `rake -T` for the full list.)*



Building the backend for the Windows version
--------------------------------------------

Prerequisites:

* Node 0.10.x with npm
* IcedCoffeeScript 1.3.3f

Building:

1. Install build script dependencies:

        cd scripts
        npm install
        cd ..

2. Use the script to set up symlinks inside node_modules/ repo folder:

        iced scripts/relink.iced

3. Install externel dependencies of each package:

        for i in node_modules/*; do (echo; echo $i; cd $i; npm install); done

4. Relink again, because `npm install` loves to screw things up:

        iced scripts/relink.iced

5. Compile CoffeeScript sources (use `-cw` for watch mode, `-c` for one-time compilation):

        iced --runtime inline -cw node_modules/*/*.{coffee,iced} node_modules/*/{lib,test,config,rpc-api,bin}/**.{coffee,iced}

Verifying:

1. Run and make sure it displays a command-line usage error:

        node node_modules/livereload/bin/livereload.js

2. Run and make sure it starts up, outputs a bunch of stuff and listens for browser connections (Ctrl-C to quit):

        node node_modules/livereload/bin/livereload.js rpc console

3. Run and make sure it outputs nothing (Ctrl-C to quit):

        node node_modules/livereload/bin/livereload.js rpc server


LR for Mac hacking tips
-----------------------

* Add `backend/` to LiveReload, enable compilation.
* Set `LRBackendOverride` environment variable to `/path/to/LiveReload/node_modules/livereload-new/bin/livereload.js`, so your changes are picked up without rerunning `rake backend`.
* To run multiple copies of LiveReload, set `LRPortOverride` to some unused TCP port.
* Set `LRBundledPluginsOverride` to specify a path to the bundled plugins when running on the command line.
  - *(Also useful for speeding up Xcode builds; temporarily delete bundled plugins from the project and set this variable so that LiveReload can find them.)*


git-subdir
----------

We're using git-subdir to sync commits between this repository and the repositories of individual projects.

This probably is of no concern to you, but in case you need it, you can run the following commands to set it up:

    git subdir node_modules/livereload/ -r cli --url git@github.com:livereload/livereload-cli.git --method squash,linear
    git subdir node_modules/livereload-core/ -r core --url git@github.com:livereload/livereload-core.git --method squash,linear
    git subdir node_modules/livereload-server/ -r server --url git@github.com:livereload/livereload-server.git --method squash,linear
    git subdir node_modules/livereload-client/ -r client --url git@github.com:livereload/livereload-client.git --method squash,linear
    git subdir node_modules/livereload-protocol/ -r protocol --url git@github.com:livereload/livereload-protocol.git --method squash,linear

    git subdir node_modules/fsmonitor/ -r fsmonitor --url git@github.com:andreyvit/fsmonitor.js.git --method squash,linear
    git subdir node_modules/jobqueue/ -r jobqueue --url git@github.com:livereload/jobqueue.git --method squash,linear
    git subdir node_modules/pathspec/ -r pathspec --url git@github.com:andreyvit/pathspec.js.git --method squash,linear
    git subdir node_modules/reactive/ -r reactive --url git@github.com:andreyvit/reactive.js.git --method squash,linear

    git subdir node_modules/vfs-local/ -r vfs-local --url git@github.com:livereload/vfs-local.git --method squash,linear
    git subdir node_modules/vfs-test/ -r vfs-test --url git@github.com:livereload/vfs-test.git --method squash,linear

    git-subdir mac/ATPathSpec --url git@github.com:andreyvit/ATPathSpec.git --method squash,linear


Signing the bundled Node.js binary
----------------------------------

Copy:

    cp /usr/local/bin/node LiveReload/Resources/LiveReloadNodejs

Sign:

    codesign -f -s "3rd Party Mac Developer Application: Andrey Tarantsov" --entitlements LiveReload/Resources/LiveReloadNodejs.entitlements LiveReload/Resources/LiveReloadNodejs

Verify:

    codesign -dvvv ./LiveReload/Resources/LiveReloadNodejs



AppNewsKit
==========

(See `Stats.h/m`. This is a seriously cool shit to communicate with your live users. Consider those files to be under MIT. I’ll extract and document it properly soon.)

* Collect usage statistics
* Deliver news to your users

Example `ping.txt`:

```javascript
    {
        "see_explanation_at": "http://help.livereload.com/kb/about-us/usage-statistics-privacy-policy",
        "messages": [
            {
                "title": "MyApp on the Mac App Store!",
                "message": "MyApp 2.1 has been released on the Mac App Store, and is on sale (50% off)! Do you want to learn more about it?",
                "id": "myapp-2.0.0-release",
                "version": [">=2.0 <3.0"],
                "status": ["unregistered"],
                "stats": {
                    "stat.reloads": { "min": 10 }
                },
                "delay_if_nagged_within": "3d",
                "remind_later_in": "5d",
                "deliver_after": "2011-12-08 16:33:00",
                "wait_until_good_time": true,
                "delivery_on_stats": {
                    "or": {
                        "stat.reloads.last": { "within": 30 },
                        "stat.launch.first": { "within": 120 }
                    }
                },
                "random_percentage": 50,
                "primary_button_url": "http://myapp.com/mas/",
                "primary_button_title": "Visit Mac App Store"
            }
        ]
    }
```
