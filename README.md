# LiveReload web socket and http server

A component of LiveReload 3 that:

* serves `livereload.js` over HTTP
* listens for web socket connections; parses the incoming messages and validates outgoing messages using [livereload-protocol](https://github.com/livereload/livereload-protocol)
* will handle URL overriding once I implement that for LR3

## License

© 2012, Andrey Tarantsov, distributed under the MIT license.
