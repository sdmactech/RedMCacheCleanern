Created by Slimm

RedM Cache Cleaner App - v2.0
=============================

A clean Windows utility for clearing RedM cache folders for the Windows user
who launches it. v2.0 is a full visual redesign (modern WPF interface, Red Dead
inspired theme) with the exact same functionality as before.

What it cleans
--------------
After confirmation, the app can delete these RedM folders:
  - cache
  - server-cache
  - server-cache-priv

There is also an optional checkbox for deleting:
  - nui-storage
If nui-storage is selected, the app asks for a separate confirmation first.

How to use
----------
1. Double-click "RedM Cache Cleaner.vbs" to launch the app.
2. Review the target RedM data folder shown in the app.
3. Click "Clean RedM Cache".
4. Confirm the cleanup when prompted.
5. If you selected "Also delete nui-storage", confirm that second prompt.

Included files
--------------
RedM Cache Cleaner.vbs
    Main double-click launcher. Opens the app with no visible console window.
redm_cache_cleaner_w_background_windows.bat
    Fallback launcher. Use if the VBS launcher does not work.
support_redm_cleaner_Gps1.ps1
    The WPF GUI app. Keep it in the same folder as the launchers.
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

Recommended: Close RedM before cleaning so files are not locked.
