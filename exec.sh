#!/usr/bin/env bash
pkgJsonParser() {
  local p="package.json"
  local field="${1%%.*}"
  local subField="${1##*.}"
  local value pre
  if which jq >/dev/null 2>&1; then
    if [ "$field" = "author" ]; then
      pre=".$field | if type == \"string\" then split(\" \") | "
      case "$subField" in
      name) value=$(jq -r "$pre.[0] else .$subField end" "$p") ;;
      email) value=$(jq -r "$pre.[1] else .$subField end" "$p") ;;
      url) value=$(jq -r "$pre.[2] else .$subField end" "$p") ;;
      *) value=$(jq -r ".$field" "$p") ;;
      esac
    else
      value=$(jq -r ".$field" "$p")
    fi
  else
    if [ "$field" = "author" ]; then
      local authorArray=$(grep "\"$field\":*" "$p" | sed -E "s/.*\"$field\": \"(.*?)\".*/\1/")
      read -r -a authorValuesArray <<<"${authorArray[*]}"
      if [ ${#authorValuesArray[@]} -gt 0 ]; then
        local index
        case "$subField" in
        name) index=0 ;;
        email) index=1 ;;
        url) index=2 ;;
        esac
        value="${authorValuesArray[$index]}"
      else
        value=$(grep -A 3 "\"$field\"" "$p" | grep "\"$subField\"" | cut -d'"' -f4)
      fi
    else
      value=$(grep "\"$field\"" "$p" | cut -d'"' -f4)
    fi
  fi
  [ -z "$value" ] && value="Not found" || value="${value//[()<>]/}"
  echo "$value"
}
generateUserScript() {
  local pkgName=$(pkgJsonParser "name")
  local pkgVersion=$(pkgJsonParser "version")
  local pkgDescription=$(pkgJsonParser "description")
  local authorName=$(pkgJsonParser "author.name")
  local authorEmail=$(pkgJsonParser "author.email")
  local authorUrl=$(pkgJsonParser "author.url")
  local website=$(pkgJsonParser "website")
  echo "// ==UserScript==
// @name               $pkgName
// @namespace          $authorUrl
// @version            $pkgVersion
// @description        $pkgDescription
// @author             $authorName
// @match              $website*
// @run-at             document-start
// ==/UserScript==
"
}
getDateFormat() {
  local base="%H:%M:%S"
  local unformatted="%Y-%m-%d $base"
  local formatted="%a, %b %d, %Y $base"
  case "$1" in
  b) echo "$base" ;;
  f) echo "$formatted" ;;
  u | *) echo "$unformatted" ;;
  esac
}
isMac() { [[ $OSTYPE == "darwin"* ]]; }
getDateTime() {
  [ "$1" = "m" ] && [ ! -e "$2" ] && return 1
  local formatOption="${1:-r}"
  local dateInput="${2:-now}"
  local formattedFormat="$(getDateFormat f)"
  local unformattedFormat="$(getDateFormat u)"
  if isMac; then
    case "$formatOption" in
    t) date -j -f "$unformattedFormat" "$dateInput" +%s ;;
    f) date -j -f "$unformattedFormat" "$dateInput" +"$formattedFormat" ;;
    m) stat -f "%Sm" -t "$unformattedFormat" "$dateInput" ;;
    r | *) date -j -f "$unformattedFormat" "$dateInput" +"$unformattedFormat" ;;
    esac
  else
    case "$formatOption" in
    t) date -d "$dateInput" +%s ;;
    f) date -d "$dateInput" +"$formattedFormat" ;;
    m) stat -c %y "$dateInput" ;;
    r | *) date -d "$dateInput" +"$unformattedFormat" ;;
    esac
  fi
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
  rm -f "$inputFile" && echo "$outputFile: ready to be published!"
}
processDirectory() {
  local directory="$1"
  find "$directory" -type f -name "*iife.js" -print0 | while IFS= read -r -d '' file; do
    cleanFileContents "$file"
  done
}
runClean() {
  local paths=("${@:-dist}")
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
  if find ./src -name "*.scss" -newermt "$lastModTimestamp" -print -quit | grep -q .; then
    local minifyFlag="--style=compressed"
    [ "$1" = "style:mini" ] || minifyFlag=""
    sass --load-path=node_modules --no-source-map -q $minifyFlag src/scss:src/assets
    echo "Successfully compiled scss files to css!"
  fi
}
updateCommitMessage() {
  local modified_files=($(getFiles))
  local deleted_files=($(getFiles d))
  local new_files=($(getFiles n))
  local final_mod_files=()
  local precedenceList=("${deleted_files[@]}" "${new_files[@]}")
  local default_length=169
  local metadata="$(getDateTime f)"'\n\n'
  for file in "${modified_files[@]}"; do
    if ! inArray "$file" "${precedenceList[@]}"; then
      final_mod_files+=("$file")
    fi
  done
  populate() {
    local title="$1"
    shift
    local list=("$@")
    if [ -n "$list" ]; then
      metadata+="$title:\n$(printf '\n- %s' "${list[@]}")\n"
    fi
  }
  populate "Modified files" "${final_mod_files[@]}"
  populate "Deleted files" "${deleted_files[@]}"
  populate "New files" "${new_files[@]}"
  for file in "${final_mod_files[@]}"; do
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
  # echo -e "$metadata" >"$commitFile"
  git add .
  git commit -q -m "$metadata"
  git push
}
getFiles() {
  baseCmd="git diff --name-only"
  case "$1" in
  n) baseCmd+=" --diff-filter=A" ;;
  d) baseCmd+=" --diff-filter=D" ;;
  esac
  eval "$baseCmd"
}
inArray() {
  [[ " ${@:2} " =~ " $1 " ]]
}
# commitFile=".git/COMMIT_EDITMSG"
# [ -f "$commitFile" ] || git init
case "$npm_lifecycle_event" in
clean) runClean && updateCommitMessage ;;
style*) runStyle "$npm_lifecycle_event" ;;
zee) runStyle && vite build && runClean && updateCommitMessage ;;
*) updateCommitMessage ;;
esac
