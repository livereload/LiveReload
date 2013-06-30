using System.Text;

namespace Twins.JSON
{
    internal static class JsonFormatter
    {
        public static string Indent = "   ";

        public static void AppendIndent(StringBuilder sb, int count)
        {
            for (; count > 0; --count) sb.Append(Indent);
        }

        public static string PrettyPrint(string input)
        {
            var output = new StringBuilder(input.Length * 2);
            int depth = 0;

            for (int i = 0; i < input.Length; ++i)
            {
                char ch = input[i];

                switch (ch)
                {
                    case '\"': // found string span
                        bool str = true;
                        while (str)
                        {
                            output.Append(ch);
                            ch = input[++i];
                            if (ch == '\\')
                            {
                                if (input[i + 1] == '\"')
                                {
                                    output.Append(ch);
                                    ch = input[++i];
                                }
                            }
                            else if (ch == '\"')
                                str = false;
                        }
                        break;
                    case '{':
                    case '[':
                        output.Append(ch);
                        output.AppendLine();
                        AppendIndent(output, ++depth);
                        break;
                    case '}':
                    case ']':
                        output.AppendLine();
                        AppendIndent(output, --depth);
                        output.Append(ch);
                        break;
                    case ',':
                        output.Append(ch);
                        output.AppendLine();
                        AppendIndent(output, depth);
                        break;
                    case ':':
                        output.Append(" : ");
                        break;
                    default:
                        if (!char.IsWhiteSpace(ch))
                            output.Append(ch);
                        break;
                }

            }

            return output.ToString();
        }
    }
}