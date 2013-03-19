livereload-windows
==================

LiveReload for Windows


## Building

WARNING: you must be building from `windows/` folder of the [main LiveReload repository](https://github.com/livereload/LiveReload2) (branch “devel”). If you are running from `livereload-windows` repository, `bundle-plugins.cmd` won't work.

Prerequisites:

* Microsoft Visual Studio 2010

Process:

* Run `bundle-backend.cmd`
* Run `bundle-ruby.cmd`
* Run `bundle-node.cmd`
* Run `bundle-plugins.cmd`
* Perform the build in Visual Studio


## Overriding the backend and plugins path

You can specify an alternative backend path to avoid going through the lengthy packaging and extraction process on every backend change.

In Visual Studio, open the project properties, switch to Debug tab and specify the following command-line argument:

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

NOTES:

* when updating fastJSON library to newer version, change its Target Framework to match one of LiveReload.
