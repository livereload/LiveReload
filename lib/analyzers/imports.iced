debug  = require('debug')('livereload:core:analyzer')
fs     = require 'fs'
Path   = require 'path'
Graph  = require '../projects/graph'

{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class ImportAnalyzer extends require('./base')

  message: "Computing imports"

  computePathList: ->
    list = new RelPathList()
    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        list.include RelPathSpec.parseGitStyleSpec(spec)
    return list

  clear: ->
    @project.imports = new Graph()

  removed: (relpath) ->
    @project.imports.remove(relpath)

  update: (relpath, fullPath, callback) ->
    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        if RelPathSpec.parseGitStyleSpec(spec).matches(relpath)
          debug "  ...#{relpath} matches compiler #{compiler.name}"
          await @_updateCompilableFile relpath, fullPath, compiler, defer()
    callback()

  _updateCompilableFile: (relpath, fullPath, compiler, callback) ->
    await fs.readFile fullPath, 'utf8', defer(err, text)
    if err
      debug "Error reading #{fullPath}: #{err}"
      return callback()

    fragments = []
    for re in compiler.importRegExps
      text.replace re, ($0, fragment) ->
        debug "  ... ...found import of '#{fragment}'"
        fragments.push fragment
        $0

    importedRelPaths = []
    for fragment in fragments
      await @project.vfs.findFilesMatchingSuffixInSubtree @project.path, fragment, Path.basename(relpath), defer(err, result)
      if err
        debug "  ... ...error in findFilesMatchingSuffixInSubtree: #{err}"
      else if result.bestMatch
        debug "  ... ...imported file found at #{result.bestMatch.path}"
        importedRelPaths.push result.bestMatch.path
      else
        debug "  ... ...imported file not found in project tree"

    debug "  ...imported paths = " + JSON.stringify(importedRelPaths)

    @project.imports.updateOutgoing relpath, importedRelPaths

    callback()


# - (NSSet *)referencedPathFragmentsForPath:(NSString *)path {
#     if ([_importRegExps count] == 0)
#         return [NSSet set];

#     NSError *error = nil;
#     NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
#     if (!text) {
#         NSLog(@"Failed to read '%@' for determining imports. Error: %@", path, [error localizedDescription]);
#         return [NSSet set];
#     }

#     NSMutableSet *result = [NSMutableSet set];

#     void (^processImport)(NSString *path) = ^(NSString *path){
#         if ([_defaultImportedExts count] > 0 && [[path pathExtension] length] == 0) {
#             for (NSString *ext in _defaultImportedExts) {
#                 NSString *newPath = [path stringByAppendingFormat:@".%@", ext];
#                 for (NSString *mapping in _importToFileMappings) {
#                     NSString *dir = [newPath stringByDeletingLastPathComponent];
#                     NSString *name = [newPath lastPathComponent];
#                     NSString *mapped = [[mapping stringByReplacingOccurrencesOfString:@"$(file)" withString:name] stringByReplacingOccurrencesOfString:@"$(dir)" withString:dir];
#                     if ([[mapped substringToIndex:2] isEqualToString:@"./"])
#                         mapped = [mapped substringFromIndex:2];
#                     [result addObject:mapped];
#                 }
#             }
#         } else if ([[path pathExtension] length] > 0 && [_nonImportedExts containsObject:[path pathExtension]]) {
#             // do nothing; e.g. @import "foo.css" in LESS does not actually import the file
#         } else {
#             for (NSString *mapping in _importToFileMappings) {
#                 NSString *newPath = path;
#                 NSString *dir = [newPath stringByDeletingLastPathComponent];
#                 NSString *name = [newPath lastPathComponent];
#                 NSString *mapped = [[mapping stringByReplacingOccurrencesOfString:@"$(file)" withString:name] stringByReplacingOccurrencesOfString:@"$(dir)" withString:dir];
#                 if ([[mapped substringToIndex:2] isEqualToString:@"./"])
#                     mapped = [mapped substringFromIndex:2];
#                 [result addObject:mapped];
#             }
#         }
#     };

#     for (NSString *regexp in _importRegExps) {
#         [text enumerateStringsMatchedByRegex:regexp usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
#             if (captureCount != 2) {
#                 NSLog(@"Skipping import regexp '%@' for compiler %@ because the regexp does not have exactly one capture group.", regexp, _name);
#                 return;
#             }
#             processImport(capturedStrings[1]);

#             __block NSUInteger start = capturedRanges[0].location + capturedRanges[0].length;
#             while (start < text.length) {
#                 __block BOOL found = NO;
#                 for (NSString *contRegexp in _importContinuationRegExps) {
#                     contRegexp = [@"^\\s*" stringByAppendingString:contRegexp];
#                     [[text substringFromIndex:start] enumerateStringsMatchedByRegex:contRegexp usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
#                         if (captureCount != 2) {
#                             NSLog(@"Skipping import continuation regexp '%@' for compiler %@ because the regexp does not have exactly one capture group.", contRegexp, _name);
#                             return;
#                         }
#                         processImport(capturedStrings[1]);
#                         start += capturedRanges[0].location + capturedRanges[0].length;
#                         *stop = found = YES;
#                     }];
#                     if (found)
#                         break;
#                 }
#                 if (!found)
#                     break;
#             }
#         }];
#     }
#     return result;
# }
