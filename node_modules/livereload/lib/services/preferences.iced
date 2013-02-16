Path = require 'path'
fs   = require 'fs'


class PreferenceCategory
  constructor: (@preferences, @name) ->
    @path = Path.join(@preferences.path, "#{@name}.json")
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
      @savingTimer = setTimeout((=> @savingTimer = null; @saveNow()), @preferences._savingDelay)

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


module.exports =
class LRPreferences

  constructor: (@path) ->
    @_categories  = {}
    @_savingDelay = 100

  setTestingOptions: ({ @_savingDelay }) ->

  setDefault: (key, value) ->
    [category, subkey] = @_split(key)
    category.setDefault subkey, value

  set: (key, value, callback=(->)) ->
    [category, subkey] = @_split(key)
    category.set subkey, value, callback

  get: (key, callback) ->
    [category, subkey] = @_split(key)
    category.get subkey, callback

  _split: (key) ->
    [categoryName, subkey...] = key.split('.')
    subkey = subkey.join('.')

    category = (@_categories[categoryName] or= new PreferenceCategory(this, categoryName))
    return [category, subkey]
