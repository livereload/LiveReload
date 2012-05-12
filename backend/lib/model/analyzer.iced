log = require('dreamlog')('livereload.analyzer')
R = require '../reactive'
Job = require '../app/jobs'
{ RelPathList } = require 'pathspec'

class ListVarType

  constructor: ->
    @sourceIdToItems = {}
    @x = 10

  get: ->
    items = []
    for _, pieces of @sourceIdToItems
      items.pushAll pieces
    return items

  update: (sourceId, newPieces) ->
    oldPieces = @sourceIdToItems[sourceId]
    return no if Object.equal(oldPieces, newPieces)

    @sourceIdToItems[sourceId] = newPieces
    return yes


class DictVarType

  constructor: ->
    @sourceIdToItems = {}

  get: ->
    result = {}
    for _, pieces of @sourceIdToItems
      for piece in pieces
        Object.merge result, piece
    return result

  update: (sourceId, newPieces) ->
    oldPieces = @sourceIdToItems[sourceId]
    return no if Object.equal(oldPieces, newPieces)

    @sourceIdToItems[sourceId] = newPieces
    return yes


class GraphVarType

  constructor: ->
    @sourceIdToItems = {}

  get: -> this

  update: (sourceId, newPieces) ->
    oldPieces = @sourceIdToItems[sourceId]
    return no if Object.equal(oldPieces, newPieces)

    @sourceIdToItems[sourceId] = newPieces
    return yes

  visitBackwards: (vertex, roots=[], visited={}) ->
    visited[vertex] = yes
    hasChildren = no
    for own _, pieces of @sourceIdToItems
      for [first, second] in pieces when second is vertex
        hasChildren = yes
        @visitBackwards first, roots, visited  unless visited[first]
    if !hasChildren
      roots.push vertex
    return roots

  findRoots: (vertex) ->
    @visitBackwards(vertex)

  hasBackwardReferences: (vertex) ->
    for own _, pieces of @sourceIdToItems
      for [first, second] in pieces when second is vertex
        return yes
    return no

  toString: ->
    (for own _, pieces of @sourceIdToItems
      for [first, second] in pieces
        "#{first}-#{second}").flatten().join(' ')


StandardTypes =
  list:  ListVarType
  dict:  DictVarType
  graph: GraphVarType


class Analyzer
  constructor: (@__uid, @func) ->
    @outputVars = {}

  addOutputVar: (varDef) ->
    @outputVars[varDef.__uid] = varDef
    varDef.producingAnalyzers[this.__uid] = this
    log.debug "#{varDef} produced by #{this}"

class FileAnalyzer extends Analyzer
  constructor: (uid, func, @pathList) ->
    super(uid, func)
    if typeof @pathList is 'function'
      throw new Error "!!!!! #{uid}"

  toString: ->
    "FileAn(#{@__uid})"

class ProjectAnalyzer extends Analyzer
  constructor: (uid, func) ->
    super(uid, func)

  toString: ->
    "ProjAn(#{@__uid})"


class VarDef
  constructor: (@name, @type, @options={}) ->
    if typeof @type is 'string'
      @type = StandardTypes[@type] || throw new Error "Standard type '#{@type}' does not exist"

    @__uid = @name

    @producingAnalyzers = {}
    @dependentAnalyzers = {}

  addDependentAnalyzer: (analyzer) ->
    log.debug "#{analyzer} depends on #{this}"
    @dependentAnalyzers[analyzer.__uid] = analyzer

  toString: ->
    "VarDef(#{@name})"


class AnalyzerSchema
  constructor: ->
    @fileVarDefs = []
    @projectVarDefs = []
    @namesToVarDefs = {}
    @fileAnalyzers = []
    @projectAnalyzers = []
    @uidsInUse = {}

  addProjectVarDef: (name, type, options={}) ->
    varDef = new VarDef(name, type, options)
    @projectVarDefs.push varDef
    @namesToVarDefs[varDef.name] = varDef

  addFileVarDef: (name, type, options={}) ->
    varDef = new VarDef(name, type, options)
    @fileVarDefs.push varDef
    @namesToVarDefs[varDef.name] = varDef

  _ensureUniqueUid: (analyzer) ->
    uid = analyzer.__uid

    nextSuffix = 2
    suffix = ''
    while @uidsInUse.hasOwnProperty(uid + suffix)
      suffix = '_' + (nextSuffix++)

    analyzer.__uid = uid + suffix
    @uidsInUse[uid] = yes

    return analyzer


  addProjectAnalyzer: (uid, func) ->
    @projectAnalyzers.push @_ensureUniqueUid(new ProjectAnalyzer(uid, func))

  addFileAnalyzer: (uid, pathList, func) ->
    @fileAnalyzers.push @_ensureUniqueUid(new FileAnalyzer(uid, func, pathList))

  varDefNamed: (name) ->
    @namesToVarDefs[name] || throw new Error("File/project analysis variable '#{name}' is not defined")


class AnalyzeFileJob extends Job

  constructor: (@fileData) ->
    super [@fileData.projectData.project.id, @fileData.path]

  merge: (sibling) ->

  execute: (callback) ->
    LR.queue.add new SaveAnalysisResultsJob(@fileData.projectData)
    # follow the schema order -- it will be manipulated in the future
    # (or perhaps not, but predictability and repeatability are nice to have anyway)
    while @executeOneIteration()
      42
    callback(null)

  executeOneIteration: ->
    for analyzer in @fileData.projectData.schema.fileAnalyzers
      if dataSource = @fileData.analyzerIdToDataSource[analyzer.__uid]
        log.debug "AnalyzeFileJob running '#{analyzer}' on #{@fileData}"
        if dataSource.validate()
          return yes
    return no

class AnalyzeProjectJob extends Job

  constructor: (@dataSource) ->
    super [@dataSource.data.project.id, @dataSource.analyzer.__uid]

  merge: (sibling) ->

  execute: (callback) ->
    LR.queue.add new SaveAnalysisResultsJob(@dataSource.data)
    @dataSource.validate()
    callback(null)

class SaveAnalysisResultsJob extends Job

  constructor: (@projectData) ->
    super @projectData.id

  merge: (sibling) ->

  execute: (callback) ->
    dump = { projectVars: {}, fileVars: {} }
    for own varName, theVar of @projectData.namesToVars
      dump.projectVars[varName] = theVar.get()
    for own path, fileData of @projectData.pathToFileData
      fileDump = dump.fileVars[path] = {}
      for own varName, theVar of fileData.namesToVars
        fileDump[varName] = theVar.get()

    require('fs').writeFileSync "/tmp/LR-analysis-#{@projectData.id}", JSON.stringify(dump, null, 2)

    callback(null)


class DataSource
  constructor: (@analyzer, @data) ->
    @valid = no
    @schedule()

  invalidate: ->
    log.debug "#{this} invalidated"
    @valid = no
    @schedule()

  validate: ->
    return no if @valid
    @valid = yes

    varNameToPieces = {}

    R.withContext this, =>
      @analyze (varName, piece) =>
        (varNameToPieces[varName] ||= []).push piece

    # add any first-time vars to the list of output vars
    for varName in Object.keys(varNameToPieces) when !(varName of @analyzer.outputVars)
      @analyzer.addOutputVar @data.varNamed(varName).def

    # update all output vars (even if we didn't emit a value for a certain var now, we could've done so on the previous iteration)
    for varName in Object.keys(@analyzer.outputVars)
      @data.varNamed(varName).update @sourceId(), varNameToPieces[varName] || []

    return yes

class FileDataSource extends DataSource
  schedule: ->
    LR.queue.add new AnalyzeFileJob(@data)

  analyze: (emit) ->
    @analyzer.func @data.projectData, @data, emit

  sourceId: ->
    # for file vars @analyzer.__uid alone is enough; full path is needed for project vars
    "#{@data.path}-#{@analyzer.__uid}"

  toString: ->
    "FileDS(#{@data})"


class ProjectDataSource extends DataSource
  schedule: ->
    LR.queue.add new AnalyzeProjectJob(this)

  analyze: (emit) ->
    @analyzer.func @data, emit

  sourceId: ->
    @analyzer.__uid

  toString: ->
    "ProjDS(#{@data})"


class DataVar
  constructor: (@data, @def) ->
    @value = new (@def.type)

  get: ->
    if R.context instanceof DataSource
      @def.addDependentAnalyzer R.context.analyzer
    return @value.get()

  update: (sourceId, pieces) ->
    if @value.update(sourceId, pieces)
      @invalidate()

  invalidate: ->
    log.debug "#{this} updated, invalidating analyzers"
    for own _, analyzer of @def.dependentAnalyzers
      @data.invalidateDataContributedByAnalyzer analyzer.__uid

  toString: ->
    "Var(#{@data}.#{@def.name})"


class Data
  constructor: (analyzers, varDefs, SpecificDataSource) ->
    @analyzerIdToDataSource = {}
    for analyzer in analyzers
      @analyzerIdToDataSource[analyzer.__uid] = new SpecificDataSource(analyzer, this)

    @namesToVars = {}
    for varDef in varDefs
      theVar = @namesToVars[varDef.name] = new DataVar(this, varDef)
      Object.defineProperty this, varDef.name, get: theVar.get.bind(theVar)


class FileData extends Data
  constructor: (@projectData, @path) ->
    super(@projectData.schema.fileAnalyzers.filter((a) => a.pathList.matches(@path)), @projectData.schema.fileVarDefs, FileDataSource)

  varNamed: (name) ->
    @projectData.namesToVars[name] || @namesToVars[name] || throw new Error "File/project variable '#{name}' is not defined"

  invalidate: ->
    for own _, analyzer of @analyzerIdToDataSource
      analyzer.invalidate()
    return

  invalidateDataContributedByAnalyzer: (analyzerId) ->
    if dataSource = @analyzerIdToDataSource[analyzerId] || @projectData.analyzerIdToDataSource[analyzerId]
      dataSource.invalidate()
    else
      throw new Error "Don't know how to invalidate analyzer #{analyzerId}"

  toString: ->
    "FileD(#{@path} in #{@projectData.id})"


class ProjectData extends Data
  constructor: (@project, @schema, @tree) ->
    super(@schema.projectAnalyzers, @schema.projectVarDefs, ProjectDataSource)
    @id = @project.id
    @pathToFileData = {}

    list = RelPathList.union.apply(RelPathList, (analyzer.pathList for analyzer in @schema.fileAnalyzers))
    @treeQuery = @tree.createQuery(list)
    @treeQuery.subscribe(@id, this)
    @dependencyChanged(@treeQuery, null)

  dependencyChanged: (sender, path) ->
    if path?
      @updateFile path
    else
      for path in sender.result
        @updateFile path

  varNamed: (name) ->
    @namesToVars[name] || throw new Error "Project variable '#{name}' is not defined"

  file: (path, create=no) ->
    if create
      @pathToFileData[path] ||= new FileData(this, path)
    else
      @pathToFileData[path]

  invalidateDataContributedByAnalyzer: (analyzerId) ->
    if dataSource = @analyzerIdToDataSource[analyzerId]
      dataSource.invalidate()
    else
      for own _, fileData of @pathToFileData
        fileData.analyzerIdToDataSource[analyzerId]?.invalidate()
    return

  updateFile: (path) ->
    @file(path, yes).invalidate()

  toString: ->
    "ProjD(#{@id})"


AnalysisEngine = ProjectData
AnalysisEngine.Schema = AnalyzerSchema
module.exports = AnalysisEngine
