using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace PathSpecTests
{
    [TestClass]
    public class PathSpecTests
    {
        [TestMethod]
        public void TestTrivialFileMask() {
            var foo = PathSpec.PathSpec.Parse("foo.txt");
            Assert.IsTrue(foo.Matches("foo.txt", @"C:\foo\bar\lol\foo.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void TestWildcardFileMask() {
            var foo = PathSpec.PathSpec.Parse("*.txt");
            Assert.IsTrue(foo.Matches("foo.txt", @"C:\foo\bar\lol\foo.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void TestComplexFileMask() {
            var foo = PathSpec.PathSpec.Parse("?*hello?.txt");
            Assert.IsTrue(foo.Matches("o_hello!.txt", @"C:\foo\bar\lol\o_hello!.txt"));
            Assert.IsTrue(foo.Matches("_hello!.txt", @"C:\foo\bar\lol\_hello!.txt"));
            Assert.IsFalse(foo.Matches("hello_foo.txt", @"C:\foo\bar\lol\hello_foo.txt"));
            Assert.IsFalse(foo.Matches("o_hello!.png", @"C:\foo\bar\goatse.cx\o_hello!.png"));
            Assert.IsFalse(foo.Matches("!o_hello_foo.png", @"C:\foo\bar\goatse.cx\!o_hello_foo.png"));
            Assert.IsFalse(foo.Matches("foo_hello.txt", @"C:\foo\bar\lol\foo_hello.txt"));
        }

        [TestMethod]
        public void TestSpecialFileMask() {
            var foo = PathSpec.PathSpec.Parse("b*ar?.txt*");
            Assert.IsTrue(foo.Matches("barf.txt.bat", @"C:\foo\bar\lol\barf.txt.bat"));
            Assert.IsTrue(foo.Matches("board.dart.txt......", @"board.dart.txt......"));
        }

        [TestMethod]
        public void TestI18nFileMask() {
            var хуй = PathSpec.PathSpec.Parse("?*привет?.txt");
            Assert.IsTrue(хуй.Matches("о_привет!.txt", @"C:\хуй\bar\lol\о_привет!.txt"));
            Assert.IsTrue(хуй.Matches("_привет!.txt", @"C:\хуй\bar\lol\_привет!.txt"));
            Assert.IsFalse(хуй.Matches("привет_хуй.txt", @"C:\хуй\bar\lol\привет_хуй.txt"));
            Assert.IsFalse(хуй.Matches("о_привет!.png", @"C:\хуй\bar\goatse.cx\о_привет!.png"));
            Assert.IsFalse(хуй.Matches("!о_привет_хуй.png", @"C:\хуй\bar\goatse.cx\!о_привет_хуй.png"));
            Assert.IsFalse(хуй.Matches("хуй_привет.txt", @"C:\хуй\bar\lol\хуй_привет.txt"));
        }
    }
}
