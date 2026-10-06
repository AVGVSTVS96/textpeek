# Installing TextPeek

You're setting up TextPeek on the user's Mac. It needs macOS 14+ and the Xcode Command Line Tools.

1. Check for the tools with `xcode-select -p`. If they're missing, run `xcode-select --install` and wait for the user to finish the installer.
2. Clone the repo somewhere the user keeps code (ask if you don't know), then run `make install` in it. This builds `TextPeek.app`, copies it to `~/Applications` and launches it.
3. Tell the user to:
   - allow the Notifications and Contacts prompts TextPeek just showed
   - open System Settings → Privacy & Security → Full Disk Access, turn on TextPeek, and choose Quit & Reopen
   - open System Settings → Notifications → Messages and turn off Allow notifications
4. Confirm it's running with `pgrep -x TextPeek`.
5. Tell the user to test it: a text from a contact should show only their name, and a verification code should show in full.

After a rebuild, macOS treats TextPeek as a new app, so the user has to turn Full Disk Access on again.
