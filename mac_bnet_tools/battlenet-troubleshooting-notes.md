# Fixing Battle.net `BLZBNTAGT00000871` on macOS Tahoe

**Symptom:** Battle.net launcher shows *"We couldn't launch a program we needed to use"* with reference code `BLZBNTAGT00000871`, when clicking Update. Happens on any game (WoW retail and Classic alike) — not game-specific.

**Confirmed environment:** Apple M1 Max MacBook Pro, macOS Tahoe 26.6.2. Started after an update; previously working.

**Root cause:** Battle.net's `Switcher` self-update helper does an **"elevated launch"** (via the admin-password prompt) to swap a freshly-downloaded Agent build into place in-line. That elevated-launch call was failing at the OS level with error `-60031` — most likely macOS Tahoe (a very new release) tightening/removing support for the legacy privilege-elevation mechanism Blizzard's updater uses. This happens *before* any files are touched, which is why file/folder permissions were never the actual problem.

**Fix that worked:** a full clean manual uninstall + fresh reinstall of Battle.net from battle.net.com. A brand-new install doesn't need the broken in-place "elevated swap" path — it just installs the current Agent directly.

---

## The fix, step by step

1. Quit Battle.net. In Activity Monitor, force-quit any leftover `Agent`, `Switcher`, or `relauncher` processes.
2. Remove the app and its support files (macOS has no separate "Battle.net Uninstaller" utility — that's Windows-only):
   ```
   sudo rm -rf /Applications/Battle.net.app
   rm -rf ~/Library/Application\ Support/Battle.net
   sudo rm -rf /Users/Shared/Battle.net
   rm -f ~/Library/Preferences/com.blizzard.Battle.net.plist
   rm -rf ~/Library/Caches/com.blizzard.Battle.net
   ```
3. Check for and remove any stray privileged-helper registrations:
   ```
   find /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents \
     -iname "*blizzard*" -o -iname "*battle.net*"
   ```
   If anything's listed and loaded (`launchctl list | grep -i blizzard`), unload it first (`sudo launchctl bootout ...`) before deleting.
4. Empty the Trash, **restart the Mac** (clears cached launchd state referencing the old paths).
5. Download a fresh installer from battle.net.com and install normally.
6. Log in, install/re-add your game(s), and test an Update.

**Expected side effect:** a fresh install wipes `product.db`, so previously-installed games won't show as installed even if the game files are still on disk. Either let it download fresh, or use the launcher's "I already have this installed" / scan option to relink an existing game folder.

**Note on install location:** Battle.net's current Mac installer defaults to `/Users/Shared/Battle.net` for the Agent — this is normal, not a misconfiguration; don't chase it as a cause.

---

## What did *not* fix it (skip these if you hit `-60031` specifically)

All of the below were tried and ruled out — each is a reasonable thing to check for similar-looking Blizzard launch errors in general, but **none of them touch this specific `-60031` elevated-launch failure**, because the failure happens before macOS even gets to a file/permission check:

- Disabling Battle.net auto-updates
- Installing a second game (e.g. WoW Classic) alongside — sometimes appears to "help" by resetting state, but not reliable and not the real fix
- Gatekeeper block check (System Settings → Privacy & Security) — no block was present
- **App Management** permission (System Settings → Privacy & Security) — adding Battle.net/WoW here had no effect
- **Full Disk Access** — deduplicating stale "relauncher" entries had no effect
- **Login Items & Extensions** — background permission was already correctly enabled
- `chown`/`chmod`/ACL fixes on `/Users/Shared/Battle.net` and `~/Library/Application Support/Battle.net` — ownership was confirmed correct afterward but the error persisted unchanged
- Confirming the admin account used at the password prompt matches the logged-in user — was already the case

## Diagnostic techniques (useful for next time / other Blizzard-on-Mac issues)

- **`log stream` quoting gotcha:** Terminal can auto-convert straight quotes to smart quotes, which breaks `log stream`'s predicate parser (`Bad predicate` error). Turn off Smart Quotes (Terminal → Settings → Profiles → Text), or type the command fresh instead of pasting it.
- **Broad substring predicates catch noise:** `process CONTAINS "Agent"` also matches unrelated macOS system processes like `BiomeAgent`. Prefer dumping the full stream to a file and filtering after the fact:
  ```
  log stream --info --debug > ~/Desktop/bnet_log.txt
  # reproduce the issue, then Ctrl+C
  grep -i "blizzard\|battle.net" ~/Desktop/bnet_log.txt > ~/Desktop/bnet_filtered.txt
  ```
- **Check the app's own logs before macOS system logs.** This is what actually cracked it — Blizzard's Agent writes detailed, human-readable logs to `<Agent folder>/Logs/` (`bc-*.log`, `Switcher-*.log`), which named the exact failing operation and OS error code. macOS system logs are useful for corroboration but were mostly noise here.
- **Diff a folder's contents before/after a repro** (`ls -la` before, repro, `ls -la` after) to see precisely what a failing step does or doesn't touch — quickly ruled out several permission theories with near-zero effort.
- **Check for leftover privileged-helper registrations** when a permission problem seems to defy fixes:
  ```
  sudo launchctl list | grep -i blizzard
  find /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents -iname "*blizzard*"
  ```

## If it comes back

This looks like a **Blizzard-updater/macOS-Tahoe compatibility issue**, not a one-time local corruption — so a *future* Agent self-update could hit the same `-60031` failure again once Blizzard pushes a new Agent build, since it's the same in-place elevated-swap code path. If that happens:
- The fix is the same: repeat the clean uninstall/reinstall above.
- Worth filing a ticket with Blizzard support referencing `BLZBNTAGT00000871` and the exact log line (`Elevated launch failed ... -60031`) plus the macOS version — this is genuinely their bug to fix, and support may already be tracking it for Tahoe.

## Update 2026-09-15: confirmed recurring

The bug came back after a few days of normal use (a handful of app launches, no unusual action taken) — the reinstall is a working workaround, not a permanent fix. This is consistent with the "hits again on the next Agent self-update" theory above, not local corruption.

Since this laptop is managed remotely (VNC) and used day-to-day by someone who isn't going to debug this herself, the manual steps above have been turned into `Fix-BattleNet.command` in this repo:
- Double-click to run (self-elevates via `sudo`, asks for the normal login password).
- Automates steps 1–4 of the fix above (quit processes, remove app + support files + prefs + cache, clear stray LaunchAgents/LaunchDaemons, verify nothing's left) and opens the Battle.net download page for the manual reinstall step.
- Does **not** touch game installs — only the launcher itself.
- Logs to `/Users/Shared/BattleNetFixLogs/` so it can be reviewed remotely later.
- Has a stubbed `--nuke` mode (full wipe including WoW installs, for a true from-scratch reinstall) — not implemented yet, tabled for later.

Still open / to revisit: a more permanent root cause and fix (rather than repeat-the-workaround), possibly via the Blizzard support ticket route mentioned above, or further log analysis on the next occurrence to see if the failure signature has changed.
