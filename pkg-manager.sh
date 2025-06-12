#!/usr/bin/env bash
#
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
```
