# Fixing Battle.net When It Won't Update

Live doc: https://docs.google.com/document/d/1C6tS66DZJk20AKf4DfeWij0cG8sP6PDcPzlWsLnlcYU/edit?tab=t.0
(the doc is the source of truth for what Emma sees; this file is a copy kept with the script for reference)

## When to use this

Use this if Battle.net shows a message like "We couldn't launch a program we needed to use" (it may mention a code like BLZBNTAGT00000871) when you click Update, or Battle.net just seems stuck/broken when trying to launch a game.

This is a known, repeatable Battle.net bug — not something you did wrong, and not something wrong with your computer.

## Before you start

- Save and close anything you're in the middle of.
- Your games will NOT be deleted or affected. This only resets the Battle.net app itself.

## Steps

1. Quit Battle.net if it's open.
2. Find and double-click Fix-BattleNet.command (located: on the Desktop).
3. A black Terminal window will pop up. This is normal — don't close it.
4. It will ask for your Mac password to remove some files.
   - Type your normal login password and press Return.
   - Uses normal password rules so you won't see the password when you type it
5. Press Return again when it asks you to confirm.
6. Wait. It'll print out a few steps as it works — this takes under a minute.
7. When it says Done - you can close this window, your browser will already have opened the Battle.net download page.
8. On that page, you can click Download or check your Downloads folder to see if you already have Battle.net-Setup, then open and run the installer like you would for any new app.
9. Once it's installed, log in to Battle.net like normal.
10. Your games should already show up. But if they don't or the search for games option doesn't find them during setup you can choose install like normal.

This tool only removes battle.net launcher files so the game files are all still there. If during the game install you can probably still click play and play.

## If something looks different than described above

Let me know and I can have a look. If it's at a weird time feel free to grab a screen shot for me (CMD + Shift + 3 for full screen or 4 to drag and select)

## Things you don't need to worry about

- The Terminal window is the script working — but other than watching for when it prompts for password you can ignore the output if you wish.
- This tool keeps a log file of what it did (for me to check later) — you don't need to do anything with it.
