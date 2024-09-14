#!/usr/bin/env bash

# Define date format functions
getFormat() {
  local base="%H:%M:%S"
  local unformatted="%Y-%m-%d $base"
  local formatted="%a, %b %d, %Y $base"
  
  case "$1" in
    b) echo "$base" ;;
    f) echo "$formatted" ;;
    u|*) echo "$unformatted" ;;
  esac
}

is_mac() { [[ "$OSTYPE" == "darwin"* ]]; }

getDateTime() {
  [ "$1" = "m" ] && [ ! -e "$2" ] && return 1

  local opt="${1:-r}"
  local ui="${2:-now}"
  local ff="$(getFormat f)"
  local fu="$(getFormat u)"
  
  if is_mac; then
    case "$opt" in
      t) date -j -f "$fu" "$ui" +%s ;;
      f) date -j -f "$fu" "$ui" +"$ff" ;;
      m) stat -f "%Sm" -t "$fu" "$ui" ;;
      r|*) date -j -f "$fu" "$ui" +"$fu" ;;
    esac
  else
    case "$opt" in
      t) date -d "$ui" +%s ;;
      f) date -d "$ui" +"$ff" ;;
      m) stat -c %y "$ui" ;;
      r|*) date -d "$ui" +"$fu" ;;
    esac
  fi
  
  return $?
}

# Replace newlines with a space and squeeze repeated spaces
sanitize_string() {
  echo "$1" | tr -s '\n ' ' '
}

clean_file_contents() {
  local file="$1"
  local template="template"
  local new_filename="${file/iife/user}"

  # Clean JavaScript file, remove comments and empty lines
  {
    cat "$template"
    sanitize_string "$(perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s*\n//gm' < "$file")"
  } > "$new_filename"

  rm -f "$file" && echo "$new_filename: ready to be published!"
}

# Process directory for matching files
process_directory() {
  local dir="$1"
  find "$dir" -type f -name "*iife.js" -print0 | while IFS= read -r -d '' file; do
    clean_file_contents "$file"
  done
}

# Run cleaning process on files or directories
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

# Run Sass for styling
runStyle() {
  local ext="*.scss"
  if [ -n "$(find . -type f -name "$ext")" ]; then
    local minify="--style=compressed"
    [ "$1" = "style:minify" ] || minify=""
    sass --load-path=node_modules --no-source-map $minify src/scss:src/assets
  fi
}

# Update commit message and cache changes
updateMsg() {
  touch "$commit_file"
  
  local last_checked=$(getFileModDT)
  local commit_data=$(compareDirectories "-newermt \"$last_checked\"")
  local commit_msg="${commit_data[0]}"
  local xCache="${commit_data[1]}"

  if [ -n "$(sanitize_string "$commit_msg")" ]; then
    echo "$commit_msg" > "$commit_file"
    git add . && git commit -q -F "$commit_file" > /dev/null
    createCache "${xCache[@]}"
  fi
}

# Find files while excluding certain paths
findFiles() {
  local find_cmd="find . -type f"
  
  # Exclude directories and files from search
  find_cmd+=" -not -path './node_modules/*' -not -path './.git/*' -not -path './.cache/*'"
  find_cmd+=" -not -name '$(basename "$0")' -not -name '$commit_file' -not -name 'package-lock.json'"

  [ -n "$*" ] && find_cmd+=" $*"
  
  eval "$find_cmd"
}

# Compare files in the directory with their cache
compareDirectories() {
  [ -d ".cache" ] || createCache

  local files_to_compare
  IFS=$'\n' read -r -d '' -a files_to_compare < <(findFiles "$@" && printf '\0')

  local msg=""
  local xList=()

  for file in "${files_to_compare[@]}"; do
    local rel_path="$(realpath --relative-to="." "$file")"
    local cache_file=".cache/$rel_path"

    if [ -f "$cache_file" ]; then
      local diffs
      diffs=$(diff --suppress-common-lines "$file" \
        "$cache_file" | sed '/^[0-9].*c[0-9].*/d')
      [ -z "$diffs" ] || msg+="$file\n$diffs\n" && xList+=("$file")
    else
      msg+="$file: not found in cache\n"
    fi
  done

  echo -e "$msg"
}

getFileModDT() {
  local input="${1:-$commit_file}"
  
  # Attempt to get the file modification date
  local mod_date
  
  if [ -f "$input" ]; then
    mod_date=$(getDateTime m "$input")
  else
    mod_date=$(getDateTime t "$input")
  fi
  
  # If the command fails (mod_date is empty or getDateTime returned an error), fallback to the current date
  if [ $? -ne 0 ] || [ -z "$mod_date" ]; then
    mod_date=$(getDateTime t)
  fi

  echo "$mod_date"
}

# Function to check if a string exists in an array
xCheck() {
  [ $# -gt 1 ] || return 1
  
  local str="$1"
  shift
  local array=("$@")
  
  if printf "%s\n" "${array[@]}" | grep -Fxq "$str"; then
    return 0  # String found
  else
    return 1  # String not found
  fi
}

# Create or update cache of files
createCache() {
  local proj_files=$(findFiles)
  mkdir -p ".cache"

  local xList=("$@")

  if [ -n "$proj_files" ]; then
    echo "$proj_files" | while IFS= read -r file; do
      if xCheck "$file" "${xList[@]}"; then
        local dir=$(realpath --relative-to="." "$file")
        local cache_dir="${dir//$(basename "$file")/}"
        mkdir -p ".cache/$cache_dir" && cp -f "$file" ".cache/$dir"
      fi
    done
  fi
}

# Main script logic
script_name="$(basename "$0")"
commit_file="COMMIT_MSG"

if [ $# -gt 0 ]; then
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
      echo "Invalid argument: $action"
      exit 1
      ;;
  esac
else
  createCache
fi