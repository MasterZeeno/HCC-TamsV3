#!/bin/bash
print_error() {
  printf "\033[1;31m%s\033[0m\n" "  ✖ $1"
}
print_success() {
  printf "\033[1;32m%s\033[0m\n" "  ✔ $1"
}
command_exists() {
  if [ $# -eq 2 ]; then
    if [ "$1" = "$apt" ] && [[ $2 =~ -repo ]]; then
      return 0
    else
      "$1" show "$2" > /dev/null 2>&1
    fi
  else
    command -v "$1" > /dev/null 2>&1
  fi
}
pkg_install() {
  for item in "$@"; do
    cmd="${item%%|*}"
    pkg="${item##*|}"
    if ! command_exists "$cmd" "${pkg%%=*}"; then
      if "$cmd" install "$pkg" -y > /dev/null 2>&1; then
        print_success "Installed $pkg successfully."
      else
        print_error "Failed to install $pkg. Please try again."
        exit 1
      fi
    fi
  done
}
install_needed_pkgs() {
  chromium="chromium"
  [ "$1" = "pkg" ] || chromium+="-browser"
  pkgs=(
    "$1|jq"
    "$1|python-pip"
    "$1|x11-repo"
    "$1|tur-repo"
    "$1|$chromium"
    "pip|selenium==4.9.1"
    "pip|python-dotenv"
    "pip|requests")
  pkg_install "${pkgs[@]}"
  print_success "All required packages installed."
  return 0
}
update_timestamp() {
  sed -i "1s/.*/$(printf '%s' "$date_now" | sed 's/[&/\]/\\&/g')/" "$update_info_file"
}
update_pkgs() {
  update_pkg_mngr="$1"
  line_count=$(wc -l < "$update_info_file")
  pkg_mngr="$(tail -n 1 "$update_info_file" 2> /dev/null)"
  if [ "$(uname)" != "Linux" ] && [ -z "$PREFIX" ]; then
    print_error "This script should run only on Termux or Ubuntu/Debian distros."
    return 1
  fi
  if [ "$update_pkg_mngr" = "true" ]; then
    "$pkg_mngr" update -y > /dev/null 2>&1 && "$pkg_mngr" upgrade -y > /dev/null 2>&1 && update_timestamp
  fi
  install_needed_pkgs "${pkg_mngr##*/}"
  return $?
}
check_if_updatable() {
  if ! ping -c 1 -W 5 8.8.8.8 > /dev/null 2>&1; then
    print_error "Please check your internet connection."
    exit 1
  fi
  interval_seconds=$((days_interval * 86400))
  diff=0
  update_pkg_mngr=true
  if [ -s "$update_info_file" ]; then
    last_updated="$(head -n 1 "$update_info_file")"
    diff=$((date_now - last_updated))
    [ "$diff" -ge "$interval_seconds" ] || update_pkg_mngr=false
  else
    echo -e "$date_now\n$(command -v pkg || command -v apt)" > "$update_info_file"
  fi
  if ! update_pkgs "$update_pkg_mngr"; then
    print_error "Package update/upgrade failed."
  fi
}
runPrepare() {
  days_interval="${1:-7}"
  date_now="$(date +%s)"
  update_info_file=".pkginfo"
  touch "$update_info_file"
  check_if_updatable
}
sanitizeAndClean() {
  local input="$1"
  local perl_cmd='perl -0777 -pe "
    s{/\*.*?\*/}{}gs;
    s/^\s+|\s+$//g;
    s/\s+/ /g;
    s/^\s*\n//gm;
    s/-bs-/-zee-/g;
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
  local pkgJson="$PWD/package.json"
  local field="${1%%.*}"
  local subField="${1##*.}"
  local -A subFields=(["name"]="0" ["email"]="1" ["url"]="2")
  local index="${subFields[$subField]}"
  local value
  if command_exists "jq"; then
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
  update_version && runStyle f && npx vite build && runClean
  
  local gitFiles=$(git diff --name-status)
  local metadata="$(pkgJsonParser "name") ✨\n$(pkgJsonParser "description")\n\n"
  metadata+="Author: $(pkgJsonParser "author.name") 🤴 ($(pkgJsonParser "author.url"))\n"
  metadata+="Date: $(git log -1 --format="%ci" | sed 's/ /T/') (PHT) 🕓\n"
  metadata+="\nWebsite: $(pkgJsonParser "website") (TamsV2)\n"
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
  git add . && git commit -q -m "$(echo -e "$metadata")" && git push -f -q
}
runClean() {
  local dist="$PWD/dist"
  mkdir -p "$dist"
  find "$dist" -nowarn -type f -name "*iife.js" -print0 | while IFS= read -r -d '' file; do
    local outputFile="${file/iife/user}"
    {
      generateUserScript
      sanitizeAndClean "$file"
    } > "$outputFile"
    rm -rf "$file" && print_success "${outputFile#$dist/}: ready to be published!"
  done
  checkCustomScripts
}
runStyle() {
  local lastUpdated=$(git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S')
  local styles=$(find ./src -name "*.scss" -newermt "$lastUpdated" -print -quit)
  [ "${1#style:}" = "f" ] && styles="force"
  
  if [ -n "$styles" ]; then
    local minifyFlag=""
    if [ "${1#style:}" = "m" ] || [ "${1#style:}" = "f" ]; then
      minifyFlag="--style=compressed"
    fi
    sass --load-path=node_modules --no-source-map -q $minifyFlag src/scss:src/assets
    print_success "Successfully compiled scss files to css!"
  fi
}
checkCustomScripts() {
  find "$PWD/scripts" -nowarn -type f -name "*.sh" -print0 | while IFS= read -r -d '' script; do
    # Check if the file is already executable, skip chmod if it is
    script=$(realpath --relative-to="$PWD" "$script")
    
    if [ ! -x "$script" ]; then
      chmod +x "$script" || { echo "Failed to make $script executable"; continue; }
    fi
  
    # Capture the stdout of the script
    output=$(bash "$script" 2>&1)
    
    # Check the return status
    if [ $? -eq 0 ]; then
      print_success "$output"
    else
      print_error "$output"
    fi
  done
}
update_version() {
  # Arguments
  local current_version="$(pkgJsonParser "version")"
  local version_type="${1:-patch}"
  local pkgjson="$PWD/package.json"

  # Split the version into major, minor, and patch
  IFS='.' read -r -a version_parts <<< "$current_version"
  local major="${version_parts[0]}"
  local minor="${version_parts[1]}"
  local patch="${version_parts[2]}"

  # Determine which version part to increment
  case "$version_type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
  esac

  # New version after the bump
  local new_version="$major.$minor.$patch"

  # Check if jq is installed
  if command_exists "jq"; then
    # Use jq to update the version
    jq ".version = \"$new_version\"" "$pkgjson" > tmp.$$.json && mv tmp.$$.json "$pkgjson"
  else
    # If jq is not installed, use sed as a fallback
    sed -i.bak -E "s/\"version\": \"[^\"]+\"/\"version\": \"$new_version\"/" "$pkgjson"
  fi
}
case "$1" in
  style*) runStyle "$1" ;;
  clean) runClean ;;
  push) commitAndPush "$2" ;;
  *) python3 "$(dirname "$0")/scrapper.py" ;;
esac
