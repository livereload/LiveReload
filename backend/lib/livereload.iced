require 'sugar'

Path = require 'path'

LRApplication = require './app/application'
LineOrientedStreamTransport = require './rpc/streamtransport'

exports.run = (input, output, argv, exit) ->
  app = new LRApplication(new LineOrientedStreamTransport(input, output))

  app.on 'quit', (exitCode=0) =>
    exit(exitCode)

  if '--console' in argv
    app.rpc.transport.consoleDebuggingMode = yes
    # callbackTimeout = 60000

    app.start {
      pluginFolders: [ Path.join(__dirname, "../../LiveReload/Compilers") ]
      preferencesFolder: process.env['TMPDIR']
      version: "1.2.3"
    }, (err) ->
      throw err if err

  return app
