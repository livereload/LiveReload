'use strict';

// see http://stackoverflow.com/questions/3205027/maximum-length-of-command-line-string
var ChunkSize = 60;

var fs = require('fs');
var pathspec = require('pathspec');

var list = pathspec.RelPathList.parse(['*.coffee', '*.iced']);
pathspec.find('.', list, function(files) {
  files = files.filter(function(file) { return file.indexOf('node_modules') == -1; });
  while (files.length > 0) {
    var chunk = files.slice(0, ChunkSize);
    files.splice(0, ChunkSize);

    var cmdline = "call iced --runtime inline -c " + chunk.join(' ').replace(/\\/g, "/") + "\n";
    process.stdout.write(cmdline);
  }
});
