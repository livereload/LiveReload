# debug = require('debug')('livereload:core:compass')

exports.apiVersion = 1

exports.create = (project) ->
  locations = ['config/compass.rb', 'compass/config.rb', 'config/compass.config', 'config.rb', 'src/config.rb']

  locations.forEach (location) ->

    project.tree.filter(location).forEach (file) ->
      isCompass = file.content.match /compass plugins|^preferred_syntax = :(sass|scss)/m
      return unless isCompass

      project.emit {
        'compass.rootDir': file.grandparent(location.split('/').length)
      }, {
        reason: "Detected Compass configuration file at #{file.relpath}"
      }

comap
