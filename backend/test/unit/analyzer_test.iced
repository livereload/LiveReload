assert = require 'assert'
AnalysisEngine = require '../../lib/model/analyzer'
FSTree = require '../../lib/vfs/fstree'
FSGroup = require '../../lib/vfs/fsgroup'
Job = require '../../lib/app/jobs'


class Helper
  constructor: ->
    @log = []

    @fakeProject =
      id: "fakeproj"

    LR.queue = new Job.Queue ['AnalyzeFileJob']
    LR.queue.verbose = yes

    @schema = new AnalysisEngine.Schema

    @sassSources = FSGroup.parse("*.sass")

    @tree = new FSTree()

    @engine = new AnalysisEngine(@fakeProject, @schema, @tree)



describe "Analysis Framework", ->

  it "should run a single file analyzer", (done) ->
    helper = new Helper()
    helper.schema.addFileVarDef 'imports', 'list'

    helper.schema.addFileAnalyzer helper.sassSources, (project, file, emit) ->
      helper.log.push "analyze(#{file.path})"
      emit 'imports', 'another.sass'

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "analyze(foo.sass)"
    assert.equal JSON.stringify(Object.keys(helper.schema.fileAnalyzers[0].outputVars).sort()), JSON.stringify(['imports'])
    assert.equal JSON.stringify(helper.engine.file('foo.sass').imports), JSON.stringify(['another.sass'])
    done()


  it "should run two file analyzers, first one depending on the second one", (done) ->
    helper = new Helper()
    helper.schema.addFileVarDef 'imports', 'list'
    helper.schema.addFileVarDef 'something', 'list'

    helper.schema.addFileAnalyzer helper.sassSources, (project, file, emit) ->
      helper.log.push "first(#{file.path})"
      for path in file.imports
        emit 'something', "#{path}/boz.txt"

    helper.schema.addFileAnalyzer helper.sassSources, (project, file, emit) ->
      helper.log.push "second(#{file.path})"
      emit 'imports', 'another.sass'

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "first(foo.sass) second(foo.sass) first(foo.sass)"
    assert.equal JSON.stringify(helper.engine.file('foo.sass').imports), JSON.stringify(['another.sass'])
    assert.equal JSON.stringify(helper.engine.file('foo.sass').something), JSON.stringify(['another.sass/boz.txt'])
    done()
