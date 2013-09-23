{ addTrailingSlash, addLeadingSlash, removeTrailingSlash, removeLeadingSlash } = require '../pathutil'


# /foo/bar/boz
module.exports = AbsPath =
  normalize: (path) ->
    addLeadingSlash(path)
