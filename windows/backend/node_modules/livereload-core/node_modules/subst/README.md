# subst.js

Synopsis:

    var subst = require('subst');
    var newValue = subst(value, data);

Replaces placeholders in strings:

    subst("cp $(src) $(dst)", { '$(src)': 'file1', '$(dst)': 'file2'});
    // returns: "cp file1 file2"

and arrays:

    subst(["perl", "-i$(ext)", "$(args)", "script.pl"], { '$(ext)': '.bak', '$(args)': ['-p', '-w'] });
    // returns: ["perl", "-i.bak", "-p", "-w", "script.pl"]

and objects:

    subst({cmd: "ls", "dir": "$(project)/lib"}, { '$(project)': '~/woot' })
    // returns: {cmd: "ls", dir: "~/woot/lib"}

To avoid prefixing and suffixing the keys, use `.wrap`:

    var subst = require('subst').wrap("$(", ")");
    subst("cp $(src) $(dst)", { src: 'file1', dst: 'file2'});
    // returns: "cp file1 file2"


## Installation

    npm install subst

## Running tests

    npm install               # just once
    npm test                  # see package.json for the test command
    REPORTER=dot npm test     # override the reporter

## Spec

    subst
      ✓ should substitute placeholders in string values
      ✓ should support keys with funny characters like $([{hello}])
      ✓ should substitute placeholders in array items
      ✓ should splice substituted array items into the value array
      ✓ should recurse into nested array items
      ✓ should substitute placeholders in object keys
      ✓ should substitute placeholders in object values
      ✓ should recurse into nested objects
      ✓ should pass through null values
      ✓ should pass through undefined values
      ✓ should pass through numeric values
      ✓ should pass through Date values
      ✓ should pass through custom objects
      .wrap('{', '}')
        ✓ should substitute placeholder '{foo}' with the value of key 'foo'

## License

© 2012, Andrey Tarantsov. Distributed under the MIT license.
