
crypto = require 'crypto'

sha1 = (string) -> crypto.createHash('sha1').update(string).digest('hex')

random8  = -> Math.random().toString(36).substr(2,8)
random40 = -> random8() + random8() + random8() + random8() + random8()


class PathAuthenticator

  constructor: ->
    @salt = random40()

  sign: (localPath) ->
    sha1(@salt + localPath)

  urlPathForServingLocalPath: (localPath) ->
    if localPath.length == 0 or localPath[0] != '/'
      throw new Error("urlPathForServingLocalPath: localPath is expected to start with a slash: '#{localPath}'")

    signature = @sign(localPath)
    return  "/_livereload/url-override-v1/#{signature}#{localPath}"

  localPathForUrlPath: (urlPath) ->
    if m = urlPath.match ///^ /_livereload/url-override-v1/ ([a-z0-9]{40}) (/.*) $///
      [_, signature, localPath] = m
      localPath = decodeURI(localPath)
      if @sign(localPath) == signature
        return [200, localPath]
      else
        return [403]
    return [404]

module.exports = { PathAuthenticator }
