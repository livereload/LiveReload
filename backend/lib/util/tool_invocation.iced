
exports.subst = subst = (value, args) ->
  if Object.isString(value)
    for own argName, argValue of args
      value = value.replace ///#{RegExp.escape(argName)}///g, argValue
    value
  else if Object.isArray(value)
    result = []
    for item in value
      # when $(something) arg value is an array, occurrences of $(something) in the source array are substituted by splicing
      if Object.isString(item) and (argValue = args[item])? and Object.isArray(argValue)
        result.push.apply(result, argValue)
      else
        result.push subst(item, args)
    return result
  else
    throw new Error("Unsupported value type in subst: #{typeof value}")
