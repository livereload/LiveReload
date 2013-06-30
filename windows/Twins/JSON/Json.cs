namespace Twins.JSON
{
    public static class Json
    {
        public static object Parse(string input) {
            return new JsonParser(input, false).Decode();
        }

        public static string Stringify(object input, bool pretty = false) {
            var result = new JsonSerializer().ConvertToJSON(input);
            if (pretty)
                result = PrettyPrint(result);
            return result;
        }

        public static string PrettyPrint(string input) {
            return JsonFormatter.PrettyPrint(input);
        }
    }
}
