
removeTrailingSlash = (path) ->
  if path is '/'
    path
  else if path[path.length - 1] is '/'
    path.substr(0, path.length - 1)
  else
    path

addTrailingSlash = (path) ->
  if path is ''
    path
  else if path[path.length - 1] isnt '/'
    "#{path}/"
  else
    path

removeLeadingSlash = (path) ->
  if path[0] is '/'
    path.substr(1)
  else
    path

addLeadingSlash = (path) ->
  if path[0] isnt '/'
    "/#{path}"
  else
    path


# foo/bar/boz
PlaPath =
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


# /foo/bar/boz
AbsPath =
  normalize: (path) ->
    addLeadingSlash(path)

# ./foo/bar/boz
RelPath =
  normalize: (path) ->
    path

# AbsPath or RelPath
AnyPath =
  normalize: (path) ->
    path

module.exports = { PlaPath, AbsPath, RelPath, AnyPath }
