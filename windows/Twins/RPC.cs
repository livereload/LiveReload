using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Threading;
using System.Windows;
using LiveReload;
using Twins.JSON;

namespace Twins
{
    public class TwinsRPC
    {
        private readonly string fileName;
        private readonly string arguments;
        private readonly TextWriter logWriter;

        private Process process = new Process();
        private StreamWriter writer;
        private StreamReader reader;
        private StreamReader stderrReader;
        private Dispatcher dispatcher = Application.Current.Dispatcher;
        private Thread runThread;
        private Thread stderrThread;
        private bool disposed = false;

        public event Action LaunchComplete;
        public event Action Crash;
        public event Action<string> Message;

        public TwinsRPC(string fileName, string arguments, TextWriter logWriter) {
            this.fileName = fileName;
            this.arguments = arguments;
            this.logWriter = logWriter;
        }

        public void Start() {
            runThread = new Thread(new ThreadStart(RunThread));
            runThread.IsBackground = true; // need for thread to close at application exit
            runThread.Start();
        }

        private void LaunchProcess() {
            process.StartInfo.FileName = fileName;
            process.StartInfo.Arguments = arguments;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true; // node doesn't work without this line
            process.StartInfo.StandardOutputEncoding = Encoding.UTF8;
            process.StartInfo.StandardErrorEncoding = Encoding.UTF8;

            process.Start();

            var job = new JobManagement.Job();
            job.AddProcess(process.Handle);

            var SaneUTF8 = new UTF8Encoding(false);  // UTF8 that does not emit BOM
            writer = new StreamWriter(process.StandardInput.BaseStream, SaneUTF8);
            reader = process.StandardOutput;
            stderrReader = process.StandardError;

            dispatcher.Invoke(DispatcherPriority.Normal,
                (Action)(() => { LaunchComplete(); })
            );

            stderrThread = new Thread(new ThreadStart(LogStandardErrorThread));
            stderrThread.IsBackground = true;
            stderrThread.Start();
        }

        private void RunThread() {
            LaunchProcess();
            while (!reader.EndOfStream) {
                string line = reader.ReadLine();

                logWriter.WriteLine("INCOMING: " + line);
                logWriter.Flush();

                if (line[0] == '[') {
                    dispatcher.Invoke(DispatcherPriority.Normal,
                        (Action)(() => { Message(line); })
                    );
                }
            }
            dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => {
                    if (!disposed)
                        Crash();
                })
            );
        }

        private void LogStandardErrorThread() {
            while (!stderrReader.EndOfStream) {
                string nodeLine = stderrReader.ReadLine();
                logWriter.WriteLine("STDERR: " + nodeLine);
                logWriter.Flush();
            }
        }

        public void SendRaw(string message) {
            logWriter.WriteLine("OUTGOING: " + message);
            logWriter.Flush();

            writer.WriteLine(message);
            writer.Flush();
        }

        public void Send(string command, object arg) {
            SendRaw(Json.Stringify(new object[] { command, arg }));
        }

        public void Dispose() {
            if (writer != null) {
                writer.Close();
                writer = null;
            }
            disposed = true;
        }
    }
}
