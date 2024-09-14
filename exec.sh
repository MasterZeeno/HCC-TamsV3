#!/usr/bin/env bash

# Get formatted/unformatted date and time
getDateTime() {
  local opt="$1"
  shift
  local base="%H:%M:%S"
  local unformatted="%Y-%m-%d $base"
  local formatted="%a, %b %d, %Y $base"
  
  # Default to "now" if no date argument is provided
  local date_input="${1:-now}"

  case "$opt" in
    f)
      date -d "$date_input" +"$formatted"
      ;;
    r|*)
      date -d "$date_input" +"$unformatted"
      ;;
  esac
}

# Clean up JavaScript files by removing IIFE wrappers and comments
clean_file_contents() {
  local file="$1"
  local template="template"
  local new_filename="${file//iife/user}"

  {
    cat "$template"
    sanitize_string "$(perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s*\n//gm' < "$file")"
  } > "$new_filename"

  rm -f "$file"
  echo "  $new_filename: ready to be published!"
}

# Process files in a directory
process_directory() {
  local dir="$1"
  find "$dir" -type f -name "*iife.js" -print0 | while IFS= read -r -d $'\0' file; do
    clean_file_contents "$file"
  done
}

# Handle the 'clean' command
runClean() {
  local file_paths
  if [ -z "$@" ]; then
    file_paths=("dist")
  else
    file_paths=("$@")
  fi

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

# Handle the 'style' command
runStyle() {
  if [ -n "$(compareDirectories -name "*.scss")" ]; then
    local minify="--style=compressed"
    [ "$1" = "style:minify" ] || minify=""
    sass --load-path=node_modules --no-source-map -q "$minify" src/scss:src/assets
  fi
}

# Update commit message and cache
updateMsg() {
  [ -f "$commit_file" ] || touch "$commit_file"
  
  local last_checked=$(head -n 1 "$commit_file")
  [ -n "$last_checked" ] || last_checked=$(getDateTime f)
  echo -e "$last_checked" > "$commit_file"
  
  local last_update_date=$(getDateTime r "$last_checked")
  local commit_msg=$(compareDirectories -newermt "$last_update_date")
  
  if [ -n "$commit_msg" ]; then
    echo -e "\n$commit_msg" >> "$commit_file" && \
    createCache
  fi
}

# Sanitize a string by removing newlines and extra spaces
sanitize_string() {
  echo "${1//$'\n'/ }" | tr -s ' '  # Replace newlines with space and squeeze repeated spaces
}

# Find files with optional exclusions
findFiles() {
  local root_dir="."
  local addnl_args=""
  
  if [ $# -gt 0 ]; then
    echo "$@" | while IFS= read -r arg; do
      case "$arg" in
        --root)
          root_dir="$2"
          shift 2
          ;;
        *)
          addnl_args="$*"
          ;;
      esac
    done
  fi
  
  # Default excluded directories and files
  local exclude_dirs=("node_modules" ".git" ".cache")
  
  local exclude_files=("$script_name" "$commit_file" "package-lock.json")

  local find_cmd="find $root_dir -type f"
  
  if [ "$root_dir" = "." ]; then
    for dir in "${exclude_dirs[@]}"; do
      find_cmd+=" -not -path \"./$dir/*\""
    done
  fi
  
  # Exclude files
  for file in "${exclude_files[@]}"; do
    find_cmd+=" -not -name \"$file\""
  done
  
  # Append additional arguments if provided
  [ -z "$addnl_args" ] || find_cmd+=" $addnl_args"
  
  # Return the find command output
  eval "$find_cmd"
}

# Create cache based on current state of files
createCache() {
  local proj_files=$(findFiles)
  
  # Prepare cache directory
  mkdir -p ".cache"
  
  # Copy modified files to cache if any exist
  if [ -n "$proj_files" ]; then
    echo "$proj_files" | while IFS= read -r file; do
      cp -f "$file" ".cache/"
    done
  fi
}

# Compare current and cached directories
compareDirectories() {
  [ -d ".cache" ] || createCache
  
  local files_to_compare=$(findFiles "$@")
  local cached_files=$(findFiles --root ".cache" "$@")
  
  local msg=""
  
  if [ -n "$files_to_compare" ]; then
    echo "$files_to_compare" | while IFS= read -r file; do
      
    done
  fi
  
  # diff <(echo "$find_files" | sort) <(echo "$cache_files" | sort)
}

script_name="$(basename "$0")"
commit_file="COMMIT-MSG"

# Main script logic
action=$(sanitize_string "$1")
shift
processed_args=$(sanitize_string "$*")
case "$action" in
  clean)
    runClean "$processed_args" && \
    updateMsg
    ;;
  style*)
    runStyle "$processed_args"
    ;;
  *)
    updateMsg && createCache
    ;;
esac