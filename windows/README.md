livereload-windows
==================

LiveReload for Windows


## Building

WARNING: you must be building from `windows/` folder of the [main LiveReload repository](https://github.com/livereload/LiveReload2) (branch “devel”). If you are running from `livereload-windows` repository, `bundle-plugins.cmd` won't work.

WARNING 2: you must be building from a folder without funny characters in the path (esp spaces).

Prerequisites:

* Microsoft Visual Studio 2012 (VS 2010 should work too)
* Node 0.10.x with npm
* IcedCoffeeScript 1.3.3f

Don’t forget to pull all submodules after getting the source code!

Build the backend:

* Install externel dependencies of each package:

    On a Mac:

        # bash
        for i in node_modules/*; do (echo; echo $i; cd $i; npm install); done
        # fish
        for i in node_modules/*; echo; echo $i; pushd $i; npm install; popd; end

    On Windows (from 'windows' folder): invoke `install-npm-modules.cmd`
        

* On a Mac, check and kill any redundant local packages found. The following folders must _not_ exist:

        livereload-client/node_modules/livereload-protocol
        livereload-core/node_modules/fsmonitor
        livereload-core/node_modules/jobqueue
        livereload-core/node_modules/pathspec
        livereload-new/node_modules/fsmonitor
        livereload-new/node_modules/pathspec
        livereload-server/node_modules/livereload-protocol
        livereload/node_modules/livereload-core
        livereload/node_modules/livereload-server
        livereload/node_modules/pathspec
        livereload/node_modules/vfs-local

* Compile CoffeeScript sources.

    On a Mac (use `-cw` for watch mode, `-c` for one-time compilation):

        iced --runtime inline -cw node_modules/*/*.{coffee,iced} node_modules/*/{lib,test,config,rpc-api,bin}/**.{coffee,iced}

    On Windows (from 'windows' folder):

        cd tools\compiler
        npm install

    then invoke `compile-backend.cmd`, and then invoke the generated `compile-backend-files.cmd` (only one-time compilation is supported).

Verify that the backend works:

* Run and make sure it displays a command-line usage error:

        node node_modules/livereload/bin/livereload.js

* Run and make sure it starts up, outputs a bunch of stuff and listens for browser connections (Ctrl-C to quit):

        node node_modules/livereload/bin/livereload.js rpc console

* Run and make sure it outputs nothing (Ctrl-C to quit):

        node node_modules/livereload/bin/livereload.js rpc server

Prepare the bundled resources:

* Run `powershell ./bundle-backend.ps1`
* Run `bundle-ruby.cmd`
* Run `bundle-node.cmd`
* Run `bundle-plugins.cmd`

Finally, open the solution in Visual Studio and perform a build.


## Releasing a build

* Update version number: `node SetVersionNumber.js 0.9.3.0`

* Commit (Version bump to x.y.z)

* Update the version history message in `MainWindow.xaml`.

* Open "VS 2013 x86 Native Tools Command Prompt" (using the Start menu).

* Run PubLiveBuild.cmd from the native tools window.

    If the build fails in Visual Studio 2013 Professional, try [this StackOverflow answer](http://stackoverflow.com/a/25756668/58146) or other answers to the same question.

* Copy `PubConfig.cmd.example` into `PubConfig.cmd` and put your Amazon AWS credentials there. Obviously, you only need to do this once.

    Recommended: create an IMA account that only has access to the bucket you're trying to upload to. Create and apply a security policy similar to:

        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListAllMyBuckets"
                    ],
                    "Resource": [
                        "arn:aws:s3:::*"
                    ]
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListBucket",
                        "s3:ListBucketMultipartUploads",
                        "s3:GetBucketAcl",
                        "s3:GetBucketLocation"
                    ],
                    "Resource": [
                        "arn:aws:s3:::download.livereload.com"
                    ]
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListBucket",
                        "s3:GetObject",
                        "s3:GetObjectAcl",
                        "s3:PutObject",
                        "s3:PutObjectAcl",
                        "s3:ListMultipartUploadParts",
                        "s3:AbortMultipartUpload"
                    ],
                    "Resource": [
                        "arn:aws:s3:::download.livereload.com/*",
                        "arn:aws:s3:::download.livereload.com/windows/*",
                        "arn:aws:s3:::download.livereload.com/windows-stage/*"
                    ]
                }
            ]
        }

* Run `PubLiveUpload.cmd` (note: sadly, this triggers installation of .NET Framework 3.5 on Windows 8.1; unfortunately later versions of s3sync are commercial and cannot be distributed as part of this build process)

* After it succeeds, run `PubLiveCommit.cmd`.

## Running PowerShell scripts

As [explained on MSDN](http://technet.microsoft.com/library/hh847748.aspx), you need to configure PowerShell to run scripts. Here's how:

1. Press Win+X, run Command Prompt (Admin).
2. Run `powershell`
3. In PS, run `Set-ExecutionPolicy -ExecutionPolicy Unrestricted`


## Overriding the backend and plugins path

When running LiveReload from LiveReload2 repository, you can have it pick up the backend files from the repository folder.

Option A. You can enable the dev mode to run the backend code from the repository. Right-click the version number in the title bar and enable “Development Mode”. This will restart the app. If you've been running from Visual Studio, after doing this step you must restart the app from within Visual Studio manually.


Option B. You can specify a custom backend path. In Visual Studio, open the project properties, switch to Debug tab and specify the following command-line argument:

    -LRBackendOverride C:\livereload-devel\node_modules\livereload
    -LRBundledPluginsOverride C:\livereload-devel\plugins

When you run, Visual Studio will give a warning that command-line arguments will not be passed to secured applications; however, for some reason, it works anyway (at least on Windows XP). You can turn off "Enable ClickOnce security settings" on Security tab to make the warning go away.

Note that command-line arguments are widely reported to not work with ClickOnce applications, however I didn't have any problems so far; passing arguments to the compiled exe file works as expected.


## Bundled Ruby

We use 7z archive of Ruby downloaded via http://rubyinstaller.org/.

Ruby 1.9.3 is ruby-1.9.3-p286-i386-mingw32.7z with the following items removed:

	bin/tcl*
	bin/tk*
	lib/tcltk/
	lib/ruby/1.9.1/tk*
	lib/*.a   # presumably these are only needed to build native extensions?


## Acknowledgements

* fastJSON library:      http://fastjson.codeplex.com/
* MahApps.Metro:         http://mahapps.com/MahApps.Metro/
* Modern UI Icons:       http://modernuiicons.com/
* EditableTextBlock:     http://www.codeproject.com/Articles/31592/Editable-TextBlock-in-WPF-for-In-place-Editing
