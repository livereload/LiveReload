LiveReload 2
============

LiveReload is an essential tool for web developers, and is currently the top paid developer tool on the Mac App Store in many countries.

Please remember that this is not under a traditional free software license, but under a specific set of moral terms. I'm happy with you forking the source code, sharing your modifications and sharing binaries with your friends, but please don't post the binaries publicly without my permission, and don't fork the project under a different name. I want every user to buy a license by default, though, unless you have a good reason not to pay (in which case just ask me for a free license or copy a binary from someone else, there is no copy protection).

See http://livereload.com for licensing info and an optional backstory on that.

If you'd like to reuse some of the classes, please contact me and I'm likely to publish those under MIT.


Setting things up
-----------------

(Doc in progress.)

Subdirectories configuration for git-subdir:

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

Then:

    cd scripts
    npm install
    cd ..
    iced scripts/relink.iced

Then:

    for i in node_modules/*; do (echo; echo $i; cd $i; npm install); done
    iced scripts/relink.iced  # relink again because npm install loves to screw things up

Then:

    iced --runtime inline -cw node_modules/*/*.{coffee,iced} node_modules/*/{lib,test,config,rpc-api,bin}/**.{coffee,iced}

Then:

    node node_modules/livereload/bin/livereload.js
    node node_modules/livereload/bin/livereload.js rpc console
    node node_modules/livereload/bin/livereload.js rpc server



Building LiveReload
-------------------

You need:

* Xcode 4.2.1
* Node 0.6.x (I'm actually using Node 0.5.5, but that's an accident to be corrected soon)
* Ruby 1.8.7 for running Rake

Build process:

1. Don't forget to pull all submodules after getting the source code.

2. You need IcedCoffeeScript: `npm install -g iced-coffee-script` (version 1.3.x should be fine).

3. Compile the backend files: `iced -I inline -c cli`.

4. Run `rake backend` to package the backend into `interim/backend`.

5. Open LiveReload/LiveReload.xcodeproj and build it with Xcode. Alternatively, use `rake mac:release` or a similar task (see `rake -T` for the full list).


Hacking tips
------------

1. Add backend/ to LiveReload, enable compilation.

2. Set LRBackendOverride environment variable to `/path/to/LiveReload/cli/bin/livereload.js` so that your changes are picked up without rerunning `rake backend`.

3. To run multiple copies of LiveReload, set LRPortOverride to some unused TCP port.

4. Set LRBundledPluginsOverride to specify a path to the bundled plugins when running on the command line. (Also useful for speeding up Xcode builds by temporarily deleting the bundled plugins from the project and setting this variable so that LiveReload can find them.)


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

(See Stats.h/m. This is a seriously cool shit to communicate with your live users. consider those files to be under MIT; I will extract and document it properly soon.)

* Collect usage statistics
* Deliver news to your users

Example ping.txt:

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
