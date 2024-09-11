#!/bin/env bash

# Function to uncomment the content of a file
clean_file_contents() {
  local file="$1"
  local ext="${file##*.}"
  local dest="$(dirname "$0")/tamper-monkey"
  local template="${dest}/tamper-monkey.template.js"
  local output="${dest}/tams/${file##*/}"
  output="${output%.*}.user.${ext}"

  # Clean the file contents by removing multi-line comments and blank lines
  local cleaned="$(printf '%s ' $(cat "$file") | perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s*\n//gm')"

  # Write the result to the output file
  {
    cat "$template"
    printf "\t%s" "$cleaned"
    printf '\n})();'
  } > "$output"

  echo "Processed file saved to: tams/${output##*/}"
}

# Function to find and process target files in a directory recursively
process_directory() {
  local dir="$1"
  echo "Processing directory: $dir"
  find "$dir" -type f -name "*.js" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.css" | while read -r file; do
    clean_file_contents "$file"
  done
}

# If no arguments are passed, use "dist/assets" as the default directory
[[ $# -eq 0 ]] && filePath=("dist/assets") || filePath=("$@")

# Loop through all arguments
for path in "${filePath[@]}"; do
  if [[ -f "$path" ]]; then
    clean_file_contents "$path"
  elif [[ -d "$path" ]]; then
    process_directory "$path"
  else
    echo "Warning: '$arg' is not a valid file or directory. Skipping."
  fi
done