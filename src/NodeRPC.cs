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

        public NodeRPC(Dispatcher mainDispatcher)
        {
            dispatcher = mainDispatcher;
            Thread nodeThread = new Thread(new ThreadStart(NodeRun));
            nodeThread.IsBackground = true; // need for thread to close at application exit
            nodeThread.Start();
        }

        public void NodeStart()
        {
            string baseDir = System.AppDomain.CurrentDomain.BaseDirectory;
            if (!File.Exists(baseDir + "LiveReloadNodeJs.exe"))
            {
                baseDir = baseDir + @"..\..\";
            }
            process.StartInfo.FileName  = baseDir + @"res/LiveReloadNodejs.exe";
            process.StartInfo.Arguments = baseDir + @"res/node/test.js";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true; // node doesn't work without this line

            process.Start();

            writer = process.StandardInput;
            reader = process.StandardOutput;
        }

        public delegate void CustomNodeLineEventHandler(string s);
        public event CustomNodeLineEventHandler RaiseNodeLineEvent;

        public void NodeRun()
        {
            NodeStart();
            while (!reader.EndOfStream)
            {
                string nodeLine = reader.ReadLine();
                dispatcher.Invoke(DispatcherPriority.Normal,
                    (Action)(() => { RaiseNodeLineEvent(nodeLine); }));
            }
        }

        public void NodeSendLine(string message)
        {
            writer.WriteLine(message);
            writer.Flush();
        }
    }
}
