#!/usr/bin/env bash
getDateTime() {
  local formatOption="${1:-r}"
  local dateInput="${2:-now}"
  local unformattedFormat="%Y-%m-%d %H:%M:%S"
  local formattedFormat="%a, %b %d, %Y %H:%M:%S"
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
  eval "${dateArgs[*]}"
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
pkgJsonParser() {
  local field="${1%%.*}"
  local subField="${1##*.}"
  local -A subFields=(["name"]="0" ["email"]="1" ["url"]="2")
  local index="${subFields[$subField]}"
  local value
  if command -v jq > /dev/null 2>&1; then
    if [ "$field" = "author" ]; then
      local pre=".$field | if type == \"string\" then split(\" \") | "
      value=$(jq -r "$pre.[$index] else .$subField end" "$pkgJson")
    else
      value=$(jq -r ".$field" "$pkgJson")
    fi
  else
    if [ "$field" = "author" ]; then
      local authorArray=$(grep "\"$field\": *" "$pkgJson" | sed -E "s/.*\"$field\": \"(.*?)\".*/\1/")
      read -r -a authorValuesArray <<< "${authorArray[*]}"
      value="${authorValuesArray[$index]}"
    else
      value=$(grep "\"$field\"" "$pkgJson" | cut -d'"' -f4)
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
updatePkgVersion() {
  local arg="${1#*:}"
  local current_version=$(pkgJsonParser "version")
  IFS='.' read -r major minor patch <<< "${current_version#v}"
  case "$arg" in
    M) $((major++)) ;;
    m) $((minor++)) ;;
    p|*) $((patch++)) ;;
  esac
  local new_version="v$major.$minor.$patch"
  if command -v jq > /dev/null 2>&1; then
    jq --arg new_version "$new_version" '.version = $new_version' "$pkgJson" | tee "$pkgJson" > /dev/null
  else
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$p"
  fi
}
commitAndPush() {
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
  git add . && git commit -m "$metadata" && git push -q
}
runClean() {
  local dist=("${@:-dist}")
  find "$dist" -type f -name "*iife.js" -print0 | while IFS= read -r -d '' file; do
    local outputFile="${file/iife/user}"
    {
      generateUserScript
      sanitizeAndClean "$file"
    } > "$outputFile"
    echo "$outputFile: ready to be published!"
  done
}
runStyle() {
  local lastUpdated=$(git log -1 --format="%ci" | sed 's/ /T/')
  if find ./src -name "*.scss" -newermt "$lastUpdated" -print -quit | grep -q .; then
    local minifyFlag="--style=compressed"
    [ "$1" = "m" ] || minifyFlag=""
    sass --load-path=node_modules --no-source-map -q $minifyFlag src/scss:src/assets
    echo "Successfully compiled scss files to css!"
  fi
}
pkgJson="package.json"
case "${npm_lifecycle_event}" in
  style*) runStyle "$npm_lifecycle_event" ;;
  clean) runClean ;;
  push*) updatePkgVersion "$npm_lifecycle_event" && runClean && commitAndPush ;;
esac
