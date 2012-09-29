{ ok, equal, deepEqual } = require 'assert'
CommandLineTool = require '../lib/tools/cmdline'
MessageParser   = require '../lib/messages/parser'

describe "CommandLineTool", ->

  it "should be able to run 'ls'", (done) ->
    parser = new MessageParser {
      warnings: [
        "((message:usr.*?))\n"
      ]
    }
    tool = new CommandLineTool name: 'ls', args: ['ls', '-1$(style)'], cwd: '$(project)', parser: parser
    invocation = tool.createInvocation({ "$(project)": '/', "$(style)": 'F' })

    await
      invocation.once 'finished', defer()
      invocation.run()

    deepEqual invocation.messages, [{ type: 'warning', message: 'usr/' }]
    done()
