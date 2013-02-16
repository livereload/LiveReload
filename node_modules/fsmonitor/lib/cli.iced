{ RelPathList, RelPathSpec } = require 'pathspec'

fsmonitor = require './index'
{ spawn } = require 'child_process'


USAGE = """
Usage: fsmonitor [-d <folder>] [-p] [-s] [-q] [<mask>]... [<command> <arg>...]

Options:
  -d <folder>        Specify the folder to monitor (defaults to the current folder)
  -p                 Print changes to console (default if no command specified)
  -s                 Run the provided command once on start up
  -l                 Display a full list of matched (monitored) files and folders
  -q                 Quiet mode (don't print the initial banner)
  -J <subst>         Replace <subst> in the executed command with the name of the modified file
                     (this also changes how multiple changes are handled; normally, the command
                     is only invoked once per a batch of changes; when -J is specified, the command
                     is invoked once per every modified file)

Masks:
  +<mask>            Include only the files matching the given mask
  !<mask>            Exclude files matching the given mask

  If no inclusion masks are provided, all files not explicitly excluded will be included.

General options:
  --help             Display this message
  --version          Display fsmonitor version number
"""


escapeShellArgForDisplay = (arg) ->
  if arg.match /[ ]/
    if arg.match /[']/
      '"' + arg.replace(/[\\]/g, '\\\\').replace(/["]/g, '\\"') + '"'
    else
      "'#{arg}'"
  else
    arg

displayStringForShellArgs = (args) ->
  (escapeShellArgForDisplay(arg) for arg in args).join(' ')


class FSMonitorTool
  constructor: ->
    @list = new RelPathList()
    @list.include RelPathSpec.parse('**')
    @list2 = new RelPathList()  # alternative list to use if explicit inclusion specs were indeed provided

    @folder = process.cwd()
    @command = []
    @print = no
    @quiet = no
    @prerun = no
    @subst = null
    @listFiles = no

    @_latestChangeForExternalCommand = null
    @_externalCommandRunning = no


  parseCommandLine: (argv) ->
    requiredValue = (arg) ->
      if argv.length is 0
        process.stderr.write " *** Missing required value for #{arg}.\n"
        process.exit(13)
      return argv.shift()

    while (arg = argv.shift())?
      break if arg is '--'

      if arg.match /^--/
        switch arg
          when '--help'
            process.stdout.write USAGE.trim() + "\n"
            process.exit(0)
          when '--version'
            process.stdout.write "#{fsmonitor.version}\n"
            process.exit(0)
          else
            process.stderr.write " *** Unknown option: #{arg}.\n"
            process.exit(13)
      else if arg.match /^-./
        if arg.match /^-[dJ]./
          argv.unshift arg.substr(2)
          arg = arg.substr(0, 2)

        switch arg
          when '-d'
            @folder = requiredValue()
          when '-J'
            @subst = requiredValue()
          when '-p'
            @print = yes
          when '-s'
            @prerun = yes
          when '-q'
            @quiet = yes
          when '-l'
            @listFiles = yes
          else
            process.stderr.write " *** Unknown option: #{arg}.\n"
            process.exit(13)
      else
        if arg.match /^!/
          spec = RelPathSpec.parseGitStyleSpec(arg.slice(1))
          @list.exclude spec
          @list2?.exclude spec
        else if arg.match /^[+]/
          spec = RelPathSpec.parseGitStyleSpec(arg.slice(1))
          if @list2
            @list = @list2
            @list2 = null
          @list.include spec
        else
          argv.unshift(arg)
          break

    @command = argv
    @print = yes  if @command.length is 0


  printOptions: ->
    if @command.length > 0
      action = displayStringForShellArgs(@command)
    else
      action = '<print to console>'

    folderStr = @folder.replace(process.env.HOME, '~')

    process.stderr.write "\n"
    process.stderr.write "Monitoring:  #{folderStr}\n"
    process.stderr.write "    filter:  #{@list}\n"
    process.stderr.write "    action:  #{action}\n"
    process.stderr.write "     subst:  #{@subst}\n" if @subst
    process.stderr.write "\n"


  startMonitoring: ->
    watcher = fsmonitor.watch(@folder, @list, @handleChange.bind(@))
    watcher.on 'complete', =>
      if @listFiles
        for file in watcher.tree.allFiles
          process.stdout.write "#{file}\n"
        for folder in watcher.tree.allFolders
          process.stdout.write "#{folder}/\n"
        process.exit()
      process.stderr.write "..."  unless @quiet


  handleChange: (change) ->
    @printChange(change)              if @print
    @executeCommandForChange(change)  if @command.length > 0


  printChange: (change) ->
    str = change.toString()
    prefix = "#{Date.now()} "
    if str
      process.stderr.write "\n" + str.trim().split("\n").map((x) -> "#{prefix}#{x}\n").join('')
    else
      process.stderr.write "\n#{prefix} <empty change>\n"


  executeCommandForChange: (change) ->
    if @_latestChangeForExternalCommand
      @_latestChangeForExternalCommand.append change
    else
      @_latestChangeForExternalCommand = change
    @_scheduleExternalCommandExecution()

  _scheduleExternalCommandExecution: ->
    if @_latestChangeForExternalCommand and not @_externalCommandRunning
      process.nextTick =>
        change = @_latestChangeForExternalCommand
        @_latestChangeForExternalCommand = null

        @_externalCommandRunning = yes

        if @subst
          files = change.addedFiles.concat(change.modifiedFiles)
          for file in files
            command = (arg.replace(@subst, file) for arg in @command)
            await @_invokeExternalCommand command, defer()
        else
          await @_invokeExternalCommand @command, defer()

        process.stderr.write "\n..."  unless @quiet

        @_externalCommandRunning = no
        @_scheduleExternalCommandExecution()  # execute again if any more changes came in

  _invokeExternalCommand: (command, callback) ->
    process.stderr.write "\r#{displayStringForShellArgs(command)}\n"  unless @quiet
    child = spawn(command[0], command.slice(1), stdio: 'inherit')

    child.on 'exit', callback


exports.run = (argv) ->
  app = new FSMonitorTool()
  app.parseCommandLine(argv)
  app.startMonitoring()
  app.executeCommandForChange({}) if app.prerun
  app.printOptions() unless app.quiet
