Created by Slimm

RedM Cache Cleaner App - v3.0.1
===============================

A clean Windows utility for clearing RedM cache folders for the Windows user
who launches it. v3.0 is a Clean Rounded Style redesign (light and dark mode,
new app icon, smooth motion, RedM red accent) with the same cleanup as before.

What it cleans
--------------
After confirmation, the app can delete these RedM folders:
  - cache
  - server-cache
  - server-cache-priv

There is also an optional switch for deleting:
  - nui-storage
If nui-storage is selected, the app asks for a separate confirmation first.

How to use
----------
1. Double-click "RedM Cache Cleaner.bat" to launch the app. A small console
   window stays open behind the app while it runs; that's normal.
2. Optional: to launch from your desktop, right-click "RedM Cache Cleaner.bat",
   choose Show more options > Send to > Desktop (create shortcut).
3. Review the RedM data folder shown under Location.
4. Click "Clean RedM Cache".
5. Confirm the cleanup when prompted.
6. If you turned on "Also delete nui-storage", confirm that second prompt.

Included files
--------------
RedM Cache Cleaner.bat
    Double-click launcher for the app.
support_redm_cleaner_Gps1.ps1
    The WPF GUI app. Keep it in the same folder as the launcher.
RedM Cache Cleaner.ico / RedM Cache Cleaner.png
    The app icon, used by the window and taskbar.
support_cleanup_universal.bat
    Universal batch fallback / support script.

Troubleshooting
---------------
If Windows SmartScreen or antivirus asks about the file, only allow it if you
trust where you received it from.

If PowerShell blocks the script, right-click the ZIP before extracting, choose
Properties, check Unblock if available, click Apply, then extract again.

If the app says the RedM data directory was not found, make sure RedM has been
installed and run at least once for the current Windows user.

Recommended: Close RedM before cleaning so files are not locked.
