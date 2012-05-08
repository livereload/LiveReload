pathspec.js
===========

Shell-style file name masks:

    var Mask = require('pathspec').Mask;
    console.log(Mask.parse('*.txt').matches('foo.txt')); // true
    console.log(Mask.parse('*.txt').matches('foo.js'));  // false

Shell-style path wildcards:

    var RelPathSpec = require('pathspec').RelPathSpec;
    console.log(RelPathSpec.parse('foo/**/bar/*.txt').matches('foo/moo/goo/bar/myfile.txt')); // true
    console.log(RelPathSpec.parse('foo.txt').matches('bar/foo.txt')); // false

.gitignore-style path wildcards:

    var RelPathSpec = require('pathspec').RelPathSpec;
    console.log(RelPathSpec.parseGitStyleSpec('foo/**/bar').matches('foo/moo/goo/bar/poo/koo/myfile.txt')); // true
    console.log(RelPathSpec.parseGitStyleSpec('foo.txt').matches('bar/foo.txt')); // true

.gitignore-style path lists:

    var RelPathList = require('pathspec').RelPathList;
    var list = RelPathList.parse(['*.js', '!bin/*.js']);
    console.log(list.matches('foo.js')); // true
    console.log(list.matches('lib/foo.js')); // true
    console.log(list.matches('bin/foo.js')); // false

Build a path list manually (spec style is up to you):

    var RelPathList = require('pathspec').RelPathList;
    var list = new RelPathList();
    list.include(RelPathSpec.parse('*.js'));
    list.exclude(RelPathSpec.parse('bar.js'));
    console.log(list.matches('foo.js')); // true
    console.log(list.matches('lib/foo.js')); // false
    console.log(list.matches('bar.js')); // false

Note: they are called RelSomething because the paths are relative to some specific unknown root. Beware that things like '.' and '..' are not treated in any special way.


Installation
------------

    npm install pathspec


Running tests
-------------

    npm test
    REPORTER=dot npm test


License
-------

MIT.
