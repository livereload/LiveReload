LiveReload 2
============

LiveReload is an essential tool for web developers, and is currently the top paid developer tool on the Mac App Store in many countries.

Please remember that this is not under a traditional free software license, but under a specific set of moral terms. I'm happy with you forking the source code, sharing your modifications and sharing binaries with your friends, but please don't post the binaries publicly without my permission, and don't fork the project under a different name. I want every user to buy a license by default, though, unless you have a good reason not to pay (in which case just ask me for a free license or copy a binary from someone else, there is no copy protection).

See http://livereload.com for licensing info and an optional backstory on that.

If you'd like to reuse some of the classes, please contact me and I'm likely to publish those under MIT.


Building LiveReload
-------------------

You need:

* Xcode 4.2.1
* Node 0.6.x (I'm actually using Node 0.5.5, but that's an accident to be corrected soon)
* Ruby 1.8.7 for running Rake

Build process:

1. Don't forget to pull all submodules after getting the source code.

2. Run `rake prepare`.

3. During development: Open LiveReload/LiveReload.xcodeproj with Xcode, click Run (or Build).

    For a release build:

    * Bump the version number, `rake version:update`, commit
    * Run `rake mac:release` to produce and zip a build
    * Give it a bit of testing
    * Run `rake mac:tag mac:upload` to tag a successful build and publish it on download.livereload.com
    * Run `rake mac:publish` to add the version to the web site's data (then rebuild and publish the web site)


Hacking tips
------------

1. Add backend/ to LiveReload, enable compilation.

2. Traditional (non-Node.js) LiveReload supports -LRPortNumber 35778 option to override the port number. This is useful to compile backend sources with one copy of LiveReload while debugging another one.


Updating Node.js
----------------

To re-sign the Node.js binary:

    codesign -f -s "3rd Party Mac Developer Application: Andrey Tarantsov" --identifier 'com.livereload.LiveReload.tools.nodejs' --entitlements LiveReload/Resources/LiveReloadNodejs.entitlements LiveReload/Resources/LiveReloadNodejs


Embedding Info.plist into Node.js
---------------------------------

We used to embed an Info.plist into the Node.js binary, but it started to result in a Mac App Store rejection (“invalid binary: missing bundle identifier”) as of June 2015.

If you ever need to try it again, use [gimmedebugah](https://github.com/gdbinit/gimmedebugah):

    gimmedebugah -p LiveReload/Resources/LiveReloadNodejsInfo.plist LiveReload/Resources/LiveReloadNodejs
    mv LiveReload/Resources/LiveReloadNodejs.patched LiveReload/Resources/LiveReloadNodejs
    chmod +x LiveReload/Resources/LiveReloadNodejs

To check for an embedded plist (if there is one, pipe the output to `xxd -r`):

    otool -X -s __TEXT __info_plist LiveReload/Resources/LiveReloadNodejs


Subprojects
-----------

* [ATCocoaLabs](https://github.com/andreyvit/ATCocoaLabs/)

Setting up [git-subdir](https://github.com/andreyvit/git-subdir/):

    git subdir ATCocoaLabs --url git@github.com:andreyvit/ATCocoaLabs.git

Sync:

    git subdir
    git subdir -S


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
