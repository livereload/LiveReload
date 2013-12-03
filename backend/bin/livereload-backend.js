#! /usr/bin/env node

process.title = "LiveReloadHelper";

global.LR = require('../config/env').createEnvironment();
// require('longjohn');

if (process.argv.indexOf('--console') >= 0) {
    Path = require('path');

    LR.rpc.init(process, process.exit, { callbackTimeout: 60000, consoleDebuggingMode: true });

    LR.app.api.init({
        pluginFolders: [ Path.join(__dirname, "../../LiveReload/Compilers")],
        preferencesFolder: process.env['TMPDIR']
    }, function(err) {
        if (err) throw err;
    });
} else {
    LR.rpc.init(process, process.exit);
}

