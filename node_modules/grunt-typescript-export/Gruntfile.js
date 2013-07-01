'use strict';

module.exports = function(grunt) {

  grunt.initConfig({
    pkg: {
      name: 'foo'
    },

    jshint: {
      all: [
        'Gruntfile.js',
        'tasks/*.js',
      ],
      options: {
        jshintrc: '.jshintrc',
      },
    },

    clean: {
      tests: ['tmp'],
    },

    // Configuration to be run (and then tested).
    typescript_export: {
      first: {
        options: {
        },
        files: {
          'tmp/first.d.ts': ['test/fixtures/api.d.ts', 'test/fixtures/foo.d.ts', 'test/fixtures/bar.d.ts'],
        },
      },
    },

    nodeunit: {
      tests: ['test/*_test.js'],
    },

  });

  grunt.loadTasks('tasks');

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-nodeunit');

  // Whenever the "test" task is run, first clean the "tmp" dir, then run this
  // plugin's task(s), then test the result.
  grunt.registerTask('test', ['clean', 'typescript_export', 'nodeunit']);

  grunt.registerTask('default', ['jshint', 'test']);

};
