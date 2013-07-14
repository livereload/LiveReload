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
    --check)
        if ! test -d "$app_path"; then
            echo "result: not-found"
            echo "'$app_path' does not exist."
            exit 1
        elif ! test -f "$subl_path"; then
            echo "result: broken"
            echo "'$subl_path' does not exist."
            exit 1
        else
            echo "result: found"
            echo "$app_path"
            exit 0
        fi;;
    --help | "")
        echo "Usage: SublimeText.sh --check"
        echo "   or: SublimeText.sh <file> [<line> [<column>]]"
        exit 9;;
esac

file="$1"
line="$2"
column="$3"

if test -n "$column"; then
    "$subl_path" "$file:$line:$column" || {
        echo "result: failed"
        exit 2
    }
else
    if test -n "$line"; then
        "$subl_path" "$file:$line" || {
            echo "result: failed"
            exit 2
        }
    else
        "$subl_path" "$file" || {
            echo "result: failed"
            exit 2
        }
    fi
fi

echo "result: ok"
