assert = require 'assert'
AnalysisEngine = require '../../lib/model/analyzer'
FSTree = require '../../lib/vfs/fstree'
FSGroup = require '../../lib/vfs/fsgroup'
Job = require '../../lib/app/jobs'


class Helper
  constructor: (schemaBuilder) ->
    @log = []

    @fakeProject =
      id: "fakeproj"

    LR.queue = new Job.Queue ['AnalyzeFileJob', 'AnalyzeProjectJob']
    LR.queue.verbose = yes

    @sassSources = FSGroup.parse("*.sass")

    @schema = new AnalysisEngine.Schema
    schemaBuilder.call(this, @schema)

    @tree = new FSTree()

    @engine = new AnalysisEngine(@fakeProject, @schema, @tree)



describe "Analysis Framework", ->

  it "should run a single file analyzer", (done) ->
    helper = new Helper (schema) ->
      schema.addFileVarDef 'imports', 'list'

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
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
    helper = new Helper (schema) ->
      schema.addFileVarDef 'imports', 'list'
      schema.addFileVarDef 'something', 'list'

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
        helper.log.push "first(#{file.path})"
        for path in file.imports
          emit 'something', "#{path}/boz.txt"

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
        helper.log.push "second(#{file.path})"
        emit 'imports', 'another.sass'

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "first(foo.sass) second(foo.sass) first(foo.sass)"
    assert.equal JSON.stringify(helper.engine.file('foo.sass').imports), JSON.stringify(['another.sass'])
    assert.equal JSON.stringify(helper.engine.file('foo.sass').something), JSON.stringify(['another.sass/boz.txt'])
    done()


  it "should run a single project analyzer", (done) ->
    helper = new Helper (schema) ->
      schema.addProjectVarDef 'compilers', 'list'

      schema.addProjectAnalyzer (project, emit) ->
        helper.log.push "analyze(#{project.id})"
        emit 'compilers', 'SASS'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "analyze(fakeproj)"
    assert.equal JSON.stringify(Object.keys(helper.schema.projectAnalyzers[0].outputVars).sort()), JSON.stringify(['compilers'])
    assert.equal JSON.stringify(helper.engine.compilers), JSON.stringify(['SASS'])
    done()


  it "should update analysis results when file changes", (done) ->
    _value = 'one.sass'
    helper = new Helper (schema) ->
      schema.addFileVarDef 'imports', 'list'

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
        helper.log.push "analyze(#{file.path})"
        emit 'imports', _value

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "analyze(foo.sass)"
    assert.equal JSON.stringify(helper.engine.file('foo.sass').imports), JSON.stringify(['one.sass'])

    helper.log.push "change"
    _value = 'another.sass'

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "analyze(foo.sass) change analyze(foo.sass)"
    assert.equal JSON.stringify(helper.engine.file('foo.sass').imports), JSON.stringify(['another.sass'])
    done()


  it "should run an interdependent system of file -> project -> file analyzers", (done) ->
    helper = new Helper (schema) ->
      schema.addProjectVarDef 'imports', 'list'
      schema.addProjectVarDef 'compilers', 'list'
      schema.addFileVarDef 'compassMixins', 'list'

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
        helper.log.push "f2(#{file.path})"
        if 'Compass' in project.compilers
          emit 'compassMixins', 'background-with-css2-fallback'
          emit 'compassMixins', 'blueprint-reset'

      schema.addFileAnalyzer @sassSources, (project, file, emit) ->
        helper.log.push "f1(#{file.path})"
        emit 'imports', 'compass/reset'

      schema.addProjectAnalyzer (project, emit) ->
        helper.log.push "p(#{project.id})"
        for path in project.imports
          if path.startsWith 'compass'
            emit 'compilers', 'Compass'

    helper.tree.touch 'foo.sass'
    helper.engine.updateFile 'foo.sass'

    await LR.queue.once 'empty', defer()
    assert.equal helper.log.join(" "), "f2(foo.sass) f1(foo.sass) p(fakeproj) f2(foo.sass)"
    assert.equal JSON.stringify(helper.engine.compilers), JSON.stringify(['Compass'])
    assert.equal JSON.stringify(helper.engine.imports), JSON.stringify(['compass/reset'])
    assert.equal JSON.stringify(helper.engine.file('foo.sass').compassMixins), JSON.stringify(['background-with-css2-fallback', 'blueprint-reset'])
    done()
