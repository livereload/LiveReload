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
        Process process = new Process();
        StreamWriter writer;
        StreamReader reader;
        Dispatcher dispatcher;
        string baseDir;

        public event Action         NodeStartedEvent;
        public event Action<string> NodeMessageEvent;

        public NodeRPC(Dispatcher mainDispatcher, string baseDir_)
        {
            baseDir = baseDir_;
            dispatcher = mainDispatcher;
            Thread nodeThread = new Thread(new ThreadStart(NodeRun));
            nodeThread.IsBackground = true; // need for thread to close at application exit
            nodeThread.Start();
        }

        public void NodeStart()
        {
            process.StartInfo.FileName  = baseDir + @"res/LiveReloadNodejs.exe";
            process.StartInfo.Arguments = baseDir + @"backend/bin/livereload.js rpc server";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true; // node doesn't work without this line

            process.Start();

            writer = process.StandardInput;
            reader = process.StandardOutput;
            NodeStartedEvent();
        }

        public void NodeRun()
        {
            NodeStart();
            while (!reader.EndOfStream)
            {
                string nodeLine = reader.ReadLine();
                if (nodeLine[0] == '[')
                {
                    dispatcher.Invoke(DispatcherPriority.Normal,
                        (Action)(() => { NodeMessageEvent(nodeLine); }));
                }
            }
        }

        public void NodeMessageSend(string message)
        {
            writer.WriteLine(message);
            writer.Flush();
        }
    }
}
