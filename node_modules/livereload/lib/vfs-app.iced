{LocalVFS} = require 'vfs-local'

class AppVFS extends LocalVFS

  constructor: (@C) ->

  findFilesMatchingSuffixInSubtree: (root, suffix, bestSubtree, callback) ->
    LR.client.project.pathOfBestFileMatchingPathSuffix { project: root, suffix }, (err, resp) ->
      if err
        return callback err
      if resp.err
        return callback new Error(resp.err)

      if resp.found
        match = { score: 1, path: resp.file }
        return callback null, { allMatches: [match], bestMatches: [match], bestMatch: match }
      else
        return callback null, { allMatches: [], bestMatches: [], bestMatch: null }

module.exports = AppVFS
