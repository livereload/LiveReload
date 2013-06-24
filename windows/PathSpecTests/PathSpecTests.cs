using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace PathSpecTests
{
    [TestClass]
    public class PathSpecTests
    {
        [TestMethod]
        public void TestTrivialFileMask() {
            var foo = PathSpec.PathSpec.Parse("хуй.txt");
            Assert.IsTrue(foo.Matches("хуй.txt", @"C:\foo\bar\lol\хуй.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void TestWildcardFileMask() {
            var foo = PathSpec.PathSpec.Parse("*.txt");
            Assert.IsTrue(foo.Matches("хуй.txt", @"C:\foo\bar\lol\хуй.txt"));
            Assert.IsFalse(foo.Matches("pizda.dat", @"C:\foo\bar\lol\pizda.dat"));
        }

        [TestMethod]
        public void TestComplexFileMask() {
            var foo = PathSpec.PathSpec.Parse("?*привет?.txt");
            Assert.IsTrue(foo.Matches("о_привет!.txt", @"C:\foo\bar\lol\о_привет!.txt"));
            Assert.IsTrue(foo.Matches("_привет!.txt", @"C:\foo\bar\lol\_привет!.txt"));
            Assert.IsFalse(foo.Matches("привет_хуй.txt", @"C:\foo\bar\lol\привет_хуй.txt"));
            Assert.IsFalse(foo.Matches("о_привет!.png", @"C:\foo\bar\lgoatse.cx\о_привет!.png"));
            Assert.IsFalse(foo.Matches("!о_привет_хуй.png", @"C:\foo\bar\goatse.cx\!о_привет_хуй.png"));
            Assert.IsFalse(foo.Matches("хуй_привет.txt", @"C:\foo\bar\lol\хуй_привет.txt"));
        }

        [TestMethod]
        public void TestSpecialFileMask() {
            var foo = PathSpec.PathSpec.Parse("b*ar?.txt*");
            Assert.IsTrue(foo.Matches("barf.txt.bat", @"C:\foo\bar\lol\barf.txt.bat"));
            Assert.IsTrue(foo.Matches("board.dart.txt......", @"board.dart.txt......"));
        }
    }
}
