using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Threading;

namespace Twins
{
    public abstract class ModelBase : INotifyPropertyChanged, IDisposable
    {
        private bool disposed;

        public event PropertyChangedEventHandler PropertyChanged;

        public event Action Disposed = delegate { };

        private readonly CancellationTokenSource disposeCancellationTokenSource = new CancellationTokenSource();

        protected virtual void OnPropertyChanged(string name) {
            var p = PropertyChanged;
            if (p != null) {
                p(this, new PropertyChangedEventArgs(name));
            }
        }

        public void Dispose() {
            if (disposed)
                return;
            disposed = true;

            disposeCancellationTokenSource.Cancel();
            disposeCancellationTokenSource.Dispose();

            DisposeManagedResources();
        }

        protected virtual void DisposeManagedResources() {
        }

        protected CancellationToken DisposeCancellationToken {
            get {
                return disposeCancellationTokenSource.Token;
            }
        }
    }
}
