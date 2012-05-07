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

    LR.queue = new Job.Queue ['RunAnalyzerJob']
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
    done()
