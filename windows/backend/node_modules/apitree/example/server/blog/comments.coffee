
exports.publish = ({postId, author, body}) ->
  comment = { postId, author, body, id: DB.comments.length }
  DB.put 'comments', comment
  comment.id
