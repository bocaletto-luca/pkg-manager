#!/usr/bin/env bash
#
# pkg-menu.sh — Professional Interactive APT Package Manager
# Version: 2.1
# Author: Bocaletto Luca
# License: MIT
#
# Description:
#   Zero-dependency Bash script to manage APT on Debian/Ubuntu/Mint
#   with an interactive menu, logging, spinner, CLI flags, and “auto” mode.
#
# Usage:
#   sudo pkg-menu.sh [OPTIONS]
#
# Options:
#   -h, --help     Show help and exit
#   -v, --version  Show version and exit
#   -a, --auto     Run full update→upgrade→dist-upgrade→autoremove→autoclean
#
# Logs:
#   /var/log/pkg-menu-YYYYMMDD-HHMMSS.log
#

set -Eeuo pipefail
IFS=$'\n\t'

### ─── Configuration & Logging ────────────────────────────────────────────────
readonly VERSION="2.1"
readonly LOG_DIR="/var/log"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="${LOG_DIR}/pkg-menu-${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
exec > >(tee -a "${LOG_FILE}") 2>&1

### ─── Colors & Formatting ───────────────────────────────────────────────────
_RED=$(tput setaf 1);    _GREEN=$(tput setaf 2)
_YELLOW=$(tput setaf 3); _BLUE=$(tput setaf 4)
_BOLD=$(tput bold);      _RESET=$(tput sgr0)

info()    { printf "%s [INFO ]%s %s\n"    "${_BLUE}${_BOLD}" "${_RESET}" "$*"; }
success() { printf "%s [ OK  ]%s %s\n"    "${_GREEN}${_BOLD}" "${_RESET}" "$*"; }
warn()    { printf "%s [WARN ]%s %s\n"    "${_YELLOW}${_BOLD}" "${_RESET}" "$*"; }
error()   { printf "%s [ERROR]%s %s\n"    "${_RED}${_BOLD}" "${_RESET}" "$*"; }

### ─── Helpers ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${_BOLD}pkg-menu.sh${_RESET} — Interactive APT Manager (v${VERSION})

Usage: sudo $0 [OPTIONS]

Options:
  -h, --help       Show this help
  -v, --version    Show version
  -a, --auto       Run full maintenance (update → upgrade → dist-upgrade → autoremove → autoclean)
EOF
  exit 0
}

show_version() {
  echo "pkg-menu.sh version ${VERSION}"
  exit 0
}

require_root() {
  (( EUID == 0 )) || { error "Must run as root."; exit 1; }
}

spinner() {
  local pid=$1 delay=0.1 spin='|/-\' out
  while kill -0 "$pid" 2>/dev/null; do
    for c in $spin; do
      printf "\r${_YELLOW}%s${_RESET}" "$c"
      sleep $delay
    done
  done
  printf "\r"
}

apt_cmd() {
  local cmd=("$@")
  info "${cmd[*]}"
  "${cmd[@]}" -qq &
  spinner $!
  success "Done: ${cmd[*]}"
}

pause() {
  echo
  read -n1 -s -r -p "Press any key to return…"  
  echo
}

### ─── APT TASKS ───────────────────────────────────────────────────────────────
update_lists()       { apt_cmd apt-get update; }
upgrade_packages()   { apt_cmd DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; }
dist_upgrade()       { apt_cmd DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y; }
autoremove_packages(){ apt_cmd apt-get autoremove --purge -y; }
autoclean_cache()    { apt_cmd apt-get autoclean -y; }

search_package() {
  read -rp "Search keyword: " kw
  info "Searching for '${kw}'"
  apt-cache search "$kw" | sed '/^$/d'
}

install_package() {
  read -rp "Install package: " pkg
  apt_cmd DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
}

remove_package() {
  read -rp "Remove package: " pkg
  apt_cmd DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y "$pkg"
}

auto_all() {
  update_lists
  upgrade_packages
  dist_upgrade
  autoremove_packages
  autoclean_cache
}

### ─── CLI ARG PARSING ─────────────────────────────────────────────────────────
if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)    usage           ;;
    -v|--version) show_version    ;;
    -a|--auto)    require_root; auto_all; success "Auto maintenance complete."; exit 0 ;;
    *)            error "Unknown option: $1"; usage ;;
  esac
fi

### ─── Interactive Menu ────────────────────────────────────────────────────────
require_root

while true; do
  clear
  echo "${_BOLD}${_BLUE}============================================${_RESET}"
  echo "${_BOLD}${_BLUE}       APT Package Manager – v${VERSION}       ${_RESET}"
  echo "${_BOLD}${_BLUE}============================================${_RESET}"
  cat <<EOF

 1) Update package list
 2) Upgrade packages
 3) Dist-upgrade (full-upgrade)
 4) Search for a package
 5) Install a package
 6) Remove a package
 7) Autoremove orphaned packages
 8) Autoclean apt cache
 9) Run full maintenance (auto)
 0) Exit

EOF
  read -rp "Select [0–9]: " choice
  echo
  case "$choice" in
    1) update_lists        ; pause ;;
    2) upgrade_packages    ; pause ;;
    3) dist_upgrade        ; pause ;;
    4) search_package      ; pause ;;
    5) install_package     ; pause ;;
    6) remove_package      ; pause ;;
    7) autoremove_packages ; pause ;;
    8) autoclean_cache     ; pause ;;
    9) auto_all            ; pause ;;
    0) success "Exiting. Log: $LOG_FILE"; exit 0 ;;
    *) warn "Invalid choice"; pause ;;
  esac
done
