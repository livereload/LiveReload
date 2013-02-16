debug   = require('debug')('livereload:cli')
_       = require 'underscore'
R       = require('livereload-core').R


module.exports =
class Stats extends R.Model

  schema:
    connectionCount:          { type: 'int' }
    changes:                  { type: 'int' }
    compilations:             { type: 'int' }
    refreshes:                { type: 'int' }
