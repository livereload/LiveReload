require 'sugar'

{ Communicator } = require './communicator'

communicator = new Communicator(process.stdin, process.stdout, process.stderr)
communicator.on 'end', -> process.exit(0)
