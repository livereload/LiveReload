debug = require('debug')('livereload:cli')

Path = require 'path'
fs   = require 'fs'

dreamopt = require('dreamopt')

LiveReloadContext = require './context'


OPTIONS = [
  'Commands for interactive usage:'
  '  watch'

  'Other commands:'
  '  rpc'

  'General options:'
]


exports.run = (argv) ->
  options = dreamopt OPTIONS,
    loadCommandSyntax: (name) ->
      require("./commands/#{name.replace(/\s/g, '-')}").usage

  debug JSON.stringify(options)

  context = new LiveReloadContext()
  context.paths = {}
  context.paths.root = Path.dirname(__dirname)
  context.paths.rpc  = Path.join(context.paths.root, 'rpc-api')

  context.paths.bundledPlugins = process.env.LRBundledPluginsOverride || Path.join(context.paths.root, 'plugins')
  context.session.addPluginFolder context.paths.bundledPlugins

  require("./commands/#{options.command}").run(options, context)
