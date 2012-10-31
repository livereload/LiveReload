debug = require('debug')('livereload:core:compilation')
Path  = require 'path'
{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class CompilationPlugin

  metadata:
    apiVersion: 1
    name: 'livereload-compilation'

  jobPriorities: [
    'compilation'
  ]


  loadProject: (project, memento) ->


  createSteps: (project) ->
    [new CompilationStep(project)]


class CompilationStep

  constructor: (@project) ->
    @id = 'compilation'
    @session = @project.session
    @queue = @project.session.queue


  # LiveReload API

  initialize: () ->
    @queue.register { project: @project.id, action: 'compile' }, @_perform.bind(@)

  schedule: (change) ->
    return unless @_isCompilationActive()
    @queue.add { project: @project.id, action: 'compile', paths: change.paths.slice(0), changes: [change] }


  # internal

  _isCompilationActive: ->
    @project.compilationEnabled

  _perform: (request, done) ->
    return done(null) unless @_isCompilationActive()

    compiled = {}

    for relpath in request.paths
      debug "Looking for compiler for #{relpath}..."
      found = no

      if file = @project.fileAt(relpath)
        if file.compiler and file.outputNameMask
          await @_performCompilation file, defer()
          found = yes

      if found
        compiled[relpath] = yes

    for change in request.changes
      change.pathsToRefresh = (relpath for relpath in change.pathsToRefresh when !compiled.hasOwnProperty(relpath))

    done()


  _performCompilation: (file, callback) ->
    srcInfo = @_fileInfo(file.relpath)
    dstInfo = @_fileInfo(file.destRelPath)

    rubyExecPath =
      if @session.rubies.length > 0
        Path.join(@session.rubies[0].path, "bin", "ruby" + (if process.platform is 'win32' then '.exe' else ''))
      else
        'ruby'

    info =
      '$(project_dir)': @project.fullPath
      '$(ruby)':  rubyExecPath
      '$(node)':  process.execPath

      '$(src_rel_path)': srcInfo.relpath
      '$(src_path)':     srcInfo.path
      '$(src_dir)':      srcInfo.dir
      '$(src_file)':     srcInfo.file

      '$(dst_rel_path)': dstInfo.relpath
      '$(dst_path)':     dstInfo.path
      '$(dst_dir)':      dstInfo.dir
      '$(dst_file)':     dstInfo.file

      '$(additional)':   []

    action = { id: 'compile', message: "Compiling #{srcInfo.file}" }
    invocation = file.compiler.tool.createInvocation(info)

    @project.reportActionStart(action)
    invocation.once 'finished', =>
      @project.reportActionFinish(action)
      callback()
    invocation.run()


  _fileInfo: (relpath) ->
    fullPath = Path.join(@project.fullPath, relpath)

    return {
      relpath: relpath
      file:    Path.basename(relpath)
      path:    fullPath
      dir:     Path.dirname(fullPath)
    }


# - (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project with:(CompilationOptions *)options compilerOutput:(ToolOutput **)compilerOutput {
#     if (compilerOutput) *compilerOutput = nil;

#     // TODO: move this into a more appropriate place
#     setenv("COMPASS_FULL_SASS_BACKTRACE", "1", 1);

#     NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#     NSString *sourcePath = [rootPath stringByAppendingPathComponent:sourceRelPath];
#     NSString *destinationPath = [rootPath stringByAppendingPathComponent:destinationRelPath];

#     RubyVersion *rubyVersion = [RubyVersion rubyVersionWithIdentifier:project.rubyVersionIdentifier];
#     NSString *rubyPath = (rubyVersion.valid ? rubyVersion.executablePath : @"__!RUBY_NOT_FOUND!__");

#     NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
#                                  rubyPath, @"$(ruby)",
#                                  [[NSBundle mainBundle] pathForResource:@"LiveReloadNodejs" ofType:nil], @"$(node)",
#                                  _plugin.path, @"$(plugin)",
#                                  rootPath, @"$(project_dir)",

#                                  [sourcePath lastPathComponent], @"$(src_file)",
#                                  sourcePath, @"$(src_path)",
#                                  [sourcePath stringByDeletingLastPathComponent], @"$(src_dir)",
#                                  sourceRelPath, @"$(src_rel_path)",

#                                  [destinationPath lastPathComponent], @"$(dst_file)",
#                                  destinationPath, @"$(dst_path)",
#                                  destinationRelPath, @"$(dst_rel_path)",
#                                  [destinationPath stringByDeletingLastPathComponent], @"$(dst_dir)",
#                                  nil];

#     NSString *additionalArguments = [options.additionalArguments stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
#     NSMutableArray *additionalArgumentsArray = [NSMutableArray array];

#     for (ToolOption *toolOption in [self optionsForProject:project]) {
#         [additionalArgumentsArray addObjectsFromArray:toolOption.currentCompilerArguments];
#     }

#     if ([additionalArguments length]) {
#         [additionalArgumentsArray addObjectsFromArray:[additionalArguments componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
#     }
#     [info setObject:[additionalArgumentsArray arrayBySubstitutingValuesFromDictionary:info] forKey:@"$(additional)"];

#     NSArray *arguments = [_commandLine arrayBySubstitutingValuesFromDictionary:info];
#     NSLog(@"Running compiler: %@", [arguments description]);

#     NSString *runDirectory;
#     if (_runDirectory) {
#         runDirectory = [_runDirectory stringBySubstitutingValuesFromDictionary:info];
#     } else {
#         runDirectory = NSTemporaryDirectory();
#     }

#     BOOL rubyInUse = [[arguments componentsJoinedByString:@" "] rangeOfString:rubyPath].length > 0;
#     if (rubyInUse && !rubyVersion.valid) {
#         NSLog(@"Ruby version '%@' does not exist, refusing to run.", project.rubyVersionIdentifier);
#         *compilerOutput = [[ToolOutput alloc] initWithCompiler:self type:ToolOutputTypeError sourcePath:sourcePath line:0 message:@"Ruby not found. Please visit this project's compiler settings and choose another Ruby interpreter" output:@""];
#         return;
#     }

#     NSString *commandLine = [arguments componentsJoinedByString:@" "]; // stringByReplacingOccurrencesOfString:[[NSBundle mainBundle] resourcePath] withString:@"$LiveReloadResources"] stringByReplacingOccurrencesOfString:[@"~" stringByExpandingTildeInPath] withString:@"~"];
#     NSString *command = [arguments objectAtIndex:0];
#     arguments = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];

#     NSError *error = nil;
#     NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
#     [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];
#     NSString *output = [NSTask stringByLaunchingPath:command
#                                        withArguments:arguments
#                                                error:&error];
#     [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];

#     NSString *strippedOutput = [output stringByReplacingOccurrencesOfRegex:@"(\\e\\[.*?m)+" withString:@"<ESC>"];
#     NSString *cleanOutput = [[strippedOutput stringByReplacingOccurrencesOfRegex:@"<ESC>" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

#     if (cleanOutput.length > 0) {
#         const char *project_path = [project.path UTF8String];
#         console_printf("\n%s compiler:\n%s\n\n%s\n\n", [self.name UTF8String], str_collapse_paths([commandLine UTF8String], project_path), str_collapse_paths([cleanOutput UTF8String], project_path));
#     }

#     if (error) {
#         NSLog(@"Error: %@\nOutput:\n%@", [error description], strippedOutput);
#         if ([error code] == kNSTaskProcessOutputError) {
#             NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
#                                            @"[^\\n]+?", @"file",
#                                            @"\\d+", @"line",
#                                            @"\\S[^\\n]+?", @"message",
#                                            nil];

#             NSDictionary *data = nil;
#             for (NSString *regexp in _errorFormats) {
#                 if ([regexp rangeOfString:@"message-override"].location != NSNotFound || [regexp rangeOfString:@"***"].location != NSNotFound)
#                     continue;  // new Node.js features not supported by this native code (yet?)
#                 NSString *stripped;
#                 if ([regexp rangeOfString:@"<ESC>"].length > 0) {
#                     stripped = strippedOutput;
#                 } else {
#                     stripped = [output stringByReplacingOccurrencesOfRegex:@"(\\e\\[.*?m)+" withString:@""];
#                 }
#                 NSDictionary *match = [stripped dictionaryByMatchingWithRegexp:regexp withSmartSubstitutions:substitutions options:0];
#                 if ([match count] > [data count]) {
#                     data = match;
#                 }
#             }

#             NSString *file = [data objectForKey:@"file"];
#             NSString *line = [data objectForKey:@"line"];
#             NSString *message = [[data objectForKey:@"message"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
#             enum ToolOutputType errorType = (message ? ToolOutputTypeError : ToolOutputTypeErrorRaw);

#             if (!file) {
#                 file = sourcePath;
#             } else if (![file isAbsolutePath]) {
#                 // used by Compass
#                 NSString *candidate1 = [rootPath stringByAppendingPathComponent:file];
#                 // used by everyone else
#                 NSString *candidate2 = [[sourcePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
#                 if ([[NSFileManager defaultManager] fileExistsAtPath:candidate2]) {
#                     file = candidate2;
#                 } else if ([[NSFileManager defaultManager] fileExistsAtPath:candidate1]) {
#                     file = candidate1;
#                 }
#             }
#             if (errorType == ToolOutputTypeErrorRaw) {
#                 message = output;
#                 if ([message length] == 0) {
#                     message = @"Compilation failed with an empty output.";
#                 }
#                 console_printf("%s: compilation failed.", [[sourcePath lastPathComponent] UTF8String]);
#             } else {
#                 if (line.length > 0) {
#                     console_printf("%s(%s): %s", [[sourcePath lastPathComponent] UTF8String], [line UTF8String], [message UTF8String]);
#                 } else {
#                     console_printf("%s: %s", [[sourcePath lastPathComponent] UTF8String], [message UTF8String]);
#                 }
#             }

#             if (compilerOutput) {
#                 NSInteger lineNo = [line integerValue];
#                 *compilerOutput = [[ToolOutput alloc] initWithCompiler:self type:errorType sourcePath:file line:lineNo message:message output:cleanOutput] ;
#             }
#         }
#     } else {
#         NSLog(@"Output:\n%@", strippedOutput);
#         console_printf("%s compiled.", [[sourcePath lastPathComponent] UTF8String]);
#     }
#     [pool drain];

#     //compilerOutput returned by reference and must be autoreleased, but not in local pool
#     [*compilerOutput autorelease];
# }

