@echo off
echo Starting Wallpaper Changer...
start "" "C:\Users\raj97\WallpaperChanger\bin\Debug\net6.0-windows\WallpaperChanger.exe"

REM If the executable doesn't exist yet, try to compile it
if not exist "C:\Users\raj97\WallpaperChanger\bin\Debug\net6.0-windows\WallpaperChanger.exe" (
    echo Executable not found. Attempting to build the project...
    
    REM Try to find Visual Studio installation
    if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" (
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" "C:\Users\raj97\WallpaperChanger\WallpaperChanger.csproj" /Build "Debug|AnyCPU"
        start "" "C:\Users\raj97\WallpaperChanger\bin\Debug\net6.0-windows\WallpaperChanger.exe"
    ) else (
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" (
            "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" "C:\Users\raj97\WallpaperChanger\WallpaperChanger.csproj" /Build "Debug|AnyCPU"
            start "" "C:\Users\raj97\WallpaperChanger\bin\Debug\net6.0-windows\WallpaperChanger.exe"
        ) else (
            echo Visual Studio not found. Please install Visual Studio or .NET SDK to build the application.
            echo Or compile the application manually first.
            pause
        )
    )
) 