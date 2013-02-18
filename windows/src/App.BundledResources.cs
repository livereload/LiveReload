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
        private string bundledRubyDir;
        private string bundledNodeDir;

        private void BeginExtractBundledResources(Action Callback)
        {
            Thread extractThread = new Thread(new ThreadStart (
                (Action)(() => {
                    SevenZipExtractor.SetLibraryPath(Path.Combine(resourcesDir, "7zxa.dll"));

                    bundledBackendDir = extractBundledResourcesFromFile("backend.7z");
                    bundledRubyDir    = extractBundledResourcesFromFile("ruby-1.9.3.7z");
                    bundledNodeDir    = extractBundledResourcesFromFile("node-0.8.12.7z");

                    App.Current.Dispatcher.Invoke(DispatcherPriority.Normal,
                        (Action)(() => { Callback();})
                    );
                })
            ));
            extractThread.IsBackground = true; // need for thread to close at application exit
            extractThread.Start();
        }

        private string extractBundledResourcesFromFile(string filename)
        {
            string sourceFile     = Path.Combine(resourcesDir, "bundled", filename);
            string timestampFile  = Path.Combine(extractedResourcesDir, Path.ChangeExtension(filename, "timestamp"));

            string destinationDir = Path.Combine(extractedResourcesDir, Path.GetFileNameWithoutExtension(filename));

            if (!File.Exists(timestampFile) || File.GetLastWriteTimeUtc(sourceFile) > File.GetLastWriteTimeUtc(timestampFile))
            {
                try
                {
                    Directory.Delete(destinationDir, true);
                }
                catch (DirectoryNotFoundException)
                {
                    // good!
                }

                var extractor = new SevenZipExtractor(sourceFile);

                // we typically have a properly-named root dir inside .7z itself, so extracting into destinationDir doesn't work
                extractor.ExtractArchive(extractedResourcesDir);
                extractor.Dispose();

                File.WriteAllBytes(timestampFile, new byte[0]);
            }

            return destinationDir;
        }
    }
}
