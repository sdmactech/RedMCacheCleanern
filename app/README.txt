Created by Slimm

RedM Cache Cleaner App - v3.0
=============================

A clean Windows utility for clearing RedM cache folders for the Windows user
who launches it. v3.0 is a Clean Rounded Style redesign (light and dark mode,
new app icon, smooth motion, RedM red accent) with the same cleanup as before,
plus a "Create Desktop Shortcut" button.

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
1. Double-click "RedM Cache Cleaner.vbs" to launch the app.
2. Optional: click "Create Desktop Shortcut" to launch it from your desktop
   next time.
3. Review the RedM data folder shown under Location.
4. Click "Clean RedM Cache".
5. Confirm the cleanup when prompted.
6. If you turned on "Also delete nui-storage", confirm that second prompt.

Included files
--------------
RedM Cache Cleaner.vbs
    Main double-click launcher. Opens the app with no visible console window.
redm_cache_cleaner_w_background_windows.bat
    Fallback launcher. Use if the VBS launcher does not work.
support_redm_cleaner_Gps1.ps1
    The WPF GUI app. Keep it in the same folder as the launchers.
RedM Cache Cleaner.ico / RedM Cache Cleaner.png
    The app icon, used by the window, taskbar and desktop shortcut.
support_cleanup_universal.bat
    Universal batch fallback / support script.

Troubleshooting
---------------
If Windows SmartScreen or antivirus asks about the file, only allow it if you
trust where you received it from.

If the app does not open from the VBS launcher, try the .bat launcher instead.

If PowerShell blocks the script, right-click the ZIP before extracting, choose
Properties, check Unblock if available, click Apply, then extract again.

If the app says the RedM data directory was not found, make sure RedM has been
installed and run at least once for the current Windows user.

If the desktop shortcut stops working, you probably moved the app's folder.
Open the app from its new location and click "Create Desktop Shortcut" again.

Recommended: Close RedM before cleaning so files are not locked.
