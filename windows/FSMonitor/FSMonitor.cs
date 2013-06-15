using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Threading;
using LiveReload.Utilities;

namespace LiveReload.FSMonitor {
    // unless specified otherwise, all methods are invoked
    public class FSMonitorService : IFSMonitor {
        private readonly Dispatcher dispatcher;
        private readonly IFSMonitorOwner owner;
        private readonly TimeSpan coalescencePeriod;
        private readonly DispatcherTimer coalescenceTimer;
        private readonly string path;
        private bool disposed;
        private bool enabled = false;
        private FileSystemWatcher watcher;
        private ISet<string> queuedFileChanges = new HashSet<string>();

        public FSMonitorService(Dispatcher dispatcher, IFSMonitorOwner owner, string path, TimeSpan coalescencePeriod) {
            if (owner == null)
                throw new ArgumentNullException();
            if (path == null)
                throw new ArgumentNullException();
            this.dispatcher = dispatcher;
            this.owner = owner;
            this.path = path;

            coalescenceTimer = new DispatcherTimer(coalescencePeriod, DispatcherPriority.Background, delegate {
                coalescenceTimer.Stop();
                SendQueuedChanges();
            }, dispatcher);
        }

        public void Dispose() {
            if (disposed)
                return;

            disposed = true;
            DisposeMonitor();
        }

        public bool Enabled {
            get {
                return enabled;
            }
            set {
                if (enabled != value) {
                    enabled = value;
                    if (enabled)
                        CreateMonitor();
                    else
                        DisposeMonitor();
                }
            }
        }

        private void CreateMonitor() {
            watcher = new FileSystemWatcher(path);
            watcher.IncludeSubdirectories = true;
            watcher.Created += Watcher_Created;
            watcher.Renamed += Watcher_Renamed;
            watcher.Changed += Watcher_Changed;
            watcher.Deleted += Watcher_Deleted;
            watcher.EnableRaisingEvents = true;
        }

        private void DisposeMonitor() {
            if (watcher != null) {
                watcher.Dispose();
                watcher = null;
            }
        }

        // caution: called from thread pool
        private void Watcher_Deleted(object sender, FileSystemEventArgs e) {
            dispatcher.BeginInvoke((Action)delegate { OnChange(e.FullPath); });
        }

        // caution: called from thread pool
        private void Watcher_Changed(object sender, FileSystemEventArgs e) {
            dispatcher.BeginInvoke((Action)delegate { OnChange(e.FullPath); });
        }

        // caution: called from thread pool
        private void Watcher_Renamed(object sender, RenamedEventArgs e) {
            dispatcher.BeginInvoke((Action)delegate {
                OnChange(e.OldFullPath);
                OnChange(e.FullPath);
            });
        }

        // caution: called from thread pool
        private void Watcher_Created(object sender, FileSystemEventArgs e) {
            dispatcher.BeginInvoke((Action)delegate { OnChange(e.FullPath); });
        }

        private void OnChange(string path) {
            if (disposed)
                return;
            Console.WriteLine("Detected change: " + path);
            queuedFileChanges.Add(path);
            coalescenceTimer.Stop();
            coalescenceTimer.Start();
        }

        private void SendQueuedChanges() {
            // TODO: make the paths relative
            owner.OnFileChange(new List<string>(queuedFileChanges));
            queuedFileChanges.Clear();
        }

        public void SetWhiteBlackList(List<string> whitelist, List<string> blacklist) {
            // TODO
        }
    }
}
