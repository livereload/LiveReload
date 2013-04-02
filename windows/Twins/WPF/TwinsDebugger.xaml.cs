using System;
using System.Collections.Generic;
using System.IO.IsolatedStorage;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Shapes;

namespace Twins.WPF
{
    public partial class TwinsDebugger : Window, ITwinsDebugger
    {
        private readonly TwinsEnvironment environment;
        private readonly IsolatedStoragePreferenceStore preferenceStore;
        private Timer timer;

        public TwinsDebugger(TwinsEnvironment environment) {
            this.environment = environment;

            InitializeComponent();

            DataContext = new TwinsDebuggerViewModel(environment);
            ViewModel.PropertyChanged += ViewModel_PropertyChanged;

            preferenceStore = new IsolatedStoragePreferenceStore(IsolatedStorageFile.GetUserStoreForAssembly(), "TwinsDebuggerPreferences.json");
            ViewModel.Payload = (preferenceStore.Get("Payload") as string) ?? "";
            ViewModel.PayloadHistoryMemento = (preferenceStore.Get("PayloadHistory") as string) ?? "";
            new WindowLocationPersistence(this, preferenceStore, "DebuggerWindowLocation");
        }

        public TwinsDebuggerViewModel ViewModel {
            get {
                return (TwinsDebuggerViewModel)DataContext;
            }
        }

        private void SendPayload_Click(object sender, RoutedEventArgs e) {
            var payload = ViewModel.Payload;
            environment.SimulateRaw(payload);
            ViewModel.AddToHistory(payload);

            SendConfirmationMark.Visibility = Visibility.Visible;

            if (timer != null)
                timer.Dispose();
            timer = new Timer((state) => Application.Current.Dispatcher.Invoke(new Action(HideCheckmark)), null, TimeSpan.FromMilliseconds(250), TimeSpan.FromMilliseconds(-1));
        }

        private void HideCheckmark() {
            SendConfirmationMark.Visibility = Visibility.Hidden;
            timer.Dispose();
            timer = null;
        }

        private void ClearPayload_Click(object sender, RoutedEventArgs e) {
            ViewModel.Payload = "";
        }

        void ViewModel_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e) {
            if (e.PropertyName == "Payload") {
                preferenceStore.Update("Payload", ViewModel.Payload);
            } else if (e.PropertyName == "PayloadHistory") {
                preferenceStore.Update("PayloadHistory", ViewModel.PayloadHistoryMemento);
            }
        }

        public void ShowDebugger() {
            Show();
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e) {
            e.Cancel = true;
            Hide();
        }

        private void PayloadHistoryCombo_SelectionChanged(object sender, RoutedEventArgs e) {
            var combo = (ComboBox)sender;
            var payload = combo.SelectedItem as string;
            if (payload != null) {
                ViewModel.Payload = payload;
            }
        }
    }

    public class TwinsDebuggerViewModel : ModelBase
    {
        private string payload;
        private List<string> payloadHistory;
        private const int historySize = 20;

        // design-time only
        public TwinsDebuggerViewModel() {
        }

        public TwinsDebuggerViewModel(TwinsEnvironment environment) {
        }

        public string Payload {
            get {
                return payload;
            }

            set {
                if (payload != value) {
                    payload = value;
                    OnPropertyChanged("Payload");
                }
            }
        }

        public List<string> PayloadHistory {
            get {
                return payloadHistory;
            }
        }

        public void AddToHistory(string payload) {
            while (payloadHistory.Remove(payload))
                continue;
            payloadHistory.Insert(0, payload);
            if (payloadHistory.Count > historySize) {
                payloadHistory.RemoveRange(historySize, payloadHistory.Count - historySize);
            }
            OnPropertyChanged("PayloadHistory");
        }

        public string PayloadHistoryMemento {
            get {
                return string.Join("\n~~~~~\n", payloadHistory);
            }
            set {
                payloadHistory = value.Split(new string[] { "\n~~~~~\n" }, StringSplitOptions.RemoveEmptyEntries).ToList();
                OnPropertyChanged("PayloadHistory");
            }
        }
    }
}
