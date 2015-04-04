
exports.create = ({ name, password }) ->
  user = { name, password, id: DB.users.length }
  DB.put 'users', user
  user.id
