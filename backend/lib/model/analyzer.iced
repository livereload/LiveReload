R = require '../reactive'
Job = require '../app/jobs'

_nextId = 1


class ListVarType

  defaultValue: -> []

StandardTypes =
  list: new ListVarType()


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


class RunAnalyzerJob extends Job

  constructor: (@dataSource) ->
    super [@dataSource.fileData.projectData.project.id, @dataSource.fileData.path, @dataSource.analyzer.__uid]

  merge: (sibling) ->

  execute: (callback) ->
    @dataSource.validate()
    callback(null)


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
    LR.queue.add new RunAnalyzerJob(this)

  validate: ->
    return no if @valid
    @valid = yes
    R.withContext this, =>
      @varNameToPieces = {}
      @analyzer.func(@fileData.projectData, @fileData, @emit.bind(@))

    return yes


class FileVar
  constructor: (@fileData, @def) ->
    @value = @def.type.defaultValue()

  get: ->
    if R.context instanceof FileDataSource
      if R.context.fileData isnt @fileData
        throw new Error "File analyzers are prohibited from reading variables of other files; analyzer for #{R.context.fileData.path} tried to read #{@def.name} from #{@fileData.path}"
      @def.addDependentAnalyzer R.context.analyzer
    return @value


class FileData
  constructor: (@projectData, @path) ->
    @analyzerIdToFileDataSource = {}

    @namesToVars = {}
    for varDef in @projectData.schema.fileVarDefs
      theVar = @namesToVars[varDef.name] = new FileVar(this, varDef)
      Object.defineProperty this, varDef.name, get: theVar.get.bind(theVar)

  contributionOf: (analyzer) ->
    @analyzerIdToFileDataSource[analyzer.__uid] ||= new FileDataSource(this, analyzer)

  varNamed: (name) ->


class ProjectData
  constructor: (@project, @schema, @tree) ->
    @pathToFileData = {}

  updateFile: (path) ->
    fileData = (@pathToFileData[path] ||= new FileData(this, path))
    for analyzer in @schema.fileAnalyzers
      if analyzer.fileGroup.contains(path)
        fileData.contributionOf(analyzer).schedule()


AnalysisEngine = ProjectData
AnalysisEngine.Schema = AnalyzerSchema
module.exports = AnalysisEngine
