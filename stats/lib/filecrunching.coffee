G         = require './granularities'
Hierarchy = require './hierarchy'


withTiming = (message, func) ->
  console.time message if message
  result = func()
  console.timeEnd message if message
  return result


class Job
  constructor: (@period, @outputFile) ->
    @inputFiles = []
    @inputData  = null
    @outputData = null

  addSource: (file) ->
    @inputFiles.push file

  resolve: (timingMessage) ->
    @inputData ||=
      for file in @inputFiles
        withTiming (timingMessage && "#{timingMessage} #{file.name}"), =>
          { stats: file.readSync(), period: file.id }

  resolveOutput: (timingMessage) ->
    @outputData ||=
      withTiming (timingMessage && "#{timingMessage} #{@outputFile.name}"), =>
        @outputFile.readSync()


extractSingleItem = (items) ->
  if items.length != 1
    throw new Error("Assertion error: for srcG == dstG, but multiple items loaded")
  [{ period, stats }] = items
  return stats


exports.run = (options, sourceGroup, destinationGroup, func) ->
  console.log "Options: " + JSON.stringify(options)

  srcG = G[sourceGroup.granularity]
  dstG = G[destinationGroup.granularity]

  options.since &&= dstG.first(srcG, G.day.outer(dstG, options.since))
  options.until &&= dstG .last(srcG, G.day.outer(dstG, options.until))

  console.log "Options: " + JSON.stringify(options)

  console.time 'total'

  execute = (cur, prev) ->
    sourceFiles     = [cur.inputFiles, func.temporalInput && prev?.inputFiles, func.temporalOutput && prev?.outputFile].compact().flatten()
    sourceTimestamp = sourceFiles.map('timestamp').max()

    if options.force or sourceTimestamp > cur.outputFile.timestamp()
      console.log  "#{cur.outputFile.name}"
      console.time " -> total"

      console.time    " -> read"
      curInputData  = cur.resolve(options.showSources && " -> read")
      if func.temporalInput
        prevInputData = prev?.resolve(options.showSources && " -> read previous input")
      if func.temporalOutput
        prevOutputData = prev?.resolveOutput(options.showSources && " -> read previous output #{prev.outputFile.name}")
      console.timeEnd " -> read"

      srcArgWrapper = if srcG == dstG then extractSingleItem else ((items) -> items)

      args = [dstG.wrap(cur.period), srcArgWrapper(curInputData)]
      if func.temporalInput or func.temporalOutput
        args.push prev && dstG.wrap(prev.period)
      if func.temporalInput
        args.push prevInputData && srcArgWrapper(prevInputData)
      if func.temporalOutput
        args.push prevOutputData

      console.time " -> computation"
      outputData = func.apply(null, args)
      console.timeEnd " -> computation"

      unless outputData instanceof Hierarchy
        throw new Error("Processing function returned something which is not a Hierarchy: #{typeof outputData} #{JSON.stringify(outputData)}")

      if func.temporalOutput
        cur.outputData = outputData

      console.time " -> write"
      cur.outputFile.writeSync(outputData)
      console.timeEnd " -> write"

      console.timeEnd " -> total"

    else
      fileNames = sourceFiles.map('name').join(", ")
      if options.showSources
        console.log "#{cur.outputFile.name}: unchanged (source files: #{fileNames})"
      else
        console.log "#{cur.outputFile.name}: unchanged"

  Queue =
    cur:  null
    prev: null

    prepare: (period) ->
      if !@cur || @cur.period != period
        if @cur
          # console.log "flushing #{@period} with #{@sources.length} sources"
          execute @cur, @prev

        @prev = @cur              if func.temporalInput or func.temporalOutput
        @cur  = new Job(period, destinationGroup.file(period))

    flush: -> @prepare(null)

    add: (file) ->
      # console.log "enqueued: #{file.id}"
      @prepare srcG.outer(dstG, file.id)
      @cur.addSource file


  do ->
    for file in sourceGroup.allFiles()
      # console.log "source: #{file.id}"
      continue if options.since && srcG.lt(file.id, options.since)
      continue if options.until && srcG.gt(file.id, options.until)

      Queue.add file

  Queue.flush()

  console.timeEnd 'total'
