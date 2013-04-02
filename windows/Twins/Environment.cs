using LiveReload;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;

namespace Twins
{
    public struct Configuration
    {
        public string ExecutablePath;
        public string ExecutableArguments;
    }

    public class TwinsEnvironment
    {
        public event Action LaunchComplete = delegate { };
        public event Action Crash = delegate { };
        
        private TwinsRPC rpc;
        private RootEntity root;

        public TwinsEnvironment(Configuration conjugation, TextWriter logWriter) {
            rpc = new TwinsRPC(conjugation.ExecutablePath, conjugation.ExecutableArguments, logWriter);
            rpc.Message += RPC_Message;
            rpc.LaunchComplete += RPC_LaunchComplete;
            rpc.Crash += RPC_Crash;
            rpc.Start();

            root = new Twins.RootEntity();
            root.OutgoingUpdate += (payload => rpc.Send("rpc", payload));
        }

        public void Dispose() {
            rpc.Dispose();
        }

        // TODO: move this far, far away from here (some day)
        public void UseWPF() {
            Twins.WPF.UIFacets.Register(root);
        }

        public void Expose(string name, object obj) {
            root.Expose(name, obj);
        }

        // send a non-object-related command (to be deprecated?)
        public void Send(string command, object arg) {
            rpc.Send(command, arg);
        }

        public void SimulateRaw(string payload) {
            RPC_Message(payload);
        }

        private void RPC_Message(string nodeLine) {
            var b = (object[])Json.Parse(nodeLine);
            string messageType = (string)b[0];
            if (messageType == "app.displayCriticalError") {
                var arg = (Dictionary<string, object>)b[1];

                var title = (string)arg["title"];
                var text = (string)arg["text"];
                var url = (string)arg["url"];
                var button = (string)arg["button"];

                MessageBox.Show(text, title, MessageBoxButton.OK, MessageBoxImage.Error);
                Application.Current.Shutdown();
            } else if (messageType == "rpc") {
                var arg = (Dictionary<string, object>)b[1];

                Twins.PayloadDelegate reply = null;
                if (b.Length > 2) {
                    string callback = (string)b[2];
                    reply = (payload => rpc.Send(callback, payload));
                }

                root.ProcessIncomingUpdate(arg, reply);
            }
        }

        private void RPC_Crash() {
            Crash();
        }

        private void RPC_LaunchComplete() {
            LaunchComplete();
        }
    }
}
