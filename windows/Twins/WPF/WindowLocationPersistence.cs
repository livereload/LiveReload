using LiveReload.Properties;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.IsolatedStorage;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Forms;
using Twins.JSON;

namespace Twins.WPF
{
    public interface IPreferenceStore
    {
        object Get(string key, object defaultValue = null);
        void Update(string key, object value);
    }

    public class IsolatedStoragePreferenceStore : IPreferenceStore
    {
        private readonly IsolatedStorageFile storage;
        private readonly string fileName;
        private readonly Encoding UTF8WithoutBOM = new UTF8Encoding(false);

        public IsolatedStoragePreferenceStore(IsolatedStorageFile storage, string fileName) {
            this.storage = storage;
            this.fileName = fileName;
        }

        public object Get(string key, object defaultValue = null) {
            var dictionary = ReadAll() as Dictionary<string, object>;
            object result = defaultValue;
            if (dictionary != null) {
                dictionary.TryGetValue(key, out result);
            }
            return result;
        }

        public void Update(string key, object value) {
            var dictionary = ReadAll() as Dictionary<string, object>;
            if (dictionary == null) {
                dictionary = new Dictionary<string, object>();
            }
            dictionary[key] = value;
            WriteAll(dictionary);
        }

        private object ReadAll() {
            try {
                using (var reader = new StreamReader(new IsolatedStorageFileStream(fileName, FileMode.Open, FileAccess.Read, FileShare.Read, storage), UTF8WithoutBOM)) {
                    var text = reader.ReadToEnd();
                    return Json.Parse(text);
                }
            } catch (Exception) {
                return null;
            }
        }

        private void WriteAll(object data) {
            try {
                var text = Json.Stringify(data, false);
                using (var writer = new StreamWriter(new IsolatedStorageFileStream(fileName, FileMode.Create, FileAccess.Write, FileShare.None, storage), UTF8WithoutBOM)) {
                    writer.WriteLine(text);
                }
            } catch (Exception e) {
                System.Diagnostics.Debug.WriteLine("Error saving preferences to isolated storage file '{0}': {1} {2}", fileName, e.GetType().FullName, e.Message);
            }
        }
    }

    public class WindowLocationPersistence
    {
        private readonly Window window;
        private readonly IPreferenceStore preferenceStore;
        private readonly string preferenceKey;

        public WindowLocationPersistence(Window window, IPreferenceStore preferenceStore, string preferenceKey) {
            this.window = window;
            this.preferenceStore = preferenceStore;
            this.preferenceKey = preferenceKey;

            window.LocationChanged += Window_SizeOrLocationChanged;
            window.SizeChanged += Window_SizeOrLocationChanged;
            window.StateChanged += Window_SizeOrLocationChanged;

            Load();
        }

        public string Memento {
            get {
                Rect rect = new Rect(window.Left, window.Top, window.Width, window.Height);
                if (window.WindowState != WindowState.Normal)
                    rect = window.RestoreBounds;
                return window.WindowState.ToString() + " " + rect.Left + " " + rect.Top + " " + rect.Width + " " + rect.Height;
            }
            set {
                if (string.IsNullOrWhiteSpace(value))
                    return;

                var components = value.Split(' ');
                if (components.Length < 5)
                    throw new ArgumentException("Invalid memento");

                Rect rect = new Rect(Convert.ToDouble(components[1]), Convert.ToDouble(components[2]), Convert.ToDouble(components[3]), Convert.ToDouble(components[4]));

                var winFormsRect = new System.Drawing.Rectangle((int)rect.Left, (int)rect.Top, (int)rect.Width, (int)rect.Height);
                var screen = Screen.FromRectangle(winFormsRect);
                if (screen.WorkingArea.Contains(winFormsRect)) {
                    // ideally we want to restore RestoreBounds when WindowState isn't Normal, but that property is read-only
                    window.Left = rect.Left;
                    window.Top = rect.Top;
                    window.Width = rect.Width;
                    window.Height = rect.Height;
                }
                
                if (components[0] == "Normal")
                    window.WindowState = WindowState.Normal;
                else if (components[0] == "Maximized")
                    window.WindowState = WindowState.Maximized;
                else if (components[0] == "Minimized")
                    window.WindowState = WindowState.Minimized;
                else
                    throw new ArgumentException("Invalid memento");
            }
        }

        private void Load() {
            var memento = preferenceStore.Get(preferenceKey) as string;
            if (memento != null)
                Memento = memento;
        }

        private void Save() {
            preferenceStore.Update(preferenceKey, Memento);
        }

        void Window_SizeOrLocationChanged(object sender, EventArgs e) {
            Save();
        }
    }
}
