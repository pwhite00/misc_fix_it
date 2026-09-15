#!/bin/bash
#
# Battle.net Fix-It (repair mode)
#
# Quits Battle.net, removes the launcher and its saved files, checks for
# leftover Blizzard system helpers, verifies the cleanup, then opens the
# Battle.net download page for a fresh reinstall.
#
# Your game folders are NOT touched or deleted by this mode.
#
# Usage: double-click this file in Finder (you'll be asked for your Mac
# password), or run it from Terminal: ./Fix-BattleNet.command
#
set -uo pipefail

if [[ "${1:-}" == "--nuke" ]]; then
  echo "The full 'nuke and reinstall everything' mode (including WoW) isn't"
  echo "built yet. Run this without --nuke for the normal repair, or ask"
  echo "Peter to finish the nuke mode first."
  read -rp "Press Enter to close..." _
  exit 1
fi

LOG_DIR="/Users/Shared/BattleNetFixLogs"

# Re-launch with sudo if not already root, so the password prompt happens
# right here in the Terminal window that just opened.
if [[ $EUID -ne 0 ]]; then
  echo "This needs your Mac password to remove some files."
  echo "(Nothing will show on screen as you type it — that's normal.)"
  echo
  exec sudo /bin/bash "$0" "$@"
fi

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/fix-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

TARGET_USER="$(stat -f '%Su' /dev/console)"
TARGET_HOME="/Users/${TARGET_USER}"
TARGET_UID="$(id -u "$TARGET_USER")"

echo "=============================================="
echo " Battle.net Fix-It - repair mode"
echo " User: ${TARGET_USER}   Date: $(date)"
echo "=============================================="
echo
echo "This will:"
echo "  1. Quit Battle.net and its helper processes"
echo "  2. Remove the Battle.net app and its saved files"
echo "  3. Check for and remove any leftover Blizzard system helpers"
echo "  4. Confirm everything is cleaned up"
echo "  5. Open the Battle.net download page so you can reinstall"
echo
echo "Your games themselves will NOT be touched or deleted."
echo
read -rp "Press Enter to continue, or close this window to cancel..." _

echo
echo "--- Step 1: Quitting Battle.net ---"
pkill -i -f "/Applications/Battle.net.app" 2>/dev/null || true
pkill -i -f "/Users/Shared/Battle.net" 2>/dev/null || true
sleep 2

echo
echo "--- Step 2: Removing Battle.net files ---"
rm -rf "/Applications/Battle.net.app"
rm -rf "/Users/Shared/Battle.net"
rm -rf "${TARGET_HOME}/Library/Application Support/Battle.net"
rm -f  "${TARGET_HOME}/Library/Preferences/com.blizzard.Battle.net.plist"
rm -rf "${TARGET_HOME}/Library/Caches/com.blizzard.Battle.net"

echo
echo "--- Step 3: Checking for leftover Blizzard system helpers ---"
HELPER_DIRS=(
  "/Library/LaunchAgents"
  "/Library/LaunchDaemons"
  "${TARGET_HOME}/Library/LaunchAgents"
)
for dir in "${HELPER_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' plist; do
    label="$(basename "$plist" .plist)"
    echo "  Found: $plist"
    if [[ "$dir" == "/Library/LaunchDaemons" ]]; then
      launchctl bootout "system/${label}" 2>/dev/null || true
    else
      launchctl bootout "gui/${TARGET_UID}/${label}" 2>/dev/null || true
    fi
    rm -f "$plist"
    echo "  Removed."
  done < <(find "$dir" -maxdepth 1 \( -iname "*blizzard*" -o -iname "*battle.net*" \) -print0 2>/dev/null)
done

echo
echo "--- Step 4: Verifying cleanup ---"
LEFTOVER=0
for path in \
  "/Applications/Battle.net.app" \
  "/Users/Shared/Battle.net" \
  "${TARGET_HOME}/Library/Application Support/Battle.net"
do
  if [[ -e "$path" ]]; then
    echo "  WARNING: still present: $path"
    LEFTOVER=1
  fi
done
if pgrep -i -f "battle.net" >/dev/null 2>&1; then
  echo "  WARNING: a Battle.net-related process is still running."
  LEFTOVER=1
fi

if [[ $LEFTOVER -eq 0 ]]; then
  echo "  Cleanup verified - no leftover files or processes found."
else
  echo "  Some items could not be fully removed. Restarting the Mac before"
  echo "  reinstalling may clear them."
fi

echo
echo "--- Step 5: Opening the Battle.net download page ---"
sudo -u "$TARGET_USER" open "https://www.battle.net/download"
echo
echo "Download and run the Battle.net installer from the page that just"
echo "opened, then log in as usual. Your game folders were left in place,"
echo "so Battle.net should find them automatically - if not, use"
echo "'Scan for Games' / 'I already have this installed' after logging in."
echo
echo "Log saved to: $LOG_FILE"
echo "Done - you can close this window."
