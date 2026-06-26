Created by Slimm

RedM Cache Cleaner App
======================

This app provides a simple window for cleaning RedM cache folders for the Windows user who launches it. It automatically uses the current user's Windows profile and does not require editing paths manually.

What it cleans
--------------

After confirmation, the app can delete these RedM folders:

- cache
- server-cache
- server-cache-priv

There is also an optional checkbox for deleting:

- nui-storage

If nui-storage is selected, the app will ask for a separate confirmation before deleting it.

How to use
----------

1. Double-click "RedM Cache Cleaner.vbs" to launch the app.
2. Review the target RedM data folder shown in the app.
3. Click "Clean RedM Cache".
4. Confirm the cleanup when prompted.
5. If you selected "Also delete nui-storage", confirm that second prompt if you still want to delete it.

Included files
--------------

RedM Cache Cleaner.vbs
    Main double-click launcher. This opens the app without leaving a console window visible.

redm_cache_cleaner_w_background_windows.bat
    Fallback launcher. Use this if the VBS launcher does not work on your computer. A console window may appear briefly.

support_redm_cleaner_Gps1.ps1
    The actual PowerShell GUI app. Keep this file in the same folder as the launchers.

support_cleanup_universal.bat
    Universal batch support file. This is included as a simple script-based version/fallback.

Troubleshooting
---------------

If Windows SmartScreen or antivirus asks about the file, choose the option to allow it only if you trust where you received it from.

If the app does not open with "RedM Cache Cleaner.vbs", try double-clicking "redm_cache_cleaner_w_background_windows.bat" instead.

If PowerShell blocks the script, right-click the ZIP before extracting, choose Properties, check Unblock if available, click Apply, then extract the ZIP again.

If the app says the RedM data directory was not found, make sure RedM has been installed and run at least once for the current Windows user.

Recommended before cleaning
---------------------------

Close RedM before running the cleaner. If RedM is open, Windows may prevent some folders from being deleted.
