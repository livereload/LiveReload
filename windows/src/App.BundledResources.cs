using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.IO;
using SevenZip;
using System.Threading;
using System.Windows.Threading;

namespace LiveReload
{
    public partial class App
    {
        private string bundledBackendDir;
        private string bundledPluginsDir;
        private string bundledRubyDir;
        private string bundledNodeDir;

        private void BeginExtractBundledResources(Action Callback) {
            Thread extractThread = new Thread(new ThreadStart(
                (Action)(() => {
                    SevenZipExtractor.SetLibraryPath(Path.Combine(resourcesDir, "7zxa.dll"));

                    bundledBackendDir = extractBundledResourcesFromFile("backend.7z");
                    bundledPluginsDir = extractBundledResourcesFromFile("plugins.7z");
                    bundledRubyDir = extractBundledResourcesFromFile("ruby-1.9.3.7z");
                    bundledNodeDir = extractBundledResourcesFromFile("node-0.10.0.7z");

                    App.Current.Dispatcher.Invoke(DispatcherPriority.Normal,
                        (Action)(() => { Callback(); })
                    );
                })
            ));
            extractThread.IsBackground = true; // need for thread to close at application exit
            extractThread.Start();
        }

        private string extractBundledResourcesFromFile(string filename) {
            string sourceFile = Path.Combine(resourcesDir, "bundled", filename);
            string timestampFile = Path.Combine(extractedResourcesDir, Path.ChangeExtension(filename, "timestamp"));

            string destinationDir = Path.Combine(extractedResourcesDir, Path.GetFileNameWithoutExtension(filename));

            if (!File.Exists(timestampFile) || File.GetLastWriteTimeUtc(sourceFile) > File.GetLastWriteTimeUtc(timestampFile)) {
                DeleteRecursivelyWithMagicDust(destinationDir);

                var extractor = new SevenZipExtractor(sourceFile);

                // we typically have a properly-named root dir inside .7z itself, so extracting into destinationDir doesn't work
                extractor.ExtractArchive(extractedResourcesDir);
                extractor.Dispose();

                File.WriteAllBytes(timestampFile, new byte[0]);
            }

            return destinationDir;
        }

        private static void DeleteRecursivelyWithMagicDust(string destinationDir) {
            const int magicDust = 10;
            for (var gnomes = 1; gnomes <= magicDust; gnomes++) {
                try {
                    Directory.Delete(destinationDir, true);
                } catch (DirectoryNotFoundException) {
                    return;  // good!
                } catch (IOException) { // System.IO.IOException: The directory is not empty
                    System.Diagnostics.Debug.WriteLine("Gnomes prevent deletion of {0}! Applying magic dust, attempt #{1}.", destinationDir, gnomes);

                    // see http://stackoverflow.com/questions/329355/cannot-delete-directory-with-directory-deletepath-true for more magic.
                    Thread.Sleep(50);
                    continue;
                }
                return;
            }
        }
    }
}
