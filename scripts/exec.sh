#!/bin/env bash

[ "$#" -gt 0 ] || \
{ echo "Specify a script to run." \
    && exit 1; }
sanitize_string() {
  local input="$1"
  local no_newlines="${input//$'\n'/ }"
  local sanitized="${no_newlines//  / }"
  echo "$sanitized"
}

runClean() {
    clean_file_contents() {
        local file="$1"
        local template="$(dirname "$0")/template.txt"
        local newFilename="${file//iife/user}"

        {
            cat "$template"
            echo "$(sanitize_string "$(cat "$file" | perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s*\n//gm')")"
        } > "$newFilename"

        rm -f "$file"
        echo "Succesfully processed: $newFilename"
    }

    process_directory() {
        local dir="$1"
        echo "Processing directory: $dir"
        find "$dir" -type f -name "*iife.js" | while read -r file; do
            clean_file_contents "$file"
        done
    }

    removeExtras() {
        echo "$1" | sed 's/[^a-zA-Z0-9 ]//g' | tr -s ' '
    }

    processedArgs=$(removeExtras "$*")

    if [ -z "$processedArgs" ]; then
        filePath=("dist")
    else
        filePath=($processedArgs)
    fi

    for path in "${filePath[@]}"; do
        if [[ -f "$path" ]]; then
            clean_file_contents "$path"
        elif [[ -d "$path" ]]; then
            process_directory "$path"
        else
            echo "Warning: '$arg' is not a valid file or directory. Skipping."
        fi
    done
}

runStyle() {
    sass --load-path=node_modules --no-source-map -q $1 src/scss:src/assets
}

action="$1"
shift

case "$action" in
    clean)
        runClean "$@"
        ;;
    style)
        runStyle "$@"
        ;;
    *)
        echo "Unknown command: $action"
        exit 1
        ;;
esac
