using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace PathSpec
{
    public abstract class Mask
    {
        public abstract bool Matches(string filename, string path);
    }

    public class FixedFileMask : Mask
    {
        private readonly string filename;

        public FixedFileMask(string filename) {
            this.filename = filename;
        }

        public override bool Matches(string filename, string path) {
            return this.filename == filename;
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
        public override bool Matches(string filename, string path) {
            return regex.IsMatch(filename);
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
}
