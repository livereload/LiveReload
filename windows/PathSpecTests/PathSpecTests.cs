using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

using PathSpec;

namespace PathSpecTests
{
    [TestClass]
    public class MaskTests
    {
        [TestMethod]
        public void Mask_Trivial() {
            var foo = PathSpec.PathSpec.Parse("foo.txt");
            Assert.IsTrue(foo.Matches("foo.txt", @"C:\foo\bar\lol\foo.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void Mask_Wildcard() {
            var foo = PathSpec.PathSpec.Parse("*.txt");
            Assert.IsTrue(foo.Matches("foo.txt", @"C:\foo\bar\lol\foo.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void Mask_Complex() {
            var foo = PathSpec.PathSpec.Parse("?*hello?.txt");
            Assert.IsTrue(foo.Matches("o_hello!.txt", @"C:\foo\bar\lol\o_hello!.txt"));
            Assert.IsTrue(foo.Matches("_hello!.txt", @"C:\foo\bar\lol\_hello!.txt"));
            Assert.IsFalse(foo.Matches("hello_foo.txt", @"C:\foo\bar\lol\hello_foo.txt"));
            Assert.IsFalse(foo.Matches("o_hello!.png", @"C:\foo\bar\goatse.cx\o_hello!.png"));
            Assert.IsFalse(foo.Matches("!o_hello_foo.png", @"C:\foo\bar\goatse.cx\!o_hello_foo.png"));
            Assert.IsFalse(foo.Matches("foo_hello.txt", @"C:\foo\bar\lol\foo_hello.txt"));
        }

        [TestMethod]
        public void Mask_Special() {
            var foo = PathSpec.PathSpec.Parse("b*ar?.txt*");
            Assert.IsTrue(foo.Matches("barf.txt.bat", @"C:\foo\bar\lol\barf.txt.bat"));
            Assert.IsTrue(foo.Matches("board.dart.txt......", @"board.dart.txt......"));
        }

        [TestMethod]
        public void Mask_I18n() {
            var хуй = PathSpec.PathSpec.Parse("?*привет?.txt");
            Assert.IsTrue(хуй.Matches("о_привет!.txt", @"C:\хуй\bar\lol\о_привет!.txt"));
            Assert.IsTrue(хуй.Matches("_привет!.txt", @"C:\хуй\bar\lol\_привет!.txt"));
            Assert.IsFalse(хуй.Matches("привет_хуй.txt", @"C:\хуй\bar\lol\привет_хуй.txt"));
            Assert.IsFalse(хуй.Matches("о_привет!.png", @"C:\хуй\bar\goatse.cx\о_привет!.png"));
            Assert.IsFalse(хуй.Matches("!о_привет_хуй.png", @"C:\хуй\bar\goatse.cx\!о_привет_хуй.png"));
            Assert.IsFalse(хуй.Matches("хуй_привет.txt", @"C:\хуй\bar\lol\хуй_привет.txt"));
        }
    }

    [TestClass]
    public class PathListTests
    {
        private const string include =  "*.html" + "\n" +
                                        "*.htm" + "\n" +
                                        "*.shtml" + "\n" +
                                        "*.xhtml    # 1999 just called" + "\n" +
                                        "" + "\n" +
                                        "*.asp      # 1995 is on the line as well" + "\n" +
                                        "n" + "\n" +
                                        "# Not sure what good comes from monitoring these" + "\n";
        [TestMethod]
        public void PathList_Trivial() {
            var foo = PathList.Parse(include);
            Assert.IsTrue(foo.Includes(@"C:\foo\bar\lol\foo.htm"));
            Assert.IsTrue(foo.Includes(@"C:\foo\bar\lol\bar.xhtml"));
            Assert.IsTrue(foo.Includes(@"C:\foo\bar\lol\lol.asp\n"));
            Assert.IsFalse(foo.Includes(@"C:\# Not sure what good comes from monitoring these"));
            Assert.IsFalse(foo.Includes(@"C:"));
            Assert.IsFalse(foo.Includes(@"C:\"));
            Assert.IsFalse(foo.Includes(@"lol"));
        }

        [TestMethod]
        public void PathList_MatchInTheMiddle() {
            var foo = PathList.Parse(include);
            Assert.IsTrue(foo.Includes(@"C:\goatse.asp\haha"));
            Assert.IsFalse(foo.Includes(@"C:\goatse.aspx\haha"));
            Assert.IsTrue(foo.Includes(@"~/goatse.asp/"));
            Assert.IsTrue(foo.Includes(@"~/goatse.asp/haha"));
            Assert.IsFalse(foo.Includes(@"C:\# Not sure what good comes from monitoring these/haha"));
        }
    }
}
