#! /usr/bin/env node

process.title = "LiveReloadHelper";

global.LR = require('../config/env').createEnvironment();

LR.rpc.init(process, process.exit);
