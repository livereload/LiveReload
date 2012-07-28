debug = require('debug')('livereload:cli')

Path = require 'path'
fs   = require 'fs'

dreamopt = require('dreamopt')

OPTIONS = [
  'Commands for interactive usage:'
  '  watch'

  'Other commands:'
  '  rpc'

  'General options:'
]

class LiveReloadContext

exports.run = (argv) ->
  options = dreamopt OPTIONS,
    loadCommandSyntax: (name) ->
      require("./commands/#{name.replace(/\s/g, '-')}").usage

  debug JSON.stringify(options)

  context = new LiveReloadContext()
  context.paths = {}
  context.paths.root = Path.dirname(__dirname)
  context.paths.rpc  = Path.join(context.paths.root, 'rpc-api')

  context.paths.bundledPlugins = Path.join(context.paths.root, 'plugins')

  require("./commands/#{options.command}").run(options, context)
