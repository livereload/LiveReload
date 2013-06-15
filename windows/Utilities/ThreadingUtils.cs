using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Threading;

namespace LiveReload.Utilities {
    public static class DispatcherExtensions {
        public static void InvokeAfterDelay(this Dispatcher dispatcher, TimeSpan delay, Action action) {
            DispatcherTimer timer = null;
            timer = new DispatcherTimer(delay, DispatcherPriority.Background, delegate {
                timer.Stop();
                action();
            }, dispatcher);
            timer.Start();
        }
    }

    public class DelayedInvocation : IDisposable {
        private DispatcherTimer timer;

        DelayedInvocation(DispatcherTimer timer) {
            this.timer = timer;
        }

        public void Restart() {
            timer.Stop();
            timer.Start();
        }

        public void Dispose() {
            timer.Stop();
        }
    }
}
