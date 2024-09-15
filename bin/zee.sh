#!/usr/bin/env bash
pkgJsonParser() {
  local field="${1%%.*}"
  local subField="${1##*.}"
  local -A subFields=(["name"]="0" ["email"]="1" ["url"]="2")
  local index="${subFields[$subField]}"
  local value
  if command -v jq >/dev/null 2>&1; then
    if [ "$field" = "author" ]; then
      local pre=".$field | if type == \"string\" then split(\" \") | "
      value=$(jq -r "$pre.[$index] else .$subField end" "$p")
    else
      value=$(jq -r ".$field" "$p")
    fi
  else
    if [ "$field" = "author" ]; then
      local authorArray=$(grep "\"$field\": *" "$p" | sed -E 's/.*"author": "(.*?)".*/\1/')
      read -r -a authorValuesArray <<<"${authorArray[*]}"
      value="${authorValuesArray[$index]}"
    else
      value=$(grep "\"$field\"" "$p" | cut -d'"' -f4)
    fi
  fi
  echo "${value:-Undefined}"
}
generateUserScript() {
  local -a pkgProperties=(
    "name" "author.url" "version"
    "description" "author.name" "website")
  local -a pkgValues
  for prop in "${pkgProperties[@]}"; do
    pkgValues+=("$(pkgJsonParser "$prop")")
  done
  echo "// ==UserScript==
// @name                ${pkgValues[0]}
// @namespace          ${pkgValues[1]}
// @version              ${pkgValues[2]}
// @description          ${pkgValues[3]}
// @author              ${pkgValues[4]}
// @match              ${pkgValues[5]}*
// @run-at              document-start
// ==/UserScript=="
}
getDateTime() {
  local formatOption="${1:-r}"
  local dateInput="${2:-now}"
  local baseFormat="%H:%M:%S"
  local unformattedFormat="%Y-%m-%d $baseFormat"
  local formattedFormat="%a, %b %d, %Y $baseFormat"
  local -a dateArgs
  if [[ $OSTYPE == "darwin"* ]]; then
    dateArgs=(date -j -f "$unformattedFormat" "$dateInput")
  else
    dateArgs=(date -d "$dateInput")
  fi
  case "$formatOption" in
    t) dateArgs+=(+%s) ;;
    f) dateArgs+=(+"$formattedFormat") ;;
    r | *) dateArgs+=(+"$unformattedFormat") ;;
  esac
  eval "${dateArgs[@]}"
}
sanitizeAndClean() {
  local input="$1"
  local perl_cmd='perl -0777 -pe "
    s{/\*.*?\*/}{}gs;
    s/^\s+|\s+$//g;
    s/\s+/ /g;
    s/^\s*\n//gm;
  "'
  if [ -n "$input" ] && [ -f "$input" ]; then
    eval "$perl_cmd < \"$input\""
  elif [ -n "$input" ]; then
    eval "echo \"$input\" | $perl_cmd"
  else
    eval "$perl_cmd"
  fi
}
cleanFileContents() {
  local inputFile="$1"
  local outputFile="${inputFile/iife/user}"
  {
    generateUserScript
    sanitizeAndClean "$inputFile"
  } >"$outputFile"
  echo "$outputFile: ready to be published!"
}
processDirectory() {
  local directory="$1"
  find "$directory" -type f -name "*iife.js" -print0 | while IFS= read -r -d '' file; do
    cleanFileContents "$file"
  done
}
runClean() {
  local -a paths=("${@:-dist}")
  for path in "${paths[@]}"; do
    if [ -f "$path" ]; then
      cleanFileContents "$path"
    elif [ -d "$path" ]; then
      processDirectory "$path"
    else
      echo "Warning: '$path' is not a valid file or directory. Skipping." >&2
    fi
  done
}
runStyle() {
  local lastUpdated=$(git log -1 --format="%ci" | sed 's/ /T/')
  if find ./src -name "*.scss" -newermt "$lastUpdated" -print -quit | grep -q .; then
    local minifyFlag="--style=compressed"
    [ "${1#style:}" = "m" ] || minifyFlag=""
    sass --load-path=node_modules --no-source-map -q $minifyFlag src/scss:src/assets
    echo "Successfully compiled scss files to css!"
  fi
}
updatePkgVersion() {
  local current_version=$(pkgJsonParser "version")
  IFS='.' read -r major minor patch <<<"${current_version#v}"
  local arg="${1#push:}"
  case "${arg:0:1}" in
    M) $((major++)) ;;
    m) $((minor++)) ;;
    p) $((patch++)) ;;
  esac
  local new_version="v$major.$minor.$patch"
  if command -v jq >/dev/null 2>&1; then
    jq --arg new_version "$new_version" '.version = $new_version' "$p" > "$p.tmp"
    mv -f "$p.tmp" "$p"
  else
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$p"
  fi
}
commitAndPush() {
  local arg="${1#push:}"
  local repo="${arg#*:}"
  local modFiles=()
  local default_length=169
  local gitFiles=$(git diff --name-status)
  local metadata="$(getDateTime f)"'\n\n'
  populate() {
    local str="$1"
    local -a fileList=$(echo "$gitFiles" | grep "^${str:0:1}" | cut -f2)
    [ "${str:0:1}" = "M" ] && modFiles=("${fileList[@]}")
    metadata+="$str:\n$(printf '\n- %s' "${fileList[@]}")\n"
  }
  for list in "Modified files" "Deleted files" "New files"; do
    populate "$list"
  done
  for file in "${modFiles[@]}"; do
    local diff_output=$(git diff HEAD~1 -- "$file")
    if [ -n "$diff_output" ]; then
      local max_length=$((${#diff_output} * 3 / 4))
      [ "$max_length" -lt "$default_length" ] || max_length="$default_length"
      local truncated_diff=$(echo "$diff_output" | head -c "$max_length")
      if [ "${#diff_output}" -ge "$max_length" ]; then
        truncated_diff+="..."
      fi
      metadata+="\nChanges in $file:\n\n$truncated_diff\n"
    fi
  done
  
  git add . && git commit -m "$metadata"
  [ "$repo" = "n" ] || git push -q
}

p="package.json"

case "$1" in
  clean)
    runClean
    ;;
  style*)
    runStyle "$1"
    ;;
  push*)
    p="$2"
    if updatePkgVersion "$1"; then
      runClean
      commitAndPush "$1"
    else
      echo "Failed to update package version for $1" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown argument: $arg" >&2
    exit 1
    ;;
esac
