# urlmatch.js

Synopsis:

    var urlmatch = require('urlmatch');
    if (urlmatch(pattern, url)) { ... }

Example:

    if (urlmatch("livereload.com", "http://livereload.com/help/")) {
      console.log("It works!");
    }

Pattern syntax:

* `livereload.com` — matches any URL on livereload.com (any protocol, any port, any path), but not its subdomains
* `*.livereload.com` — matches livereload.com and all its subdomains
* `http://livereload.com` — matches only HTTP protocol URLs (but any port is okay)
* `livereload.com/help` — matches only the specified path
* `livereload.com:80` — matches only the specified port; if the actual URL has no port number, the port is assumed to be 80 if the protocol is HTTP, and 443 if the protocol is HTTPS
* `https://*.livereload.com/admin/login` — combines the above to match `admin/login` path on livereload.com and any subdomain, only when accessed via HTTPS.

See the spec below for more examples.


## Installation

    npm install urlmatch

## Running tests

    npm install               # just once
    npm test                  # see package.json for the test command
    REPORTER=dot npm test     # override the reporter

## Spec

    urlmatch
      with pattern 'livereload.com'
        ✓ should match 'http://livereload.com'
        ✓ should match 'http://livereload.com/'
        ✓ should match 'http://livereload.com:80'
        ✓ should match 'http://livereload.com:3000'
        ✓ should match 'http://livereload.com/help/'
        ✓ should match 'https://livereload.com'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'http://foo.livereload.com'
        ✓ shouldn't match 'https://foo.livereload.com/'
      with pattern 'http://livereload.com'
        ✓ should match 'http://livereload.com'
        ✓ should match 'http://livereload.com/'
        ✓ should match 'http://livereload.com:80'
        ✓ should match 'http://livereload.com:3000'
        ✓ should match 'http://livereload.com/help/'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'https://livereload.com'
        ✓ shouldn't match 'https://foo.livereload.com/'
        ✓ shouldn't match 'http://foo.bar.livereload.com'
        ✓ shouldn't match 'http://foo.bar.livereload.com/help/'
      with pattern 'https://livereload.com'
        ✓ should match 'https://livereload.com'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'http://livereload.com'
      with pattern 'livereload.com:3000'
        ✓ should match 'http://livereload.com:3000'
        ✓ should match 'http://livereload.com:3000/help/'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'http://foo.bar.livereload.com'
        ✓ shouldn't match 'http://foo.bar.livereload.com/help/'
        ✓ shouldn't match 'https://livereload.com'
        ✓ shouldn't match 'http://livereload.com/'
        ✓ shouldn't match 'http://livereload.com:80'
      with pattern 'livereload.com:80'
        ✓ should match 'http://livereload.com/'
        ✓ should match 'http://livereload.com:80'
        ✓ should match 'http://livereload.com/help/'
        ✓ should match 'http://livereload.com:80'
        ✓ should match 'http://livereload.com:80/help/'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'https://livereload.com'
        ✓ shouldn't match 'http://livereload.com:3000'
        ✓ shouldn't match 'http://foo.bar.livereload.com'
        ✓ shouldn't match 'http://foo.bar.livereload.com/help/'
      with pattern '*.livereload.com'
        ✓ should match 'http://livereload.com/'
        ✓ should match 'https://livereload.com'
        ✓ should match 'http://foo.livereload.com'
        ✓ should match 'https://foo.livereload.com'
        ✓ should match 'http://foo.bar.livereload.com'
        ✓ shouldn't match 'http://example.com/'
      with pattern 'livereload.com/help'
        ✓ should match 'http://livereload.com/help/index.html'
        ✓ should match 'https://livereload.com/help/index.html'
        ✓ should match 'http://livereload.com:3000/help/index.html'
        ✓ should match 'http://livereload.com:3000/help/index.html'
        ✓ should match 'http://livereload.com:3000/help-topics/index.html'
        ✓ shouldn't match 'http://livereload.com/'
        ✓ shouldn't match 'http://example.com/'
        ✓ shouldn't match 'http://example.com/help/index.html'
        ✓ shouldn't match 'http://foo.livereload.com/help/index.html'

## License

© 2012, Andrey Tarantsov. Distributed under the MIT license.
