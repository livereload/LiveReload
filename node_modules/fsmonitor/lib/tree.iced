debug = require('debug')('fsmonitor')
fs    = require 'fs'
Path  = require 'path'

{ EventEmitter } = require 'events'

{ PlaPath } = require './pathutil'

prependUniques = (dest, source) ->
  for item in source
    if dest.indexOf(item) < 0
      dest.unshift item
  dest

appendUniques = (dest, source) ->
  for item in source
    if dest.indexOf(item) < 0
      dest.push item
  dest


class FSFile
  constructor: (@relpath, @stats) ->

  equals: (peer) ->
    if this.stats.isFile()
      (this.stats.size == peer.stats.size) and (this.stats.mode == peer.stats.mode) and (+this.stats.mtime == +peer.stats.mtime) and (this.stats.dev == peer.stats.dev) and (this.stats.ino == peer.stats.ino)
    else
      (this.stats.mode == peer.stats.mode)

  toString: ->
    "FSFile(#{@relpath})"


class FSChange
  constructor: ->
    @addedFiles    = []
    @modifiedFiles = []
    @removedFiles  = []

    @addedFolders    = []
    @modifiedFolders = []
    @removedFolders  = []

  isEmpty: ->
    (@addedFiles.length + @modifiedFiles.length + @removedFiles.length + @addedFolders.length + @modifiedFolders.length + @removedFolders.length) == 0

  prepend: (peer) ->
    prependUniques @addedFiles,    peer.addedFiles
    prependUniques @modifiedFiles, peer.modifiedFiles
    prependUniques @removedFiles,  peer.removedFiles

    prependUniques @addedFolders,    peer.addedFolders
    prependUniques @modifiedFolders, peer.modifiedFolders
    prependUniques @removedFolders,  peer.removedFolders

  append: (peer) ->
    appendUniques @addedFiles,    peer.addedFiles
    appendUniques @modifiedFiles, peer.modifiedFiles
    appendUniques @removedFiles,  peer.removedFiles

    appendUniques @addedFolders,    peer.addedFolders
    appendUniques @modifiedFolders, peer.modifiedFolders
    appendUniques @removedFolders,  peer.removedFolders

  toString: ->
    [
      @_listToString '+', @addedFiles,    ''
      @_listToString '!', @modifiedFiles, ''
      @_listToString '-', @removedFiles,  ''
      @_listToString '+', @addedFolders,    '/'
      @_listToString '!', @modifiedFolders, '/'
      @_listToString '-', @removedFolders,  '/'
    ].join('')

  _listToString: (prefix, list, suffix) ->
    result = []
    for relpath in list.slice(0).sort()
      result.push "#{prefix}#{relpath}#{suffix}\n"
    return result.join('')


module.exports =
class FSTree extends EventEmitter

  constructor: (@root, @filter) ->
    if @filter and not ((typeof @filter.matches is 'function') and (typeof @filter.excludes is 'function'))
      throw new Error "Invalid filter provided to FSTree; must define .matches() and .excludes()"
    @filter or= { matches: (-> yes), excludes: (-> no) }

    @_files   = []
    @_folders = []
    @_errors  = []
    await @_walk @root, '', defer()

    @_updateRequested  = no
    @_updateInProgress = no

    debug "Finished building FSTree with #{@_files.length} files and #{@_folders.length} folders at #{@root}"
    @emit 'complete'


  update: (folder, item) ->
    @_updateRequested = yes
    unless @_updateInProgress
      @_performQueuedUpdate()
    return

  _performQueuedUpdate: ->
    @_updateInProgress = yes
    @_updateRequested  = no
    debug "Updating FSTree at #{@root}"

    oldFiles = {}
    for file in @_files
      oldFiles[file.relpath] = file

    oldFolders = {}
    for folder in @_folders
      oldFolders[folder.relpath] = folder

    @_files   = []
    @_folders = []
    @_errors  = []
    await @_walk @root, '', defer()

    change = new FSChange()

    # addedFiles, modifiedFiles
    for file in @_files
      relpath = file.relpath
      if oldFiles.hasOwnProperty(relpath)
        old = oldFiles[relpath]
        delete oldFiles[relpath]
        change.modifiedFiles.push(relpath) unless file.equals(old)
        unless file.equals(old)
          debug "Change in file #{relpath}:"
          debug "  .. size #{file.stats.size} != #{old.stats.size}" unless file.stats.size == old.stats.size
          debug "  .. mode #{file.stats.mode} != #{old.stats.mode}" unless file.stats.mode == old.stats.mode
          debug "  .. mtime #{+file.stats.mtime} != #{+old.stats.mtime}" unless +file.stats.mtime == +old.stats.mtime
          debug "  .. size #{file.stats.size} != #{old.stats.size}" unless file.stats.size == old.stats.size
          debug "  .. dev #{file.stats.dev} != #{old.stats.dev}" unless file.stats.dev == old.stats.dev
          debug "  .. ino #{file.stats.ino} != #{old.stats.ino}" unless file.stats.ino == old.stats.ino
      else
        change.addedFiles.push(relpath)
    # removedFiles
    for own key, file of oldFiles
      change.removedFiles.push file.relpath

    # addedFolders, modifiedFolders
    for folder in @_folders
      relpath = folder.relpath
      if oldFolders.hasOwnProperty(relpath)
        old = oldFolders[relpath]
        delete oldFolders[relpath]
        change.modifiedFolders.push(relpath) unless folder.equals(old)
        unless folder.equals(old)
          debug "Change in folder #{relpath}/:"
          debug "  .. mode #{folder.stats.mode} != #{old.stats.mode}" unless folder.stats.mode == old.stats.mode
      else
        change.addedFolders.push(relpath)
    # removedFolders
    for own key, folder of oldFolders
      change.removedFolders.push folder.relpath

    @emit 'change', change  unless change.isEmpty()

    @_updateInProgress = no
    if @_updateRequested
      @_performQueuedUpdate()



  Object.defineProperty @::, 'allFiles', get: ->
    (file.relpath for file in @_files).sort()

  Object.defineProperty @::, 'allFolders', get: ->
    (file.relpath for file in @_folders).sort()

  findMatchingPaths: (list) ->
    (file.relpath for file in @_files when list.matches(file.relpath)).sort()

  findFilesBySuffix: (suffix, { bestSubtree }, callback) ->
    suffix = PlaPath.normalize(suffix)

    name = Path.basename(suffix)

    bestScore = 0

    allMatches =
      for file in @_files
        path = file.relpath
        # debug "findFilesMatchingSuffixInSubtree considering: path = %j", path

        continue unless Path.basename(path) is name
        score = PlaPath.numberOfMatchingTrailingComponents(path, suffix)
        score += 0.5 if bestSubtree && PlaPath.isSubpath(path, bestSubtree)

        bestScore = score if score > bestScore

        debug "findFilesMatchingSuffixInSubtree match: path = %j, score = %j", path, score

        { path, score }

    bestMatches = (match for match in allMatches when match.score is bestScore)

    bestMatch = if bestMatches.length is 1 then bestMatches[0] else null

    process.nextTick ->
      callback null, { allMatches, bestMatches, bestMatch }


  _addError: (path, err) ->
    @_errors.push { path, err }

  _addFile: (relpath, stats) ->
    debug "file: #{relpath}"
    @_files.push new FSFile(relpath, stats)

  _addFolder: (relpath, stats) ->
    debug "FOLD: #{relpath}"
    @_folders.push new FSFile(relpath, stats)

  _walk: (path, relpath, autocb) ->
    await fs.lstat path, defer(err, stats)
    return @_addError(path, err) if err

    if stats.isFile()
      if @filter.matches(relpath, no)
        @_addFile relpath, stats
    else if stats.isDirectory()
      return if @filter.excludes(relpath, yes)
      @_addFolder relpath, stats

      await fs.readdir path, defer(err, files)
      return @_addError(path, err) if err

      for file in files
        await @_walk Path.join(path, file), Path.join(relpath, file), defer()
