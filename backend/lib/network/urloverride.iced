fs   = require 'fs'
Path = require 'path'
Url  = require 'url'

{ PathAuthenticator } = require './pathauth'

ERR_NOT_MATCHED    = 'not-matched'
ERR_FILE_NOT_FOUND = 'file-not-found'
ERR_AUTH_FAILED    = 'auth-failed'


class FileType
  constructor: ->
    @overridable = no
    @mime = "application/octet-stream"

class CSSFileType
  constructor: ->
    @overridable = yes
    @mime = "text/css"
    @isCSS = yes

class ImageFileType
  constructor: (@mime) ->
    @overridable = yes

FileTypeByExtension =
  '.css':  new CSSFileType()
  '.png':  new ImageFileType('image/png')
  '.jpg':  new ImageFileType('image/jpg')
  '.jpeg': new ImageFileType('image/jpg')
  '.gif':  new ImageFileType('image/gif')

lookupFileType = (path) ->
  ext = Path.extname(path)
  FileTypeByExtension[ext] ? new FileType()


CSS_IMPORT_RE = ///
  # capture 1: before file name
  (
    url    \s*
    \(     \s*?
    ['"]?
  )
  # capture 2: file name
  (
    [^)'"]*
  )
  # capture 3: after file name
  (
    ['"]?  \s*?
    \)
  )
///g


class URLOverrideCoordinator

  constructor: ->
    @authenticator = new PathAuthenticator()
    @fs   = require('fs')
    @Path = require('path')

  shouldOverrideFile: (path) ->
    lookupFileType(path).overridable

  createOverrideURL: (path) ->
    @authenticator.urlPathForServingLocalPath(path)

  handleHttpRequest: (url, callback) ->
    [errCode, localPath] = @authenticator.localPathForUrlPath(url.pathname)

    return callback(ERR_NOT_MATCHED)    if errCode is 404
    return callback(ERR_AUTH_FAILED)    if errCode is 403
    return callback(errCode)            if errCode isnt 200

    await @Path.exists(localPath, defer exists)
    return callback(ERR_FILE_NOT_FOUND) unless exists

    baseUrl  = url.query?.url
    fileType = lookupFileType(localPath)

    if fileType.isCSS && baseUrl
      await @fs.readFile(localPath, 'utf8', defer(err, content))
      return callback(err) if err

      content = content.replace CSS_IMPORT_RE, (match, prefix, importedURL, suffix) ->
        newURL = Url.resolve(baseUrl, importedURL)
        "#{prefix}#{newURL}#{suffix}"

      content = new Buffer(content)

    else
      await @fs.readFile(localPath, 'utf8', defer(err, content))
      return callback(err) if err

    return callback(null, { mime: fileType.mime, content })


module.exports = { URLOverrideCoordinator, ERR_NOT_MATCHED, ERR_AUTH_FAILED, ERR_FILE_NOT_FOUND }
