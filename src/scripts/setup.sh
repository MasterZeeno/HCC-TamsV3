#!/usr/bin/env bash

isInstalled() {
  if [ "$1" = "pkg" ]; then
    command -v "$2"
  else
    "$1" show "$2"
  fi
}

process_termux() {
  IFS=' ' read -r -a ARGS <<< "$*"
  PKG_MANAGER="${ARGS[0]}"
  REQUIRED_PKG="${ARGS[1]}"

  if ! isInstalled "$PKG_MANAGER" "$REQUIRED_PKG" > /dev/null 2>&1; then
    [ "${#ARGS[@]}" -gt 2 ] && COUNT=2 || COUNT=1
    PKGS=("${ARGS[@]:$COUNT}")
    yes | "$PKG_MANAGER" install "${PKGS[*]}"
  fi
}

pkgs=(
  "pkg chromedriver x11-repo tur-repo chromium"
  "pkg jq"
  "pkg pip python python-pip"
  "pip selenium==4.9.1"
  "pip python-dotenv"
  "pip requests"
)

yes | termux-setup-storage
yes | pkg update
yes | pkg upgrade

for pkg in "${pkgs[@]}"; do
  process_termux "$pkg"
done
