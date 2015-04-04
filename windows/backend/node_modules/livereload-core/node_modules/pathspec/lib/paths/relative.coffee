{ addTrailingSlash, addLeadingSlash, removeTrailingSlash, removeLeadingSlash } = require '../pathutil'


# ./foo/bar/boz
module.exports = RelPath =
  normalize: (path) ->
    path
