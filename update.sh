#!/bin/bash

# Title: Ultimate Ubuntu Maintenance Script
# Author: Tyler Hodges
# Purpose: Keep your server clean, secure, fast, and healthy.

set -euo pipefail

LOG_FILE="$(dirname "$0")/maintenance.log"

# Function to handle any failure
on_failure() {
  echo "failure"
  exit 1
}

# Trap any command failure
trap 'on_failure' ERR

# Run everything inside a subshell, logging to file only (overwrite each time)
(
  echo "🚀 Starting full maintenance run at $(date)"
  echo "=================================================="

  # 1. Package Management
  echo "📦 Updating and upgrading system packages..."
  sudo -n apt update -y && sudo -n apt full-upgrade -y
  echo "🧹 Removing unused packages and cleaning cache..."
  sudo -n apt autoremove -y && sudo -n apt autoclean -y && sudo -n apt clean -y

  # 2. Snap & Flatpak Cleanup
  if command -v snap >/dev/null 2>&1; then
    echo "📦 Removing old Snap versions..."
    snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
      sudo -n snap remove "$snapname" --revision="$revision"
    done
  fi
  if command -v flatpak >/dev/null 2>&1; then
    echo "📦 Removing unused Flatpak packages..."
    flatpak uninstall --unused -y
  fi

  # 3. Security Updates
  echo "🛡️  Checking for security updates..."
  sudo -n unattended-upgrade --dry-run -d | grep -i "install" || echo "No security updates found."

  # 4. Rootkit Detection
  echo "🔍 Running rootkit check (rkhunter)..."
  if ! command -v rkhunter >/dev/null 2>&1; then
    echo "Installing rkhunter..."
    sudo -n apt install rkhunter -y
  fi
  sudo -n rkhunter --update
  sudo -n rkhunter --check --sk

  # 5. SUID/SGID Check
  echo "🔎 Searching for SUID/SGID files..."
  find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | tee /tmp/suid_sgid_files.txt

  # 6. Disk Health
  echo "💽 Checking disk health (SMART)..."
  if command -v smartctl >/dev/null 2>&1; then
    sudo -n smartctl --scan | awk '{print $1}' | while read -r dev; do
      echo "🔧 Device: $dev"
      sudo -n smartctl -H "$dev"
    done
  else
    echo "Installing smartmontools..."
    sudo -n apt install smartmontools -y
  fi

  # 7. Zombie Processes
  echo "🧟 Looking for zombie processes..."
  ZOMBIES=$(ps aux | awk '{ if ($8=="Z") print $0 }')
  if [ -n "$ZOMBIES" ]; then
    echo "⚠️  Zombie processes found:"
    echo "$ZOMBIES"
  else
    echo "✅ No zombie processes detected."
  fi

  # 8. Top resource hogs
  echo "🔥 Top 5 CPU-consuming processes:"
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6

  echo "🔥 Top 5 memory-consuming processes:"
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

  # 9. Disk Usage Summary
  echo "📊 Disk usage:"
  df -h /

  # 10. Journal Space Check
  echo "🧾 Checking journal space usage..."
  journalctl --disk-usage

  # 11. Uptime & Load
  echo "📈 Uptime and load average:"
  uptime

  echo "✅ All tasks complete at $(date)"
  echo "=================================================="

) > "$LOG_FILE" 2>&1  # Overwrites log each run

# Success message for n8n
echo "success"
exit 0
