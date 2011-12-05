fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
util = require 'util'
plist = require 'plist'
async = require 'async'
require 'sugar'

{ PluginManager } = require '../lib/plugin'

data = yaml.load(fs.readFileSync(path.join(__dirname, 'unparsable_logs.yml'), 'utf8'))
groupedRecords = Object.values(data.groupBy('compiler'))

divider = "------------------------------------------------------------"

outputFolder = path.join(__dirname, 'reports')

formatRecs = (recs) -> recs.map((r) -> "#{r.output || ''}\n\n" + r.body.replace(/\s*$/, '') + "\n").join("\n#{divider}\n\n")

processAllLogs = (pluginManager, callback) ->
  async.forEach groupedRecords, (recs, callback) ->
    name = recs[0].compiler
    compiler = pluginManager.compilers[name]

    folderPath = compiler.plugin.folder

    try
      messages = fs.readFileSync("#{folderPath}/messages.txt", 'utf-8').split(divider).map (m) -> m.trim()
    catch e
      messages = []

    plist.parseFile "#{folderPath}/Info.plist", (err, obj) ->
      return callback(err) if err

      parser = compiler.parser

      recs = ({ body: m } for m in messages).concat(recs)
      for rec in recs
        rec.output = parser.parse(rec.body)
        rec.matched = rec.output.parsed

      unparsed = recs.findAll (r) -> !r.matched
      parsed   = recs.findAll (r) -> r.matched

      console.log name, unparsed.length

      recsText = recs.map((r) -> r.body.replace(/\s*$/, '') + "\n").join("\n#{divider}\n\n")
      if unparsed.length
        fs.writeFileSync("#{outputFolder}/#{name}-bad.txt", formatRecs(unparsed))
      else
        try fs.unlinkSync("#{outputFolder}/#{name}-bad.txt") catch e
      fs.writeFileSync("#{outputFolder}/#{name}-ok.txt", formatRecs(parsed))
      fs.writeFileSync("#{outputFolder}/#{name}-formats.txt", JSON.stringify(parser.errorFormats.findAll((f) -> !f.used), null, 2))

      callback()

  , (err) ->


pluginManager = new PluginManager([path.join(__dirname, "../../LiveReload/Compilers")])
pluginManager.rescan (err) ->
  processAllLogs pluginManager, (err) ->
    console.log "DONE."
