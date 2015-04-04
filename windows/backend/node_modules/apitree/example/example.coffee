
global.DB =
  put: (collection, object) ->
    @[collection].push object
    console.log "Added to #{collection}: #{JSON.stringify(object)}"

path = require 'path'
global.S = require('../lib/apitree').createApiTree(path.join(__dirname, 'server'))

S.app.init()
userId = S.users.create(name: 'admin', password: 'admin123')
postId = S.blog.posts.publish(authorId: userId, title: "Hello!", body: "Hey! This is my first post.")
S.blog.comments.publish(postId: postId, author: "Random Visitor", body: "Very excited about your new blog.")
S.blog.comments.publish(postId: postId, author: "spa.m@mer.go.ddam.it", body: "Send Your Name, Address to receive £750,000 GBP in British P O Cash Splash.")
