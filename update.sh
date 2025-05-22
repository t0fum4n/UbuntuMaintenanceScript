#!/bin/bash

# Title: Ubuntu Maintenance Script
# Author: Tyler Hodges
# Description: Updates, upgrades, cleans, and reports system health.

set -e

echo "🧼 Starting maintenance at $(date)"
echo "--------------------------------------------------"

# 1. Update package lists
echo "📦 Updating package list..."
sudo apt update -y

# 2. Upgrade all packages
echo "⬆️  Upgrading packages..."
sudo apt upgrade -y

# 3. Full upgrade
echo "📦 Performing full upgrade (includes kernel, etc.)..."
sudo apt full-upgrade -y

# 4. Remove unnecessary packages
echo "🧹 Autoremoving unused packages..."
sudo apt autoremove -y

# 5. Clean apt cache
echo "🧽 Cleaning up package cache..."
sudo apt autoclean -y
sudo apt clean

# 6. Snap package cleanup
if command -v snap >/dev/null 2>&1; then
  echo "📦 Cleaning up old Snap revisions..."
  snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision"
  done
fi

# 7. Flatpak cleanup
if command -v flatpak >/dev/null 2>&1; then
  echo "📦 Cleaning up old Flatpak versions..."
  flatpak uninstall --unused -y
fi

# 8. Check for failed services
echo "🔍 Checking for failed services..."
FAILED_SERVICES=$(systemctl --failed --no-legend)
if [ -n "$FAILED_SERVICES" ]; then
  echo "⚠️  Failed services detected:"
  echo "$FAILED_SERVICES"
else
  echo "✅ No failed services."
fi

# 9. Disk usage summary
echo "💽 Disk usage:"
df -h /

# 10. Done
echo "✅ Maintenance complete at $(date)"
echo "--------------------------------------------------"
