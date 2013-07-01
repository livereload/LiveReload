/// <reference path="./d.ts/DefinitelyTyped/node/node.d.ts" />

declare module "foo" {

import events = require('events');

// test/fixtures/api.d.ts
export interface Message {
    command?: string;
}

// test/fixtures/foo.d.ts
export class Foo extends events.EventEmitter {
    constructor(input, output);
    public send(message): void;
}

// test/fixtures/bar.d.ts
export function bar(boz): any;

}
