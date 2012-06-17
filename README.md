# LiveReload web socket and http server

A component of LiveReload 3 that:

* serves `livereload.js` over HTTP
* listens for web socket connections; parses the incoming messages and validates outgoing messages using [livereload-protocol](https://github.com/livereload/livereload-protocol)
* will handle URL overriding once I implement that for LR3

## License

© 2012, Andrey Tarantsov, distributed under the [Open Community Indie Software License](https://gist.github.com/2466992).

Note that the license limits redistribution of this code, so you probably don't want to use it in public apps. Please [contact me](mailto:andrey@tarantsov.com) if you have a use for this module; I might reconsider the license, extract some pieces of it or suggest another option.

