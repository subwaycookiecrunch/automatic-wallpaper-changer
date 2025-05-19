$WshShell = New-Object -ComObject WScript.Shell
$Startup = $WshShell.SpecialFolders.Item("Startup")
$Shortcut = $WshShell.CreateShortcut("$Startup\Wallpaper Changer.lnk")
$Shortcut.TargetPath = "C:\Users\raj97\WallpaperChanger\RunWallpaperChanger.bat"
$Shortcut.WorkingDirectory = "C:\Users\raj97\WallpaperChanger"
$Shortcut.Description = "Launch Wallpaper Changer Application"
$Shortcut.IconLocation = "shell32.dll,43"  # Use a system icon that looks like a photo
$Shortcut.Save()

Write-Host "Wallpaper Changer added to startup successfully!"
Write-Host "The application will now start automatically when you log in to Windows." 