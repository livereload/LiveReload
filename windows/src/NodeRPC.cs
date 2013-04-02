using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Threading;

namespace LiveReload
{
    class NodeRPC
    {
        private Process process = new Process();
        private StreamWriter writer;
        private StreamReader reader;
        private StreamReader stderrReader;
        private Dispatcher dispatcher = App.Current.Dispatcher;
        private string nodeDir;
        private string backendDir;
        private TextWriter logWriter;
        private Thread nodeThread;
        private Thread stderrThread;
        private bool disposed = false;

        public event Action         NodeStartedEvent;
        public event Action         NodeCrash;
        public event Action<string> NodeMessageEvent;

        public NodeRPC(string nodeDir_, string backendDir_, TextWriter logWriter_)
        {
            nodeDir = nodeDir_;
            backendDir = backendDir_;
            logWriter = logWriter_;
        }

        public void Start()
        {
            nodeThread = new Thread(new ThreadStart(NodeRun));
            nodeThread.IsBackground = true; // need for thread to close at application exit
            nodeThread.Start();
        }

        private void NodeStart()
        {
            process.StartInfo.FileName = Path.Combine(nodeDir, @"LiveReloadNodejs.exe");
            process.StartInfo.Arguments = "\"" + (Path.Combine(backendDir, "bin/livereload.js") + "\" " + "rpc server");
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
                (Action)(() => { NodeStartedEvent(); })
            );

            stderrThread = new Thread(new ThreadStart(CopyNodeStderrToLog));
            stderrThread.IsBackground = true;
            stderrThread.Start();
        }

        private void NodeRun()
        {
            NodeStart();
            while (!reader.EndOfStream)
            {
                string nodeLine = reader.ReadLine();

                logWriter.WriteLine("INCOMING: " + nodeLine);
                logWriter.Flush();
                //Console.WriteLine("INCOMING: " + nodeLine);
                //Console.WriteLine(fastJSON.Json.Instance.Beautify(nodeLine));

                if (nodeLine[0] == '[')
                {
                    dispatcher.Invoke(DispatcherPriority.Normal,
                        (Action)(() => { NodeMessageEvent(nodeLine); })
                    );
                }
            }
            dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() =>
                {
                    if (!disposed)
                        NodeCrash();
                })
            );
        }

        private void CopyNodeStderrToLog()
        {
            while (!stderrReader.EndOfStream)
            {
                string nodeLine = stderrReader.ReadLine();
                logWriter.WriteLine("STDERR: " + nodeLine);
                logWriter.Flush();
            }
        }

        public void NodeMessageSend(string message)
        {
            logWriter.WriteLine("OUTGOING: " + message);
            logWriter.Flush();
            //Console.WriteLine("OUTGOING: " + message);
            //Console.WriteLine(fastJSON.Json.Instance.Beautify(message));

            writer.WriteLine(message);
            writer.Flush();
        }

        public void Send(string command, object arg)
        {
            NodeMessageSend(Json.Stringify(new object[] { command, arg }));
        }

        public void Dispose()
        {
            if (writer != null)
            {
                writer.Close();
                writer = null;
            }
            disposed = true;
        }
    }
}
