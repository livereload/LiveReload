# How do I include or exclude files from monitoring?

You can add file masks like `*.cs` into `included.txt` and `excluded.txt` files in LiveReload's app data folder.

Right-click the version number in the title bar and choose “Open App Data Folder” to quickly open the folder. The files should be already there (LiveReload creates them for you on first launch).

Use a gitignore-like syntax:

* A blank line matches no files, so it can serve as a separator for readability.

* A line starting with a hash mark (`#`) serves as a comment. You can also put comments at the end of a line, preceded by a space and a hash mark (`_#`).

* An optional exclamation mark prefix (`!`) negates the pattern; any matching file included by a previous pattern will become excluded again.

* If the pattern ends with a slash (`/`), the slash is removed for the purpose of the following description, but it will only match a directory. In other words, `foo/` will match a directory `foo` and paths underneath it, but will not match a regular file.

* If the pattern does not contain a slash (`/`), LiveReload treats checks for a match against the file name.

* Otherwise, LiveReload checks for a match against the full path name. For example, "Documentation/*.html" matches "Documentation/git.html" but not "Documentation/ppc/ppc.html" or "tools/perf/Documentation/perf.html".

* `**` matches any number of subdirectories. For example, "Documentation/**/git.html" matches "Documentation/git.html", "Documentation/ppc/git.html" and "Documentation/new/ppc/git.html", but not "tools/perf/Documentation/git.html".

* A leading slash matches the beginning of the pathname. For example, "/*.c" matches "cat-file.c" but not "mozilla-sha1/sha1.c".
