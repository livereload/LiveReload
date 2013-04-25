# How do I include or exclude files from monitoring?

You can add file masks like `*.cs` into `included.txt` and `excluded.txt` files in LiveReload's app data folder.

Depending on your OS, the folder might be located at:

* `C:\Users\YourUserName\AppData\Roaming\LiveReload\` (Vista, Win 7, Win 8)
* `C:\Documents and Settings\YourUserName\Application Data\LiveReload\` (Win XP)

These files use a gitignore-like syntax and should be already there (LiveReload creates them for you on first launch).
