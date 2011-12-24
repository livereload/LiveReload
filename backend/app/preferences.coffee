
Path = require 'path'
fs   = require 'fs'

_categories = {}
_path = {}
_savingDelay = 100

class PreferenceCategory
  constructor: (@name) ->
    @path = Path.join(_path, "#{@name}.json")
    @data = null
    @savingTimer = null
    @defaults = {}
    @loadCallbacks = []

  doLoad: ->
    fs.readFile @path, 'utf8', (err, raw) =>
      if err || !raw
        @data = {}
      else
        try
          @data = JSON.parse(raw)
        catch e
          LR.log.wtf "Failed to parse preference file #{@path}"
      [callbacks, @loadCallbacks] = [@loadCallbacks, null]
      for callback in callbacks
        callback()
      return

  load: (callback) ->
    if not @loadCallbacks
      return callback()

    @loadCallbacks.push(callback)
    if @loadCallbacks.length is 1
      @doLoad()

  saveNow: ->
    fs.writeFile @path, JSON.stringify(@data, null, 2), 'utf8', (err) =>
      if err
        LR.log.wtf "Failed to save preferences file #{@path}"

  save: ->
    unless @savingTimer
      @savingTimer = setTimeout((=> @savingTimer = null; @saveNow()), _savingDelay)

  get: (subkey, callback) ->
    @load =>
      if subkey
        if @data.hasOwnProperty(subkey)
          callback @data[subkey]
        else
          callback @defaults[subkey]
      else
        callback @data

  set: (subkey, value, callback) ->
    @load =>
      if subkey
        if @defaults.hasOwnProperty(subkey) && @defaults[subkey] == value
          delete @data[subkey]
        else
          @data[subkey] = value
      else
        @data = value
      @save()
      callback()

  setDefault: (subkey, value) ->
    @defaults[subkey] = value


split = (key) ->
  [categoryName, subkey...] = key.split('.')
  subkey = subkey.join('.')

  category = (_categories[categoryName] ||= new PreferenceCategory(categoryName))
  return [category, subkey]

nop = ->


exports.init = (path, callback) ->
  _path = path
  callback()

exports.setTestingOptions = ({ savingDelay }) ->
  _savingDelay = savingDelay

exports.setDefault = (key, value) ->
  throw new Error("Preferences not initialized yet") if !_path
  [category, subkey] = split(key)
  category.setDefault subkey, value

exports.set = (key, value, callback=nop) ->
  throw new Error("Preferences not initialized yet") if !_path
  [category, subkey] = split(key)
  category.set subkey, value, callback

exports.get = (key, callback) ->
  throw new Error("Preferences not initialized yet") if !_path
  [category, subkey] = split(key)
  category.get subkey, callback
