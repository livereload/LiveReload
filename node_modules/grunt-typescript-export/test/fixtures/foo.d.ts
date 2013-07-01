/// <reference path="../d.ts/DefinitelyTyped/node/node.d.ts" />
import events = require('events');
export declare class Foo extends events.EventEmitter {
    constructor(input, output);
    public send(message): void;
}
