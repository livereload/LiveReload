# Session = require 'livereload-core'
# LocalVFS = require 'vfs-local'

exports.usage = [
  'Watch the given directory.'

  'Watches the current directory by default, use -d to watch some other directory/directories.'

  'Directories:'
  '  -d, --directory DIR  Operate on the given directory #list #var(dirs)'
]

exports.run = (options, context) ->

  if options.dirs.length is 0
    process.stderr.write "At least one directory is required (for now).\n"
    process.exit 2

  dirs = for dir in options.dirs
    Path.resolve(dir)

  session = new Session
  for dir in dirs
    session.addProject LocalVFS, dir

  if options.watch
    Server = require 'livereload-server'
    server = new Server()
    server.listen ->
      console.log "LiveReload is listening on port #{server.port}."
    server.on 'error', (err, connection) ->
      console.log "Closing connection #{connection.id} because of error #{err.code}: #{err.message}"
    server.on 'command', (connection, command) ->
      console.log "Received command #{command.command} on connection #{connection.id}: #{JSON.stringify(command)}"
    server.on 'connected', (connection) ->
      console.log "Connection #{connection.id} connected."
    server.on 'disconnected', (connection) ->
      console.log "Connection #{connection.id} disconnected."
    server.on 'livereload.js', (req, res) ->
      console.log "Serving livereload.js."
      await fs.readFile Path.join(__dirname, '../res/livereload.js'), 'utf8', defer(err, data)
      throw err if err
      res.writeHead 200, 'Content-Length': data.length, 'Content-Type': 'text/javascript'
      res.end(data)

    session.addInterface(server)
    session.startMonitoring()

