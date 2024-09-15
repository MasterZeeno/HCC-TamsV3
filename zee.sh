#!/usr/bin/env bash
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
  local pkgJson="package.json"
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
commitAndPush() {
  local default_length=169
  local gitFiles=$(git diff --name-status)
  local metadata="Repository updates ✨\n\n"
  metadata+="Author: $(pkgJsonParser "author.name") 🤴 ($(pkgJsonParser "author.name"))\n"
  metadata+="Date: $(git log -1 --format="%ci" | sed 's/ /T/') (PHT) 🕓\n"
  populate() {
    local str="$1"
    local -a fileList=$(echo "$gitFiles" | grep "^${str:0:1}" | cut -f2)
    if [ -n "${fileList[@]}" ]; then
      metadata+="\n$str:\n"
      for file in $(printf '%s\n' "${fileList[@]}"); do
        metadata+=" - $file\n"
      done
    fi
  }
  for list in "Modified files" "Deleted files" "New files"; do
    populate "$list"
  done
  metadata="${metadata:-'Forced push!!!'}"
  git add . && git commit -q -m "$(echo -e "$metadata")" && git push -q
  echo -e "$metadata"
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
case "$1" in
  style*) runStyle "$1" ;;
  clean) runClean ;;
  push*) runClean && commitAndPush ;;
esac
