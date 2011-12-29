G         = require './granularities'
Hierarchy = require './hierarchy'

exports.run = (options, sourceGroup, destinationGroup, func) ->
  console.log "Options: " + JSON.stringify(options)

  srcG = G[sourceGroup.granularity]
  dstG = G[destinationGroup.granularity]

  options.since &&= dstG.first(srcG, G.day.outer(dstG, options.since))
  options.until &&= dstG .last(srcG, G.day.outer(dstG, options.until))

  console.log "Options: " + JSON.stringify(options)

  console.time 'total'

  execute = (dstperiod, sources, srctimestamp) ->
    dstfile = destinationGroup.file(dstperiod)

    if options.force or srctimestamp > dstfile.timestamp()
      console.log  "#{dstfile.name}"
      console.time " -> total"

      console.time " -> read"
      data =
        for file in sources
          console.time " -> read #{file.name}"    if options.showSources
          stats = file.readSync()
          if file.group.levels > 0
            stats = Hierarchy(stats, file.group.levels)
          console.timeEnd " -> read #{file.name}" if options.showSources
          { stats, period: file.id }
      console.timeEnd " -> read"

      console.time " -> computation"
      if srcG == dstG
        [{ period, stats }] = data
        if period != dstperiod
          throw new Error("Internal error: for srcG == dstG, srcperiod != dstperiod")
        result = func(dstperiod, stats)
      else
        result = func(dstperiod, data)
      console.timeEnd " -> computation"

      unless result instanceof Hierarchy
        throw new Error("Processing function returned something which is not a Hierarchy: #{typeof result} #{JSON.stringify(result)}")

      console.time " -> write"
      dstfile.writeSync(result)
      console.timeEnd " -> write"

      console.timeEnd " -> total"

    else
      fileNames = (file.name for file in sources).join(", ")
      if options.showSources
        console.log "#{dstfile.name}: unchanged (source files: #{fileNames})"
      else
        console.log "#{dstfile.name}: unchanged"

  Queue =
    sources:    []
    period:     null
    timestamp:  0

    prepare: (period) ->
      if @period != period
        if @period
          # console.log "flushing #{@period} with #{@sources.length} sources"
          execute @period, @sources, @timestamp

# .id, file.readSync(), file.timestamp()
        @period    = period
        @sources   = []
        @timestamp = 0

    flush: -> @prepare(null)

    add: (file) ->
      # console.log "enqueued: #{file.id}"
      @prepare srcG.outer(dstG, file.id)
      @sources.push file
      @timestamp = Math.max(@timestamp, file.timestamp())


  do ->
    for file in sourceGroup.allFiles()
      # console.log "source: #{file.id}"
      continue if options.since && srcG.lt(file.id, options.since)
      continue if options.until && srcG.gt(file.id, options.until)

      Queue.add file

  Queue.flush()

  console.timeEnd 'total'
