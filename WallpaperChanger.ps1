# WallpaperChanger.ps1
# A PowerShell script that changes Windows wallpaper every 30 seconds

Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper {
    public class Setter {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        
        public const int SPI_SETDESKWALLPAPER = 20;
        public const int SPIF_UPDATEINIFILE = 0x01;
        public const int SPIF_SENDCHANGE = 0x02;
        
        public static void SetWallpaper(string path) {
            SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
        }
    }
}
"@

# Create system tray icon
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create an icon in the system tray
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Visible = $true
$notifyIcon.Text = "Wallpaper Changer"

# Create a context menu with Open and Exit options
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$openMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$openMenuItem.Text = "Open Settings"
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Exit"
$contextMenu.Items.Add($openMenuItem)
$contextMenu.Items.Add($exitMenuItem)
$notifyIcon.ContextMenuStrip = $contextMenu

# Application state
$script:imageDirectory = $null
$script:imageFiles = @()
$script:currentIndex = 0
$script:isRunning = $false
$script:timer = $null

# Create a form for settings
$form = New-Object System.Windows.Forms.Form
$form.Text = "Wallpaper Changer"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create Select Folder button
$selectFolderButton = New-Object System.Windows.Forms.Button
$selectFolderButton.Location = New-Object System.Drawing.Point(20, 20)
$selectFolderButton.Size = New-Object System.Drawing.Size(150, 30)
$selectFolderButton.Text = "Select Images Folder"
$form.Controls.Add($selectFolderButton)

# Create Start/Stop button
$startStopButton = New-Object System.Windows.Forms.Button
$startStopButton.Location = New-Object System.Drawing.Point(20, 70)
$startStopButton.Size = New-Object System.Drawing.Size(150, 30)
$startStopButton.Text = "Start"
$form.Controls.Add($startStopButton)

# Create a status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(180, 20)
$statusLabel.Size = New-Object System.Drawing.Size(200, 80)
$statusLabel.Text = "Status: Not running`nNo folder selected"
$form.Controls.Add($statusLabel)

# Function to load image files from directory
function Load-ImageFiles {
    $script:imageFiles = @()
    if ($script:imageDirectory -and (Test-Path $script:imageDirectory)) {
        $extensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp")
        foreach ($ext in $extensions) {
            $script:imageFiles += Get-ChildItem -Path $script:imageDirectory -Filter $ext
        }
        # Shuffle the images
        $script:imageFiles = $script:imageFiles | Sort-Object { Get-Random }
        $script:currentIndex = 0
    }
}

# Function to change wallpaper
function Change-Wallpaper {
    if ($script:imageFiles.Count -eq 0) { return }
    
    try {
        $wallpaperPath = $script:imageFiles[$script:currentIndex].FullName
        [Wallpaper.Setter]::SetWallpaper($wallpaperPath)
        
        # Move to next image, wrap around when reaching the end
        $script:currentIndex = ($script:currentIndex + 1) % $script:imageFiles.Count
        
        # Update status
        $statusLabel.Text = "Status: Running`nFolder: $($script:imageDirectory)`nImages: $($script:imageFiles.Count)`nCurrent: $($script:currentIndex)"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error changing wallpaper: $_", "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Event handler for Select Folder button
$selectFolderButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder with wallpaper images"
    $result = $folderBrowser.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:imageDirectory = $folderBrowser.SelectedPath
        Load-ImageFiles
        $statusLabel.Text = "Status: Ready`nFolder: $($script:imageDirectory)`nImages: $($script:imageFiles.Count)"
        [System.Windows.Forms.MessageBox]::Show("Found $($script:imageFiles.Count) images in the selected folder.", 
            "Images Loaded", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Event handler for Start/Stop button
$startStopButton.Add_Click({
    if (-not $script:isRunning) {
        if (-not $script:imageDirectory -or $script:imageFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select a folder with images first.", 
                "No Images", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $script:isRunning = $true
        $startStopButton.Text = "Stop"
        
        # Create a timer to change wallpaper every 30 seconds
        $script:timer = New-Object System.Windows.Forms.Timer
        $script:timer.Interval = 30000  # 30 seconds
        $script:timer.Add_Tick({ Change-Wallpaper })
        $script:timer.Start()
        
        # Change wallpaper immediately when starting
        Change-Wallpaper
    }
    else {
        $script:isRunning = $false
        $startStopButton.Text = "Start"
        $script:timer.Stop()
        $script:timer = $null
        $statusLabel.Text = "Status: Stopped`nFolder: $($script:imageDirectory)`nImages: $($script:imageFiles.Count)"
    }
})

# Event handler for Open menu item
$openMenuItem.Add_Click({
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.Show()
    $form.Activate()
})

# Event handler for Exit menu item
$exitMenuItem.Add_Click({
    $notifyIcon.Visible = $false
    $form.Close()
    [System.Windows.Forms.Application]::Exit()
})

# Event handler for form closing
$form.Add_FormClosing({
    param($sender, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $form.Hide()
    }
})

# Event handler for notify icon double-click
$notifyIcon.Add_DoubleClick({
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.Show()
    $form.Activate()
})

# Start the form application
[System.Windows.Forms.Application]::Run($form) 