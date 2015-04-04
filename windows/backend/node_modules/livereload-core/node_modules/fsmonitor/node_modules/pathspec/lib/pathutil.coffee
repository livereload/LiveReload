
exports.removeTrailingSlash = (path) ->
  if path is '/'
    path
  else if path[path.length - 1] is '/'
    path.substr(0, path.length - 1)
  else
    path

exports.addTrailingSlash = (path) ->
  if path is ''
    path
  else if path[path.length - 1] isnt '/'
    "#{path}/"
  else
    path

exports.removeLeadingSlash = (path) ->
  if path[0] is '/'
    path.substr(1)
  else
    path

exports.addLeadingSlash = (path) ->
  if path[0] isnt '/'
    "/#{path}"
  else
    path
