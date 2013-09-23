exports.RegExp_escape = (str) ->
  str.replace(///(  [ / ' * + ? | ( ) \[ \] { } . ^ $ ]  )///g, '\\$1')
