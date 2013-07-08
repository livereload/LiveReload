# Writing LiveReload editor plugins


## Outputs

    check not-found
    check broken
    check found
    open failed
    open ok


## Exit code

* 9: command-line parsing error
* 2: command failed
* 1: negative success (e.g. `--check` haven't found a usable editor)
* 0: positive success
