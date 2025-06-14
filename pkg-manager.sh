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
=======
# pkg-menu.sh — Interactive APT Package Manager
# Version: 1.0
# Author: Bocaletto Luca
# License: MIT
#
# Zero-dependency Bash script for Debian/Ubuntu/Mint
# Provides an interactive menu to manage APT tasks.

set -euo pipefail

# ─── COLORS ───────────────────────────────────────────────────────────────────
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# ─── REQUIRE ROOT ─────────────────────────────────────────────────────────────
if (( EUID != 0 )); then
  echo "${RED}Error:${RESET} This script must be run as root."
  exit 1
fi

# ─── PAUSE ─────────────────────────────────────────────────────────────────────
pause() {
  echo
  read -n1 -s -r -p "Press any key to continue..."
  echo
}

# ─── SHOW MENU ─────────────────────────────────────────────────────────────────
show_menu() {
  clear
  echo "${BLUE}========================================${RESET}"
  echo "${BLUE}       APT Package Manager Menu        ${RESET}"
  echo "${BLUE}========================================${RESET}"
  echo
  echo " 1) Update package list"
  echo " 2) Upgrade installed packages"
  echo " 3) Dist-upgrade (full-upgrade)"
  echo " 4) Search for a package"
  echo " 5) Install a package"
  echo " 6) Remove a package"
  echo " 7) Autoremove unused packages"
  echo " 8) Autoclean cached files"
  echo " 0) Exit"
  echo
}

# ─── MENU ACTIONS ───────────────────────────────────────────────────────────────
do_update() {
  echo "${YELLOW}[*] Updating package lists...${RESET}"
  apt-get update
  echo "${GREEN}[+] Package lists updated.${RESET}"
  pause
}

do_upgrade() {
  echo "${YELLOW}[*] Upgrading packages...${RESET}"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  echo "${GREEN}[+] Packages upgraded.${RESET}"
  pause
}

do_dist_upgrade() {
  echo "${YELLOW}[*] Performing dist-upgrade...${RESET}"
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  echo "${GREEN}[+] Dist-upgrade completed.${RESET}"
  pause
}

do_search() {
  read -rp "Enter search term: " term
  echo "${YELLOW}[*] Searching for '${term}'...${RESET}"
  apt-cache search "${term}"
  pause
}

do_install() {
  read -rp "Enter package to install: " pkg
  echo "${YELLOW}[*] Installing '${pkg}'...${RESET}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}"
  echo "${GREEN}[+] '${pkg}' installed.${RESET}"
  pause
}

do_remove() {
  read -rp "Enter package to remove: " pkg
  echo "${YELLOW}[*] Removing '${pkg}'...${RESET}"
  DEBIAN_FRONTEND=noninteractive apt-get remove -y "${pkg}"
  echo "${GREEN}[+] '${pkg}' removed.${RESET}"
  pause
}

do_autoremove() {
  echo "${YELLOW}[*] Removing unused packages...${RESET}"
  apt-get autoremove --purge -y
  echo "${GREEN}[+] Unused packages removed.${RESET}"
  pause
}

do_autoclean() {
  echo "${YELLOW}[*] Cleaning cached package files...${RESET}"
  apt-get autoclean -y
  echo "${GREEN}[+] Cache cleaned.${RESET}"
  pause
}

# ─── MAIN LOOP ─────────────────────────────────────────────────────────────────
while true; do
  show_menu
  read -rp "Choose an option [0-8]: " choice
  case "$choice" in
    1) do_update       ;;
    2) do_upgrade      ;;
    3) do_dist_upgrade ;;
    4) do_search       ;;
    5) do_install      ;;
    6) do_remove       ;;
    7) do_autoremove   ;;
    8) do_autoclean    ;;
    0) echo "Goodbye!"; exit 0 ;;
    *) echo "${RED}Invalid choice.${RESET} Try again."; pause ;;
  esac
done
