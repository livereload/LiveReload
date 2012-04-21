
{ MessageParser } = require './tool-output'


class Compiler
  constructor: (@plugin, @manifest) ->
    @name = @manifest.Name
    @id = @name.toLowerCase()
    @parser = new MessageParser(@manifest)
    @enabledByDefault = !@manifest.Optional
    @needsOutputDirectory = (@manifest.NeedsOutputDirectory ? yes)

    @srcExts = (".#{ext}" for ext in @manifest.Extensions)
    @dstExt  = ".#{@manifest.DestinationExtension}"

    @commandLine = @manifest.CommandLine
    @runDirectory = @manifest.RunIn || ''
    @errorFormats = @manifest.Errors
    @expectedOutputDirectoryNames = @manifest.ExpectedOutputDirectories || []

    @importRegExps        = @manifest.ImportRegExps || []
    @defaultImportedExts  = @manifest.DefaultImportedExts || []
    @nonImportedExts      = @manifest.NonImportedExts || []
    @importToFileMappings = @manifest.ImportToFileMappings || ["$(dir)/$(file)"]

    @options = @manifest.Options || []

exports.Compiler = Compiler
