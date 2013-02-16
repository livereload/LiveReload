FSMonitor = require './monitor'


# Creates and returns a new FSMonitor object with the given `root` and `options`, adding the
# given `listener` (if any) to the `change` event.
exports.watch = (root, filter, options, listener) ->
  if typeof options is 'function'
    listener = options
    options = {}

  monitor = new FSMonitor(root, filter, options)
  monitor.on('change', listener) if listener

  return monitor


exports.version = '0.1.0'
