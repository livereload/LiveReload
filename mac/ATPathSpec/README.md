ATPathSpec
==========

Path matching library for Objective-C.

* Uses a flexible configurable syntax, every syntax feature can be enabled/disabled with a flag.
* Covered with tests using Xcode 5's XCUnit framework.
* Requires ARC.
* Licensed under MIT.

Synopsis:

    #import "ATPathSpec.h"

    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    BOOL matched = [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile];

Syntax flavors:

* `ATPathSpecSyntaxFlavorGlob`: shell-style glob, supporting `*` and `?` wildcards
* `ATPathSpecSyntaxFlavorGitignore`: 100% compatibility with `.gitignore`
* `ATPathSpecSyntaxFlavorExtended`: enables all ATPathSpec features; note that it's not fully compatible with gitignore because it has `ATPathSpecSyntaxOptionsRequireTrailingSlashForFolders` flag set

Syntax features (enabled via syntax flavors or individual feature flags):

* Escape special characters with backslashes (`ATPathSpecSyntaxOptionsAllowBackslashEscape`): `\!important.txt`
* Use newlines, commas and/or whitespace to separate multiple patterns with gitignore semantics described below (`ATPathSpecSyntaxOptionsAllowNewlineSeparator`, `ATPathSpecSyntaxOptionsAllowCommaSeparator`, `ATPathSpecSyntaxOptionsAllowWhitespaceSeparator`): `*.txt, *.html, !*READ*, README.txt`
* Use pipe for a union of several specs (`ATPathSpecSyntaxOptionsAllowPipeUnion`): `*.txt | *.html | (*.xml & !*build*)`
* Use ampersand for an intersection of several patterns (`ATPathSpecSyntaxOptionsAllowAmpersandIntersection`): `*.txt & !*READ*`
* Use parenthesizes to group subspecs (`ATPathSpecSyntaxOptionsAllowParen`): `foo & (bar | boz)`
* Use bang to negate expressions (`ATPathSpecSyntaxOptionsAllowBangNegation`): `*.txt & !README.*`
* Line comments start with an (unescaped) hash mark (`ATPathSpecSyntaxOptionsAllowHashComment`): `*.html # HTML files`
* Use `foo/` to match folders only (not configurable).
* Use `foo` to match files only (if ``ATPathSpecSyntaxOptionsRequireTrailingSlashForFolders` is specified) or to match files and folders (if the flag is not specified)
* If there's no slash character in the spec (aside from a possible trailing slash) and `ATPathSpecSyntaxOptionsMatchesAnyFolderWhenNoPathSpecified` flag is set, the pattern matches in any subfolder (like in gitignore); otherwise, without this flag set, such patterns only match in the root folder.


gitignore list semantics
------------------------

When you use newline, comma or whitespace separators together with bang negation, the resulting spec follows the semantics of gitignore, which can be summarized as “the last matching entry wins”. I.e.:

    *.txt
    *.html
    !*READ*
    README.txt

matches any text or HTML files, except any file names containing `READ`, but does match README.txt nevertheless.

Internally, a list like that is transformed into:

    ((*.txt | *.html) & !*READ*) | README.txt

which is what you'll get if you call `description` on the returned path spec object.

This applies to newline-separated, comma-separated and whitespace-separated lists.


Operator precedence
-------------------

There is no operator precedence; you cannot mix different operators in the same expression without parenthesizes.

(I'd love to automatically wrap newline-separated expressions into parenthesizes, so that newline would be the only operator with lower precendece, but I didn't get to that yet. Right now, you cannot mix newlines, comma and whitespace separators with any other operators as well.)


Extended flavor
---------------

The extended flavor has all syntax features enabled, so you can write stuff like:

    (*.txt *.html *README* !docs/*.txt) & !(~* | *.tmp)

Remember that extended flavor has `ATPathSpecSyntaxOptionsRequireTrailingSlashForFolders` enabled, so `.git` won't match the git subfolder, you need to use `.git/`.

Unlike other flavors which strive for compatibility with existing APIs, the extended flavor will be accumulating features as those are added to the library.


API
---

See [ATPathSpec/ATPathSpec.h](ATPathSpec/ATPathSpec.h).


License
-------

MIT license; see [LICENSE](LICENSE) file.
