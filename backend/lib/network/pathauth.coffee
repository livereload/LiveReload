
crypto = require 'crypto'

random8  = -> Math.random().toString(36).substr(2,8)
random40 = -> random8() + random8() + random8() + random8() + random8()


class PathAuthenticator

  constructor: ->
    @salt = random40()

  sign: (localPath) ->
    crypto.createHmac('sha1', @salt).update(localPath).digest('hex')

  urlPathForServingLocalPath: (localPath) ->
    if localPath.length == 0 or localPath[0] != '/'
      throw new Error("urlPathForServingLocalPath: localPath is expected to start with a slash: '#{localPath}'")

    signature = @sign(localPath)
    LR.log.fyi "urlPathForServingLocalPath: localPath = #{localPath}"
    return  "/_livereload/url-override-v1/#{signature}#{localPath}"

  localPathForUrlPath: (urlPath) ->
    if m = urlPath.match ///^ /_livereload/url-override-v1/ ([a-z0-9]{40}) (/.*) $///
      [_, signature, localPath] = m
      localPath = decodeURI(localPath)
      LR.log.fyi "localPathForUrlPath: localPath = #{localPath}"
      if @sign(localPath) == signature
        return [200, localPath]
      else
        return [403]
    return [404]

module.exports = { PathAuthenticator }
