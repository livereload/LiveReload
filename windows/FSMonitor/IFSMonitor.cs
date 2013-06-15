using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LiveReload.FSMonitor {
    public interface IFSMonitor : IDisposable {
        bool Enabled { get; set; }
        void SetWhiteBlackList(List<string> whitelist, List<string> blacklist);
    }

    public interface IFSMonitorOwner {
        void OnFileChange(ICollection<string> relativePaths);
    }
}
