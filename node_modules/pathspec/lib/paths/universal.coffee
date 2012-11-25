{ addTrailingSlash, addLeadingSlash, removeTrailingSlash, removeLeadingSlash } = require '../pathutil'
AbsPath = require './absolute'
RelPath = require './relative'


# AbsPath or RelPath
module.exports = UniPath =
  normalize: (path) ->
    path
