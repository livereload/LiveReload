# npm = require 'npm'
fs     = require 'fs'
Path   = require 'path'
_      = require 'underscore'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'

dirs = { node_modules: Path.join(Path.dirname(__dirname), 'node_modules') }


class Module
  constructor: (@name, @path) ->
    @packageJsonPath = Path.join(@path, 'package.json')
    @node_modules = Path.join(@path, 'node_modules')

  readPackageJson: ->
    @info = JSON.parse(fs.readFileSync(@packageJsonPath, 'utf8'))

options = require('dreamopt') [
  "Usage: iced scripts/relink.iced [-u]"

  "  -u, --unlink    Remove the symlinks and don't recreate them"
]

modules =
  for moduleName in fs.readdirSync(dirs.node_modules)
    continue if moduleName is ".bin"
    moduleDir = Path.join(dirs.node_modules, moduleName)
    continue unless fs.statSync(moduleDir).isDirectory()
    new Module(moduleName, moduleDir)

modulesByName = _.object(_.pluck(modules, 'name'), modules)

for module in modules
  module.readPackageJson()
  for own depName, depSpec of module.info.dependencies || {}
    if modulesByName.hasOwnProperty(depName)
      depPath = Path.join(module.node_modules, depName)
      depTargetPath = Path.join(dirs.node_modules, depName)

      try
        stats = fs.lstatSync(depPath)
      catch e
        stats = null

      if stats and stats.isSymbolicLink() and !options.unlink
        console.log("%s: %s (exists)", module.info.name, depName)

      else
        if stats
          console.log("%s: %s (deleting)", module.info.name, depName)
          if stats.isSymbolicLink()
            fs.unlinkSync(depPath)
          else
            rimraf.sync(depPath)

        unless options.unlink
          console.log "%s: %s (symlinking)", module.info.name, depName
          mkdirp.sync(Path.dirname(depPath))
          fs.symlinkSync(depTargetPath, depPath)
