using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.IO;
using SevenZip;
using System.Threading;
using System.Windows.Threading;
using System.Runtime.Serialization;
using System.Windows;

namespace LiveReload
{
    [Serializable]
    public class CommandLineArgException : Exception
    {
        public CommandLineArgException(string message)
            : base(message)
        {
        }

        protected CommandLineArgException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
        }
    }

    public struct CommandLineOptions
    {
        public string LRBackendOverride;
        public string LRBundledPluginsOverride;

        public static CommandLineOptions Parse(string[] args)
        {
            var options = new CommandLineOptions();
            using (var iter = args.AsEnumerable().GetEnumerator())
            {
                while (iter.MoveNext())
                {
                    string arg = iter.Current;
                    if (String.Equals(arg, "-LRBackendOverride", StringComparison.OrdinalIgnoreCase))
                    {
                        if (!iter.MoveNext())
                            throw new CommandLineArgException("Missing value for argument " + arg);
                        options.LRBackendOverride = iter.Current;
                    }
                    else if (String.Equals(arg, "-LRBundledPluginsOverride", StringComparison.OrdinalIgnoreCase))
                    {
                        if (!iter.MoveNext())
                            throw new CommandLineArgException("Missing value for argument " + arg);
                        options.LRBundledPluginsOverride = iter.Current;
                    }
                    else
                    {
                        throw new CommandLineArgException("Unknown option " + arg);
                    }
                }
            }
            return options;
        }
    }

    public partial class App
    {
        public static void DisplayCommandLineError(string message)
        {
            MessageBox.Show(message, "LiveReload Command Line Error", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }
}
