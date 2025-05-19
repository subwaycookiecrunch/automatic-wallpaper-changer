$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Wallpaper Changer.lnk")
$Shortcut.TargetPath = "C:\Users\raj97\WallpaperChanger\RunWallpaperChanger.bat"
$Shortcut.WorkingDirectory = "C:\Users\raj97\WallpaperChanger"
$Shortcut.Description = "Launch Wallpaper Changer Application"
$Shortcut.IconLocation = "shell32.dll,43"  # Use a system icon that looks like a photo
$Shortcut.Save()

Write-Host "Desktop shortcut created successfully!" 