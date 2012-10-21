using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using SevenZip;

namespace LiveReload
{
    public partial class App
    {
        private void extractBundledResources()
        {
            SevenZipExtractor.SetLibraryPath(Path.Combine(resourcesDir, "7z.dll"));

            extractBundledResourcesFromFile("backend.7z");
        }

        private void extractBundledResourcesFromFile(string filename)
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
                // TODO: make this an async call, show progress info, delay backend launching
                extractor.ExtractArchive(extractedResourcesDir);
                extractor.Dispose();

                File.WriteAllBytes(timestampFile, new byte[0]);
            }
        }
    }
}
