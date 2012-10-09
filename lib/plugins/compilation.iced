debug = require('debug')('livereload:core:compilation')
Path  = require 'path'
{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class CompilationPlugin

  metadata:
    apiVersion: 1
    name: 'livereload-compilation'

  jobPriorities: [
    'compilation'
  ]


  loadProject: (project, memento) ->


  createSteps: (project) ->
    [new CompilationStep(project)]


class CompilationStep

  constructor: (@project) ->
    @id = 'compilation'
    @session = @project.session
    @queue = @project.session.queue


  # LiveReload API

  initialize: () ->
    @queue.register { project: @project.id, action: 'compile' }, @_perform.bind(@)

  schedule: (change) ->
    return unless @_isCompilationActive()
    @queue.add { project: @project.id, action: 'compile', paths: change.paths.slice(0) }


  # internal

  _isCompilationActive: ->
    @project.compilationEnabled

  _perform: (request, done) ->
    return done(null) unless @_isCompilationActive()

    for relpath in request.paths
      debug "Looking for compiler for #{relpath}..."
      for compiler in @session.pluginManager.allCompilers
        for spec in compiler.sourceSpecs
          if RelPathSpec.parseGitStyleSpec(spec).matches(relpath)
            debug "  ...#{relpath} matches compiler #{compiler.name}"
            await @_performCompilation relpath, compiler, defer()
            break

    done()


  _performCompilation: (relpath, compiler, callback) ->
    dstRelDir = Path.dirname(relpath)
    dstName = Path.basename(relpath, Path.extname(relpath)) + ".#{compiler.destinationExt}"
    dstRelPath = Path.join(dstRelDir, dstName)

    srcInfo = @_fileInfo(relpath)
    dstInfo = @_fileInfo(dstRelPath)

    info =
      '$(project_dir)': @project.fullPath
      '$(ruby)':  '/usr/bin/ruby'  # TODO: rvm/rubyenv/etc
      '$(node)':  process.execPath

      '$(src_rel_path)': srcInfo.relpath
      '$(src_path)':     srcInfo.path
      '$(src_dir)':      srcInfo.dir
      '$(src_file)':     srcInfo.file

      '$(dst_rel_path)': dstInfo.relpath
      '$(dst_path)':     dstInfo.path
      '$(dst_dir)':      dstInfo.dir
      '$(dst_file)':     dstInfo.file

      '$(additional)':   []

    invocation = compiler.tool.createInvocation(info)

    invocation.once 'finished', ->
      callback(null)
    invocation.run()


  _fileInfo: (relpath) ->
    fullPath = Path.join(@project.fullPath, relpath)

    return {
      relpath: relpath
      file:    Path.basename(relpath)
      path:    fullPath
      dir:     Path.dirname(fullPath)
    }
