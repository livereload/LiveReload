using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace Twins.WPF
{
    public partial class TwinsDebugger : Window, ITwinsDebugger
    {
        private readonly TwinsEnvironment environment;

        public TwinsDebugger(TwinsEnvironment environment) {
            this.environment = environment;

            InitializeComponent();
            
            DataContext = new TwinsDebuggerViewModel(environment);
            ViewModel.PropertyChanged += ViewModel_PropertyChanged;
        }

        public TwinsDebuggerViewModel ViewModel {
            get {
                return (TwinsDebuggerViewModel)DataContext;
            }
        }

        private void SendPayload_Click(object sender, RoutedEventArgs e) {
            environment.SimulateRaw(ViewModel.Payload);
        }

        void ViewModel_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e) {
        }

        public void ShowDebugger() {
            Show();
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e) {
            e.Cancel = true;
            Hide();
        }
    }

    public class TwinsDebuggerViewModel : ModelBase
    {
        private string payload;

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
    }
}
