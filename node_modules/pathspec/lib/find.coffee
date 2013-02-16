TreeStream = require './treestream'


module.exports = (roots, list, callback) ->
  stream = new TreeStream(list)


  files = []
  stream.on 'file', (file) ->
    files.push(file)

  stream.on 'end', ->
    files.sort()
    callback(files)


  if typeof roots is 'string'
    stream.visit(roots)

  else
    for root in roots
      stream.visit(root)
