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


class FileAnalyzer extends Analyzer
  constructor: (func, @fileGroup) ->
    super(func)

    @outputVars = {}

  addOutputVar: (varDef) ->
    @outputVars[varDef.__uid] = varDef
    varDef.producingAnalyzers[this.__uid] = this


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
      if dataSource = @fileData.analyzerIdToFileDataSource[analyzer.__uid]
        if dataSource.validate()
          return yes
    return no


class FileDataSource
  constructor: (@fileData, @analyzer) ->
    @varNameToPieces = {}
    @valid = no
    @schedule()

  emit: (varName, piece) ->
    (@varNameToPieces[varName] ||= []).push piece

  invalidate: ->
    @valid = no
    @schedule()

  schedule: ->
    LR.queue.add new AnalyzeFileJob(@fileData)

  validate: ->
    return no if @valid
    @valid = yes

    oldVarNameToPieces = @varNameToPieces
    @varNameToPieces = {}

    R.withContext this, =>
      @analyzer.func(@fileData.projectData, @fileData, @emit.bind(@))

    newVarNames = Object.keys(@varNameToPieces)
    for varName in newVarNames
      @analyzer.addOutputVar @fileData.varNamed(varName).def

    affectedVarNames = Object.keys(oldVarNameToPieces).concat(newVarNames).unique()
    for varName in affectedVarNames
      @fileData.varNamed(varName).update @analyzer.__uid, @varNameToPieces[varName] || []

    return yes


class FileVar
  constructor: (@fileData, @def) ->
    @value = new (@def.type)

  get: ->
    if R.context instanceof FileDataSource
      if R.context.fileData isnt @fileData
        throw new Error "File analyzers are prohibited from reading variables of other files; analyzer for #{R.context.fileData.path} tried to read #{@def.name} from #{@fileData.path}"
      @def.addDependentAnalyzer R.context.analyzer
    return @value.get()

  update: (analyzerId, pieces) ->
    if @value.update(analyzerId, pieces)
      @invalidate()

  invalidate: ->
    for own _, analyzer of @def.dependentAnalyzers
      if dependentDataSource = @fileData.analyzerIdToFileDataSource[analyzer.__uid]
        dependentDataSource.invalidate()


class FileData
  constructor: (@projectData, @path) ->
    @analyzerIdToFileDataSource = {}
    for analyzer in @projectData.schema.fileAnalyzers
      if analyzer.fileGroup.contains(@path)
        @analyzerIdToFileDataSource[analyzer.__uid] = new FileDataSource(this, analyzer)

    @namesToVars = {}
    for varDef in @projectData.schema.fileVarDefs
      theVar = @namesToVars[varDef.name] = new FileVar(this, varDef)
      Object.defineProperty this, varDef.name, get: theVar.get.bind(theVar)

  varNamed: (name) ->
    @namesToVars[name] || throw new Error "Variable '#{name}' is not defined"


class ProjectData
  constructor: (@project, @schema, @tree) ->
    @pathToFileData = {}

  file: (path) ->
    @pathToFileData[path]

  updateFile: (path) ->
    fileData = (@pathToFileData[path] ||= new FileData(this, path))


AnalysisEngine = ProjectData
AnalysisEngine.Schema = AnalyzerSchema
module.exports = AnalysisEngine
