using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace PathSpec
{
    public abstract class Mask
    {
        public abstract bool Matches(string[] components, string path);

        public bool Matches(string filename, string path) {
            return Matches(new string[] { filename }, path);
        }
    }

    public class FixedFileMask : Mask
    {
        private readonly string filename;

        public FixedFileMask(string filename) {
            this.filename = filename;
        }

        public override bool Matches(string[] components, string path) {
            foreach (var component in components) {
                if (component == this.filename)
                    return true;
            }
            return false;
        }
    }

    public class WildcardFileMask : Mask
    {
        private readonly string mask;
        private readonly Regex regex;

        public WildcardFileMask(string mask) {
            this.mask = mask;
            this.regex = CompileToRegex(mask);
        }

        private static Regex CompileToRegex(string mask) {
            // Do we need to handle all valid *nix path characters?
            string pattern =
                 '^' +
                 Regex.Escape(mask.Replace("*", "__:STAR:__")
                                  .Replace("?", "__:QM:__"))
                     .Replace("__:STAR:__", ".*")
                     .Replace("__:QM:__", ".")
                 + '$';
            return new Regex(pattern, RegexOptions.IgnoreCase);
        }

        // Windows internal file matching rules are crap and are not emulated here
        // (eg try to match filename "foobar..." with "foobar.?.")
        // Also: http://blogs.msdn.com/b/oldnewthing/archive/2007/12/17/6785519.aspx
        public override bool Matches(string[] components, string path) {
            foreach (var component in components) {
                if (regex.IsMatch(component))
                    return true;
            }
            return false;
        }
    }

    public class PathList
    {
        private readonly List<Mask> masks = new List<Mask>();

        public void Include(Mask mask) {
            masks.Add(mask); // do we need to check for dupes?
        }

        public bool Includes(string path) {
            var components = PathUtils.SplitPathComponents(path);
            foreach (var mask in masks) {
                if (mask.Matches(components, path))
                    return true;
            }
            return false;
        }

        public void AddLines(string masks) {
            using (var reader = new System.IO.StringReader(masks)) {
                string line;
                while ((line = reader.ReadLine()) != null) {
                    var hashPos = line.IndexOf('#');
                    if (hashPos != -1) {
                        line = line.Substring(0, hashPos);
                    }
                    line = line.Trim();
                    if (line.Length == 0)
                        continue;

                    var mask = PathSpec.Parse(line);
                    Include(mask);
                }
            }
        }

        public static PathList Parse(string masks) {
            var list = new PathList();
            list.AddLines(masks);
            return list;
        }
    }

    public class PathSpec
    {
        public static Mask Parse(string mask) {
            if (mask.Contains("*") || mask.Contains("?")) {
                return new WildcardFileMask(mask);
            } else {
                return new FixedFileMask(mask);
            }
        }
    }

    public static class PathUtils
    {
        public static string[] SplitPathComponents(string path) {
            var separators = new char[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar };
            return path.Split(separators, StringSplitOptions.RemoveEmptyEntries);
        }
    }
}
