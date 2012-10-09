# LiveReload core logic

A work in progress. Powers LiveReload for Windows v0.5+ and LiveReload for Mac 3.0+.

Handles (or will handle):

* project analysis (imports, Compass detection)
* compiler and postprocessor invocation
* extracting errors/warnings from the compiler output
* issuing browser refresh commands
* saving changes made in Chrome Web Inspector
* etc

Does not handle:

* storing the list of projects
* listening for and handling browser connections
* command-line or any other UI
* bundling standard plugins (LESS, Sass, etc)
* bundling Node or Ruby runtimes

Basically the idea is that livereload-core is an ‘embeddable’ part of LiveReload, which can be assembled to do everything that LiveReload does, but makes no assumptions about the overall app environment like packaging, app type (GUI / command-line) and bundled stuff.


## License

© 2012, Andrey Tarantsov, distributed under the [Open Community Indie Software License](https://gist.github.com/2466992).

Note that the license limits redistribution of this code, so you probably don't want to use it in public apps. Please [contact me](mailto:andrey@tarantsov.com) if you have a use for this module; I might reconsider the license, extract some pieces or suggest another option.
