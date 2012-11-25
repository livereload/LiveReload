{ addTrailingSlash, addLeadingSlash, removeTrailingSlash, removeLeadingSlash } = require '../pathutil'


# foo/bar/boz
module.exports = PlaPath =
  normalize: (path) ->
    removeLeadingSlash(path)

  isSubpath: (subpath, superpath) ->
    if superpath == subpath
      return yes
    else
      superpath = addTrailingSlash(superpath)
      return subpath.substr(0, superpath.length) == superpath

  numberOfMatchingTrailingComponents: (path1, path2) ->
    components1 = path1.split '/'
    components2 = path2.split '/'

    len1 = components1.length
    len2 = components2.length
    len  = Math.min(len1, len2)

    common = 0
    common++ while (common < len) and components1[len1 - common - 1] == components2[len2 - common - 1]

    return common
