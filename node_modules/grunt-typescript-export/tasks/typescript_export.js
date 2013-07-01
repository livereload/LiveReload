'use strict';

module.exports = function(grunt) {

  grunt.registerMultiTask('typescript_export', 'Concat all .d.ts into a single file for external clients to import.', function() {
    var options = this.options({
      name: grunt.config('pkg.name')
    });

    this.files.forEach(function(group) {
      var snippets = [];
      var references = [];
      var imports = [];
      var sources = [];

      grunt.file.expand(group.src).forEach(function (file) {
        if (!grunt.file.exists(file)) {
          grunt.log.warn('Source file "' + file + '" not found.');
          return;
        }

        var lines = grunt.file.read(file).trim().split("\n");
        lines = lines.filter(function(line) {
          if (line.match(/<reference/)) {
            line = line.replace(/(<reference path=")\.\.\//g, '$1./');
            if (references.indexOf(line) === -1) {
              references.push(line);
            }
            return false;
          } else if (line.match(/^import /)) {
            if (imports.indexOf(line) === -1) {
              imports.push(line);
            }
            return false;
          } else {
            return true;
          }
        });

        var content = lines.join("\n") + "\n";
        content = content.replace(/ declare /g, ' ').replace(/\bdeclare /g, '');

        sources.push({ content: content, file: file });
      });

      if (references.length > 0) {
        references.forEach(function(line) {
          snippets.push(line + "\n");
        });
        snippets.push("\n");
      }

      snippets.push('declare module "' + options.name + '" {\n\n');

      if (imports.length > 0) {
        imports.forEach(function(line) {
          snippets.push(line + "\n");
        });
        snippets.push("\n");
      }

      sources.forEach(function(source) {
        snippets.push("// " + source.file + "\n");
        snippets.push(source.content);
        snippets.push("\n");
      });
      snippets.push('}\n');

      grunt.file.write(group.dest, snippets.join(''));
      grunt.log.writeln('File "' + group.dest + '" created.');
    });
  });

};
