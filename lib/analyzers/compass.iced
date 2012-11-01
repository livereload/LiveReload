debug  = require('debug')('livereload:core:analyzer')
{ RelPathList } = require 'pathspec'

module.exports =
class CompassAnalyzer extends require('./base')

  message: "Detecting Compass"

  computePathList: ->
    RelPathList.parse(["*.rb", "*.config"])

  clear: ->
    @project.compassMarkers = []

  removed: (relpath) ->
    # TODO

  update: (file, callback) ->
    # TODO
    callback()

# - (BOOL)isCompassConfigurationFile:(NSString *)relativePath {
#     return MatchLastPathTwoComponents(relativePath, @"config", @"compass.rb") || MatchLastPathTwoComponents(relativePath, @".compass", @"config.rb") || MatchLastPathTwoComponents(relativePath, @"config", @"compass.config") || MatchLastPathComponent(relativePath, @"config.rb") || MatchLastPathTwoComponents(relativePath, @"src", @"config.rb");
# }



# - (void)scanCompassConfigurationFile:(NSString *)relativePath {
#     NSString *data = [NSString stringWithContentsOfFile:[self.path stringByAppendingPathComponent:relativePath] encoding:NSUTF8StringEncoding error:nil];
#     if (data) {
#         if ([data isMatchedByRegex:@"compass plugins"] || [data isMatchedByRegex:@"^preferred_syntax = :(sass|scss)" options:RKLMultiline inRange:NSMakeRange(0, data.length) error:nil]) {
#             _compassDetected = YES;
#         }
#     }
# }
