R = require '../reactive'
Job = require '../app/jobs'

_nextId = 1


class ListVarType

  constructor: ->
    @sourceIdToItems = {}

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



StandardTypes =
  list: ListVarType


class Analyzer
  constructor: (@func) ->
    R.hook this
    @outputVars = {}

  addOutputVar: (varDef) ->
    @outputVars[varDef.__uid] = varDef
    varDef.producingAnalyzers[this.__uid] = this

class FileAnalyzer extends Analyzer
  constructor: (func, @fileGroup) ->
    super(func)

class ProjectAnalyzer extends Analyzer
  constructor: (func) ->
    super(func)


class VarDef
  constructor: (@name, @type, @options={}) ->
    if typeof @type is 'string'
      @type = StandardTypes[@type] || throw new Error "Standard type '#{@type}' does not exist"

    @__uid = @name

    @producingAnalyzers = {}
    @dependentAnalyzers = {}

  addDependentAnalyzer: (analyzer) ->
    @dependentAnalyzers[analyzer.__uid] = analyzer


class AnalyzerSchema
  constructor: ->
    @fileVarDefs = []
    @projectVarDefs = []
    @namesToVarDefs = {}
    @fileAnalyzers = []
    @projectAnalyzers = []

  addProjectVarDef: (name, type, options={}) ->
    varDef = new VarDef(name, type, options)
    @projectVarDefs.push varDef
    @namesToVarDefs[varDef.name] = varDef

  addFileVarDef: (name, type, options={}) ->
    varDef = new VarDef(name, type, options)
    @fileVarDefs.push varDef
    @namesToVarDefs[varDef.name] = varDef

  addProjectAnalyzer: (func) ->
    @projectAnalyzers.push new ProjectAnalyzer(func)

  addFileAnalyzer: (fileGroup, func) ->
    @fileAnalyzers.push new FileAnalyzer(func, fileGroup)

  varDefNamed: (name) ->
    @namesToVarDefs[name] || throw new Error("File/project analysis variable '#{name}' is not defined")


class AnalyzeFileJob extends Job

  constructor: (@fileData) ->
    super [@fileData.projectData.project.id, @fileData.path]

  merge: (sibling) ->

  execute: (callback) ->
    # follow the schema order -- it will be manipulated in the future
    # (or perhaps not, but predictability and repeatability are nice to have anyway)
    while @executeOneIteration()
      42
    callback(null)

  executeOneIteration: ->
    for analyzer in @fileData.projectData.schema.fileAnalyzers
      if dataSource = @fileData.analyzerIdToDataSource[analyzer.__uid]
        if dataSource.validate()
          return yes
    return no

class AnalyzeProjectJob extends Job

  constructor: (@dataSource) ->
    super [@dataSource.data.project.id, @dataSource.analyzer.__uid]

  merge: (sibling) ->

  execute: (callback) ->
    @dataSource.validate()
    callback(null)


class DataSource
  constructor: (@analyzer, @data) ->
    @valid = no
    @schedule()

  invalidate: ->
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
      @data.varNamed(varName).update @analyzer.__uid, varNameToPieces[varName] || []

    return yes

class FileDataSource extends DataSource
  schedule: ->
    LR.queue.add new AnalyzeFileJob(@data)

  analyze: (emit) ->
    @analyzer.func @data.projectData, @data, emit

class ProjectDataSource extends DataSource
  schedule: ->
    LR.queue.add new AnalyzeProjectJob(this)

  analyze: (emit) ->
    @analyzer.func @data, emit


class DataVar
  constructor: (@data, @def) ->
    @value = new (@def.type)

  get: ->
    if R.context instanceof DataSource
      @def.addDependentAnalyzer R.context.analyzer
    return @value.get()

  update: (analyzerId, pieces) ->
    if @value.update(analyzerId, pieces)
      @invalidate()

  invalidate: ->
    for own _, analyzer of @def.dependentAnalyzers
      if dependentDataSource = @data.analyzerIdToDataSource[analyzer.__uid]
        dependentDataSource.invalidate()


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
    super(@projectData.schema.fileAnalyzers.filter((a) => a.fileGroup.contains(@path)), @projectData.schema.fileVarDefs, FileDataSource)

  varNamed: (name) ->
    @projectData.namesToVars[name] || @namesToVars[name] || throw new Error "File/project variable '#{name}' is not defined"


class ProjectData extends Data
  constructor: (@project, @schema, @tree) ->
    super(@schema.projectAnalyzers, @schema.projectVarDefs, ProjectDataSource)
    @id = @project.id
    @pathToFileData = {}

  varNamed: (name) ->
    @namesToVars[name] || throw new Error "Project variable '#{name}' is not defined"

  file: (path) ->
    @pathToFileData[path]

  updateFile: (path) ->
    fileData = (@pathToFileData[path] ||= new FileData(this, path))


AnalysisEngine = ProjectData
AnalysisEngine.Schema = AnalyzerSchema
module.exports = AnalysisEngine
