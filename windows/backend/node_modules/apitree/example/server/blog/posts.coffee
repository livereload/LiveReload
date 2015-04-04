
exports.publish = ({authorId, title, body}) ->
  post = { authorId, title, body, id: DB.posts.length }
  DB.put 'posts', post
  post.id
