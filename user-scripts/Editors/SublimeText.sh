#!/bin/bash
# LR-plugin-api: editor v1
# LR-plugin-author: Andrey Tarantsov <andrey@tarantsov.com>
# LR-editor-id: com.sublimetext.2
# LR-editor-name: Sublime Text 2
# LR-editor-app-id: com.sublimetext.2
# LR-editor-default-priority: 2

app_path="/Applications/Sublime Text 2.app"
subl_path="$app_path/Contents/SharedSupport/bin/subl"

case "$1" in
    --help | "")
        echo "Usage: SublimeText.sh --check"
        echo "   or: SublimeText.sh <file> [<line> [<column>]]"
        exit 9;;
esac

if ! test -d "$app_path"; then
    echo "result: not-found"
    echo "message: '$app_path' does not exist."
    exit 1
fi

if ! test -f "$subl_path"; then
    echo "result: broken"
    echo "message: '$subl_path' does not exist."
    exit 1
fi

if test "$1" == "--check"; then
    echo "result: found"
    echo "$app_path"
    exit 0
fi

location="$1"
if test -n "$2"; then
    location="$location:$2"
    if test -n "$3"; then
        location="$location:$3"
    fi
fi

if "$subl_path" "$location"; then
    echo "result: ok"
else
    echo "result: failed"
    exit 2
fi
