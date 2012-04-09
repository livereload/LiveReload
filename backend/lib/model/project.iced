
nextProjectId = 1

class Project
  constructor: (memento={}) ->
    @path = memento.path
    @id   = "P#{nextProjectId++}"
    @name = Path.basename(@path)
    LR.client.monitoring.add({ @id, @path })

  dispose: ->
    LR.client.monitoring.remove({ @id })

  toJSON: ->
    { @id, @name, @path }

  toMemento: ->
    { @path }

  handleChange: (paths, callback) ->
    LR.log.fyi "change detected in #{@path}: #{JSON.stringify(paths)}\n"
    for path in paths
      LR.websockets.sendReloadCommand { path }
    callback(null)

module.exports = { Project }
