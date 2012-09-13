apitree.js
===========

Node.js module to create a SocketStream-style API tree from a file system directory.


Installation
------------

    npm install apitree


Usage
-----

Call `createApiTree` to load all files in the given directory (and its subdirectories) and return an object, such that `returnedObject.foo.bar.boz.fubar` equals to exported function `fubar` of file `boz` in subdirectory `foo/bar` of the given directory. (Some of the described details are customizable via optional callbacks.)

Example:

    var apitree = require('apitree');
    var path    = require('path');

    var api = apitree.createApiTree(path.join(__dirname, 'apiroot'))

    api.somefile.func1(42);
    api.sub.folder.anotherfile.func2(24);

createApiTree function accepts 2 arguments:

    apitree.createApiTree(directory, options)

where options is an optional object with 3 possible keys:

* `options.loadItem(path)` loads the contents of file at `path`; returns either `null` or an object that will be merged into the tree; the default value is `require`.
* `options.filter(name, names)` determines whether given file should be processed or ignored; other names from the same directory are provided as the second argument; the default implementation returns true for .js files and files with a registered extension in require.extensions which don't have corresponding .js files. (Exludes .json files)
* `options.nameToKey(name)` returns a key to use in the tree object for the given file or folder name; the default implementation strips the file extension and replaces any non-identifier characters with underscores.

Additionally, `options.readdirSync(directory)` and `options.isDirectory(path)` can be provided to override the standard behavior of reading from the file system.


Somewhat more realistic example
-------------------------------

See example/ directory. In CoffeeScript:

    global.DB =
      put: (collection, object) ->
        @[collection].push object
        console.log "Added to #{collection}: #{JSON.stringify(object)}"

    path = require 'path'
    global.S = require('apitree').createApiTree(path.join(__dirname, 'server'))

    S.app.init()
    userId = S.users.create(name: 'admin', password: 'admin123')
    postId = S.blog.posts.publish(authorId: userId, title: "Hello!", body: "Hey! This is my first post.")
    S.blog.comments.publish(postId: postId, author: "Random Visitor", body: "Very excited about your new blog.")
    S.blog.comments.publish(postId: postId, author: "spa.m@mer.go.ddam.it", body: "Send Your Name, Address...")

example/server/app.coffee:

    exports.init = ->
      DB.users    = []
      DB.posts    = []
      DB.comments = []

example/server/users.coffee:

    exports.create = ({ name, password }) ->
      user = { name, password, id: DB.users.length }
      DB.put 'users', user
      user.id

example/server/blog/posts.coffee:

    exports.publish = ({authorId, title, body}) ->
      post = { authorId, title, body, id: DB.posts.length }
      DB.put 'posts', post
      post.id

example/server/blog/comments.coffee:

    exports.publish = ({postId, author, body}) ->
      comment = { postId, author, body, id: DB.comments.length }
      DB.put 'comments', comment
      comment.id


Spec
----

Uses mocha, run `npm test` to execute tests.

    API tree
        when given an empty folder
          ✓ should return an empty tree
        when given a folder with a single file
          ✓ should put the file node under the tree root
          ✓ should strip the extension when naming the tree node
          ✓ should put the file's contents under its node
        when given a file and a subfolder
          ✓ should put the file and subfolder nodes together under the tree root
        when given a file and a subfolder which have the same name after stripping extensions
          ✓ should merge the file and the subfolder into a single node under the tree root
        when given a folder hierarchy with nested subfolders
          ✓ should reproduce the folder hierarachy inside the API tree
        loadItem callback
          ✓ should be used to obtain file contents
        nameToKey callback
          ✓ should accept file name as the only argument
          ✓ should be used to translate file names into tree keys
          ✓ should be used to translate subfolder names into tree keys
          ✓ should not be used to modify keys returned by loadItem
        default nameToKey callback
          ✓ should strip file extension
          ✓ should replace any non-identifier characters with underscores
          ✓ should replace runs of multiple non-identifier characters with a single underscore
        filter callback
          ✓ should accept file name as the first argument
          ✓ should accept the list of all file names in the same folder as the second argument
          ✓ should be used to choose which files to process
          ✓ should have no effect on which folders are processed
        default filter callback
          ✓ should include .js files
          ✓ should include .coffee files that don't have corresponding .js files
          ✓ should include registered extension files that don't have corresponding .js files
          ✓ should only include .js file when both .js and .coffee files exist
          ✓ should only include .js file when both registered extension file and .js files exist
          ✓ should not include any other files

    ✔ 25 tests complete (47ms)


License
-------

MIT license. Copyright 2011–2012, [Andrey Tarantsov](andrey@tarantsov.com).
