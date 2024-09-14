#!/usr/bin/env bash

getDateTime() {
  local opt="$1"
  shift
  local base="%H:%M:%S"
  local unformatted="%Y-%m-%d $base"
  local formatted="%a, %b %d, %Y $base"
  local date_input="${1:-now}"

  # Use a case for different formatting options
  case "$opt" in
    f) date -d "$date_input" +"$formatted" ;;
    r|*) date -d "$date_input" +"$unformatted" ;;
  esac
}

sanitize_string() {
  # Replace newlines with a space and squeeze repeated spaces
  echo "$1" | tr -s '\n ' ' '
}

clean_file_contents() {
  local file="$1"
  local template="template"
  local new_filename="${file//iife/user}"

  # Clean JavaScript file, remove comments and empty lines
  {
    cat "$template"
    sanitize_string "$(perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s*\n//gm' < "$file")"
  } > "$new_filename"

  # Remove old file and print success message
  rm -f "$file" && echo "  $new_filename: ready to be published!"
}

process_directory() {
  local dir="$1"
  find "$dir" -type f -name "*iife.js" -print0 | while IFS= read -r -d $'\0' file; do
    clean_file_contents "$file"
  done
}

runClean() {
  local file_paths=("${@:-dist}")

  for path in "${file_paths[@]}"; do
    if [ -f "$path" ]; then
      clean_file_contents "$path"
    elif [ -d "$path" ]; then
      process_directory "$path"
    else
      echo "Warning: '$path' is not a valid file or directory. Skipping." >&2
    fi
  done
}

runStyle() {
  local ext="*.scss"
  if [ -n "$(compareDirectories "-name \"$ext\"")" ]; then
    local minify="--style=compressed"
    [ "$1" = "style:minify" ] || minify=""
    sass --load-path=node_modules --no-source-map $minify src/scss:src/assets
  fi
}

updateMsg() {
  [ -f "$commit_file" ] || touch "$commit_file"

  local last_checked=$(head -n 1 "$commit_file")
  [ -n "$last_checked" ] || last_checked=$(getDateTime f)
  echo -e "$last_checked" > "$commit_file"

  local last_update_date=$(getDateTime r "$last_checked")
  local commit_msg=$(compareDirectories "-newermt \"$last_update_date\"")

  if [ -n "$commit_msg" ]; then
    echo -e "\n$commit_msg" >> "$commit_file" && createCache
  fi
}

findFiles() {
  local find_cmd="find . -type f"
  
  # Exclude directories and files from search
  find_cmd+=" -not -path './node_modules/*' -not -path './.git/*' -not -path './.cache/*'"
  find_cmd+=" -not -name '$(basename "$0")' -not -name '$commit_file' -not -name 'package-lock.json'"

  [ -n "$*" ] && find_cmd+=" $*"
  
  eval "$find_cmd"
}

compareDirectories() {
  [ -d ".cache" ] || createCache

  local files_to_compare
  IFS=$'\n' read -r -d '' -a files_to_compare < <(findFiles "$@" && printf '\0')

  local msg=""

  for file in "${files_to_compare[@]}"; do
    local rel_path="$(realpath --relative-to="." "$file")"
    local cache_file=".cache/$rel_path"

    if [ -f "$cache_file" ]; then
      local diffs
      diffs=$(diff --suppress-common-lines "$file" "$cache_file" | \
        sed '/^[0-9].*c[0-9].*/d; /^\(>\|<\) /!d; /^\s*\\ No newline at end of file/d')
      [ -z "$diffs" ] || msg+="$file\n$diffs\n"
    else
      msg+="$file: not found in cache\n"
    fi
  done

  echo -e "$msg"
}

createCache() {
  local proj_files=$(findFiles)
  mkdir -p ".cache"

  if [ -n "$proj_files" ]; then
    echo "$proj_files" | while IFS= read -r file; do
      local dir=$(realpath --relative-to="." "$file")
      local cache_dir="${dir//$(basename "$file")/}"
      mkdir -p ".cache/$cache_dir" && cp -f "$file" ".cache/$dir"
    done
  fi
}

script_name="$(basename "$0")"
commit_file="COMMIT-MSG"

action=$(sanitize_string "$1")
shift
processed_args=$(sanitize_string "$*")

case "$action" in
  clean)
    runClean "$processed_args" && updateMsg
    ;;
  style*)
    runStyle "$processed_args"
    ;;
  *)
    updateMsg && createCache
    ;;
esac
