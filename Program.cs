using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Collections.Generic;

namespace WallpaperChanger
{
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        private NotifyIcon trayIcon;
        private ContextMenuStrip trayMenu;
        private Timer wallpaperTimer;
        private string imageDirectory;
        private List<string> imageFiles;
        private int currentImageIndex = 0;
        private bool isRunning = false;

        // Windows API for setting wallpaper
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

        private const int SPI_SETDESKWALLPAPER = 20;
        private const int SPIF_UPDATEINIFILE = 0x01;
        private const int SPIF_SENDCHANGE = 0x02;

        public MainForm()
        {
            InitializeComponent();
            InitializeTrayIcon();
            
            // Default to 30 seconds
            wallpaperTimer = new Timer();
            wallpaperTimer.Interval = 30000; // 30 seconds
            wallpaperTimer.Tick += WallpaperTimer_Tick;
            
            imageFiles = new List<string>();
        }

        private void InitializeComponent()
        {
            this.Text = "Wallpaper Changer";
            this.Size = new Size(400, 200);
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormClosing += MainForm_FormClosing;

            // Folder selection button
            Button btnSelectFolder = new Button();
            btnSelectFolder.Text = "Select Images Folder";
            btnSelectFolder.Location = new Point(20, 20);
            btnSelectFolder.Size = new Size(150, 30);
            btnSelectFolder.Click += BtnSelectFolder_Click;
            this.Controls.Add(btnSelectFolder);

            // Start/Stop button
            Button btnStartStop = new Button();
            btnStartStop.Text = "Start";
            btnStartStop.Location = new Point(20, 70);
            btnStartStop.Size = new Size(150, 30);
            btnStartStop.Click += BtnStartStop_Click;
            this.Controls.Add(btnStartStop);

            // Minimize to tray on startup
            this.Load += (s, e) =>
            {
                this.WindowState = FormWindowState.Minimized;
                this.ShowInTaskbar = false;
            };
        }

        private void InitializeTrayIcon()
        {
            trayMenu = new ContextMenuStrip();
            trayMenu.Items.Add("Open", null, OnOpen);
            trayMenu.Items.Add("Exit", null, OnExit);

            trayIcon = new NotifyIcon();
            trayIcon.Text = "Wallpaper Changer";
            trayIcon.Icon = SystemIcons.Application;
            trayIcon.ContextMenuStrip = trayMenu;
            trayIcon.Visible = true;
            trayIcon.DoubleClick += OnOpen;
        }

        private void BtnSelectFolder_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog folderDialog = new FolderBrowserDialog())
            {
                folderDialog.Description = "Select folder with wallpaper images";
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    imageDirectory = folderDialog.SelectedPath;
                    LoadImageFiles();
                    MessageBox.Show($"Found {imageFiles.Count} images in the selected folder.", 
                        "Images Loaded", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
        }

        private void BtnStartStop_Click(object sender, EventArgs e)
        {
            Button btn = (Button)sender;

            if (!isRunning)
            {
                if (string.IsNullOrEmpty(imageDirectory) || imageFiles.Count == 0)
                {
                    MessageBox.Show("Please select a folder with images first.", 
                        "No Images", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                isRunning = true;
                btn.Text = "Stop";
                wallpaperTimer.Start();
                
                // Change wallpaper immediately when starting
                ChangeWallpaper();
            }
            else
            {
                isRunning = false;
                btn.Text = "Start";
                wallpaperTimer.Stop();
            }
        }

        private void LoadImageFiles()
        {
            imageFiles.Clear();
            
            // Get all image files with common extensions
            string[] extensions = { "*.jpg", "*.jpeg", "*.png", "*.bmp" };
            
            foreach (string extension in extensions)
            {
                imageFiles.AddRange(Directory.GetFiles(imageDirectory, extension));
            }
            
            // Shuffle images for randomization
            Random rand = new Random();
            imageFiles = imageFiles.OrderBy(x => rand.Next()).ToList();
            
            currentImageIndex = 0;
        }

        private void WallpaperTimer_Tick(object sender, EventArgs e)
        {
            ChangeWallpaper();
        }

        private void ChangeWallpaper()
        {
            if (imageFiles.Count == 0) return;

            try
            {
                SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, imageFiles[currentImageIndex], SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
                
                // Move to next image, wrap around when reaching the end
                currentImageIndex = (currentImageIndex + 1) % imageFiles.Count;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error changing wallpaper: {ex.Message}", 
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void OnOpen(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Normal;
            this.ShowInTaskbar = true;
            this.Activate();
        }

        private void OnExit(object sender, EventArgs e)
        {
            trayIcon.Visible = false;
            Application.Exit();
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;
                this.WindowState = FormWindowState.Minimized;
                this.ShowInTaskbar = false;
            }
        }
    }
} 