# LiveReload client

Handles the client side of the [LiveReload protocol](http://go.livereload.com/protocol), connects to LiveReload 2 app and any other running instance of [livereload-server](https://github.com/livereload/livereload-server).


## Synopsis

    PROTOCOLS =
      monitoring: [LRClient.protocols.MONITORING_7]
      connCheck:  [LRClient.protocols.CONN_CHECK_1]

    client = new LRClient
      supportedProtocols: PROTOCOLS
      WebSocket: WebSocket || MozWebSocket

      id: "com.mycompany.myapp"   # unique reverse-dns style id of your app
      name: "MyApp"               # user-friendly name of your app
      version: "1.0"              # version number of your app

    client.on 'connected', (negotiatedProtocols) ->
      console.log "Monitoring protocol version: %d", negotiatedProtocols.monitoring
      console.log "Connection check protocol version: %d", negotiatedProtocols.connCheck

      if negotiatedProtocols.connCheck >= 1
        client.send { command: 'ping', token: 'test' }

    client.on 'command', (message) ->
      console.log "Received command %s with data %j", message.command, message

    client.open()


## Installation

    npm install livereload-client


## Running tests

    npm test


## License

© 2012, Andrey Tarantsov, distributed under the [Open Community Indie Software License](https://gist.github.com/2466992).

Note that the license limits redistribution of this code, so you probably don't want to use it in public apps. Please [contact me](mailto:andrey@tarantsov.com) if you have a use for this module; I might reconsider the license, extract some pieces of it or suggest another option.
