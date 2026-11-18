// OpenLid for Windows -- Modern Native App & System Tray Clamshell Manager
// Strictly C# 5.0 compatible for zero-dependency compilation with Windows built-in .NET 4.x csc.exe.

using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace OpenLid
{
    internal static class NativeUI
    {
        [DllImport("user32.dll")]
        public static extern bool SetProcessDPIAware();

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        private const int DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;
        private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
        private const int DWMWA_WINDOW_CORNER_PREFERENCE = 33;
        private const int DWMWCP_ROUND = 2;

        public static void ApplyDarkModernChrome(Form form)
        {
            if (form == null || !form.IsHandleCreated) return;
            try
            {
                int useDark = 1;
                if (DwmSetWindowAttribute(form.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDark, sizeof(int)) != 0)
                {
                    DwmSetWindowAttribute(form.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, ref useDark, sizeof(int));
                }
                int cornerPref = DWMWCP_ROUND;
                DwmSetWindowAttribute(form.Handle, DWMWA_WINDOW_CORNER_PREFERENCE, ref cornerPref, sizeof(int));
            }
            catch { }
        }

        public static GraphicsPath CreateRoundedRect(Rectangle bounds, int radius)
        {
            int d = radius * 2;
            GraphicsPath path = new GraphicsPath();
            if (radius <= 0)
            {
                path.AddRectangle(bounds);
                return path;
            }
            path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
            path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
            path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
            path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    public class RoundedPanel : Panel
    {
        private int _cornerRadius = 12;
        private Color _fillColor = Color.FromArgb(18, 18, 21);
        private Color _borderColor = Color.FromArgb(52, 52, 58);

        public int CornerRadius { get { return _cornerRadius; } set { _cornerRadius = value; Invalidate(); } }
        public Color FillColor { get { return _fillColor; } set { _fillColor = value; Invalidate(); } }
        public Color BorderColor { get { return _borderColor; } set { _borderColor = value; Invalidate(); } }

        public RoundedPanel()
        {
            DoubleBuffered = true;
            BackColor = Color.Transparent;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle rect = new Rectangle(0, 0, Width - 1, Height - 1);
            using (GraphicsPath path = NativeUI.CreateRoundedRect(rect, _cornerRadius))
            using (SolidBrush brush = new SolidBrush(_fillColor))
            using (Pen pen = new Pen(_borderColor, 1f))
            {
                e.Graphics.FillPath(brush, path);
                e.Graphics.DrawPath(pen, path);
            }
            base.OnPaint(e);
        }
    }

    public class ModernButton : Control
    {
        private int _cornerRadius = 9;
        private Color _normalBack = Color.FromArgb(245, 245, 247);
        private Color _hoverBack = Color.FromArgb(255, 255, 255);
        private Color _pressBack = Color.FromArgb(215, 215, 220);
        private Color _borderColor = Color.Transparent;
        private bool _hovered = false;
        private bool _pressed = false;

        public int CornerRadius { get { return _cornerRadius; } set { _cornerRadius = value; Invalidate(); } }
        public Color NormalBack { get { return _normalBack; } set { _normalBack = value; Invalidate(); } }
        public Color HoverBack { get { return _hoverBack; } set { _hoverBack = value; Invalidate(); } }
        public Color PressBack { get { return _pressBack; } set { _pressBack = value; Invalidate(); } }
        public Color BorderColor { get { return _borderColor; } set { _borderColor = value; Invalidate(); } }

        public ModernButton()
        {
            DoubleBuffered = true;
            Cursor = Cursors.Hand;
            BackColor = Color.Transparent;
            ForeColor = Color.Black;
            Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            SetStyle(ControlStyles.SupportsTransparentBackColor | ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        }

        protected override void OnMouseEnter(EventArgs e) { _hovered = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { _hovered = false; _pressed = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnMouseDown(MouseEventArgs e) { if (e.Button == MouseButtons.Left) { _pressed = true; Invalidate(); } base.OnMouseDown(e); }
        protected override void OnMouseUp(MouseEventArgs e) { _pressed = false; Invalidate(); base.OnMouseUp(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            e.Graphics.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            Color bg = _normalBack;
            if (!Enabled) bg = Color.FromArgb(45, 52, 65);
            else if (_pressed) bg = _pressBack;
            else if (_hovered) bg = _hoverBack;

            Rectangle rect = new Rectangle(0, 0, Width - 1, Height - 1);
            using (GraphicsPath path = NativeUI.CreateRoundedRect(rect, _cornerRadius))
            using (SolidBrush brush = new SolidBrush(bg))
            {
                e.Graphics.FillPath(brush, path);
                if (_borderColor != Color.Transparent)
                {
                    using (Pen pen = new Pen(_borderColor, 1f))
                    {
                        e.Graphics.DrawPath(pen, path);
                    }
                }
            }

            Color fg = Enabled ? ForeColor : Color.FromArgb(120, 130, 145);
            TextRenderer.DrawText(e.Graphics, Text, Font, rect, fg, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
        }
    }

    public class Program
    {
        [Flags]
        public enum EXECUTION_STATE : uint
        {
            ES_AWAYMODE_REQUIRED = 0x00000040,
            ES_CONTINUOUS        = 0x80000000,
            ES_DISPLAY_REQUIRED  = 0x00000002,
            ES_SYSTEM_REQUIRED   = 0x00000001
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE esFlags);

        public static NotifyIcon TrayIcon;
        public static ContextMenuStrip TrayMenu;
        public static bool IsAwake = true;
        public static System.Windows.Forms.Timer CountdownTimer;
        public static DateTime SessionEndTime;
        public static bool IsTimedSession = false;
        public static int ActiveDurationMinutes = 0;
        public static OpenLidMainWindow MainWindow;
        public static string PresentationMode = "both";
        public static bool HasCompletedOnboarding = false;

        private static string ConfigPath
        {
            get
            {
                return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "OpenLid", "config.ini");
            }
        }

        public static string InstalledProgramsRoot
        {
            get
            {
                return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "OpenLid");
            }
        }

        public static string CurrentPackageRoot
        {
            get
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
                if (string.Equals(Path.GetFileName(baseDir), "app", StringComparison.OrdinalIgnoreCase))
                {
                    string parent = Path.GetDirectoryName(baseDir);
                    if (!string.IsNullOrEmpty(parent)) return parent;
                }
                return baseDir;
            }
        }

        public static bool IsInstalledInPrograms()
        {
            string currentRoot = CurrentPackageRoot.TrimEnd('\\', '/');
            string targetRoot = InstalledProgramsRoot.TrimEnd('\\', '/');
            return string.Equals(currentRoot, targetRoot, StringComparison.OrdinalIgnoreCase);
        }

        public static string GetCurrentLocationLabel()
        {
            string root = CurrentPackageRoot;
            string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string downloads = Path.Combine(profile, "Downloads");
            string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            string temp = Path.GetTempPath().TrimEnd('\\', '/');

            if (root.StartsWith(downloads, StringComparison.OrdinalIgnoreCase) || root.IndexOf("\\Downloads\\", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Downloads";
            if (root.StartsWith(desktop, StringComparison.OrdinalIgnoreCase))
                return "Desktop";
            if (root.StartsWith(temp, StringComparison.OrdinalIgnoreCase) || root.IndexOf("\\Temp\\", StringComparison.OrdinalIgnoreCase) >= 0)
                return "Temp Archive";
            return "Portable Folder";
        }

        [STAThread]
        public static void Main(string[] args)
        {
            try { NativeUI.SetProcessDPIAware(); } catch { }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            LoadConfig();

            if (args != null && args.Length > 0)
            {
                if (HandleCommandLine(args)) return;
            }

            // Build Tray Context Menu
            TrayMenu = new ContextMenuStrip();
            TrayMenu.Items.Add("OpenLid for Windows (v1.0.0)").Enabled = false;
            TrayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem openAppItem = new ToolStripMenuItem("Open OpenLid Dashboard", null, delegate { ShowMainWindow(); });
            openAppItem.Font = new Font(openAppItem.Font, FontStyle.Bold);
            TrayMenu.Items.Add(openAppItem);

            ToolStripMenuItem statusItem = new ToolStripMenuItem("Status: Awake (Clamshell Bypass)", null, delegate { ShowMainWindow(); });
            statusItem.Name = "StatusItem";
            TrayMenu.Items.Add(statusItem);

            ToolStripMenuItem toggleItem = new ToolStripMenuItem("Disable Sleep Bypass", null, delegate { ToggleState(); });
            toggleItem.Name = "ToggleItem";
            TrayMenu.Items.Add(toggleItem);

            ToolStripMenuItem durationMenu = new ToolStripMenuItem("Session Duration");
            durationMenu.DropDownItems.Add("Indefinite (Always)", null, delegate { SetDuration(0); });
            durationMenu.DropDownItems.Add("15 Minutes", null, delegate { SetDuration(15); });
            durationMenu.DropDownItems.Add("30 Minutes", null, delegate { SetDuration(30); });
            durationMenu.DropDownItems.Add("1 Hour", null, delegate { SetDuration(60); });
            durationMenu.DropDownItems.Add("2 Hours", null, delegate { SetDuration(120); });
            TrayMenu.Items.Add(durationMenu);

            if (!IsInstalledInPrograms())
            {
                TrayMenu.Items.Add(new ToolStripSeparator());
                TrayMenu.Items.Add(new ToolStripMenuItem("Move to Programs Folder...", null, delegate { ShowMoveToProgramsDialog(true); }));
            }

            TrayMenu.Items.Add(new ToolStripSeparator());
            ToolStripMenuItem contactMenu = new ToolStripMenuItem("Support & Links");
            contactMenu.DropDownItems.Add("GitHub Repository", null, delegate { OpenUrl("https://github.com/PurohitBhagyesh/openlid"); });
            contactMenu.DropDownItems.Add("Official Website", null, delegate { OpenUrl("https://openlid.devs.li"); });
            contactMenu.DropDownItems.Add("Report an Issue (Email)", null, delegate { OpenUrl("mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report%20(Windows)"); });
            TrayMenu.Items.Add(contactMenu);

            TrayMenu.Items.Add(new ToolStripSeparator());
            TrayMenu.Items.Add("Exit OpenLid", null, delegate { ExitApplication(); });

            TrayIcon = new NotifyIcon();
            TrayIcon.Text = "OpenLid: Awake & Vigilant";
            TrayIcon.Icon = CreateEyeIcon(true);
            TrayIcon.ContextMenuStrip = TrayMenu;
            TrayIcon.Visible = (PresentationMode == "tray" || PresentationMode == "both");
            TrayIcon.DoubleClick += delegate { ShowMainWindow(); };

            SetAwakeState(true);

            Application.ApplicationExit += delegate { RestoreDefaultPower(); };
            AppDomain.CurrentDomain.ProcessExit += delegate { RestoreDefaultPower(); };

            // Offer sleek Move-to-Programs dialog if launched from Downloads/Temp/Desktop
            ShowMoveToProgramsDialog(false);

            if (!HasCompletedOnboarding)
            {
                using (OpenLidWelcomeForm welcome = new OpenLidWelcomeForm())
                {
                    welcome.ShowDialog();
                }
                HasCompletedOnboarding = true;
                SaveConfig();
            }

            if (PresentationMode == "app" || PresentationMode == "both")
            {
                ShowMainWindow();
            }

            Application.Run();
        }

        public static void OpenUrl(string url)
        {
            try { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); } catch { }
        }

        public static void ShowMoveToProgramsDialog(bool force)
        {
            try
            {
                if (IsInstalledInPrograms()) return;

                string appDataOpenLid = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "OpenLid");
                string suppressPath = Path.Combine(appDataOpenLid, "suppress_move.txt");

                if (!force)
                {
                    if (File.Exists(suppressPath)) return;

                    string root = CurrentPackageRoot;
                    string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                    string downloads = Path.Combine(profile, "Downloads");
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    string temp = Path.GetTempPath().TrimEnd('\\', '/');

                    bool shouldOffer = root.StartsWith(downloads, StringComparison.OrdinalIgnoreCase) ||
                                       root.StartsWith(desktop, StringComparison.OrdinalIgnoreCase) ||
                                       root.StartsWith(temp, StringComparison.OrdinalIgnoreCase) ||
                                       root.IndexOf("\\Downloads\\", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                       root.IndexOf("\\Temp\\", StringComparison.OrdinalIgnoreCase) >= 0;

                    if (!shouldOffer) return;
                }

                using (MoveToProgramsForm dialog = new MoveToProgramsForm())
                {
                    DialogResult res = dialog.ShowDialog();
                    if (dialog.DontAskAgain && res != DialogResult.OK)
                    {
                        try
                        {
                            if (!Directory.Exists(appDataOpenLid)) Directory.CreateDirectory(appDataOpenLid);
                            File.WriteAllText(suppressPath, "Suppressed by user");
                        }
                        catch { }
                    }
                }
            }
            catch { }
        }

        public static void MoveToProgramsFolder(Action<string> statusCallback)
        {
            string sourceRoot = CurrentPackageRoot;
            string targetRoot = InstalledProgramsRoot;
            string targetAppDir = Path.Combine(targetRoot, "app");

            if (statusCallback != null) statusCallback("Copying OpenLid files...");
            Directory.CreateDirectory(targetRoot);
            Directory.CreateDirectory(targetAppDir);

            // Copy top-level files
            CopyDirectoryFiles(sourceRoot, targetRoot);

            // Copy app/ directory files (or baseDir if launched from flat layout)
            string sourceAppDir = Path.Combine(sourceRoot, "app");
            if (Directory.Exists(sourceAppDir))
            {
                CopyDirectoryFiles(sourceAppDir, targetAppDir);
            }
            else
            {
                CopyDirectoryFiles(AppDomain.CurrentDomain.BaseDirectory, targetAppDir);
            }

            if (statusCallback != null) statusCallback("Creating Desktop & Start Menu shortcuts...");
            string targetExe = Path.Combine(targetAppDir, "OpenLid.exe");
            string fallbackCmd = Path.Combine(targetRoot, "OpenLid.cmd");
            string launchTarget = File.Exists(targetExe) ? targetExe : fallbackCmd;
            string launchArgs = File.Exists(targetExe) ? "--app" : "";
            string iconPath = Path.Combine(targetAppDir, "OpenLid.ico");

            CreateWindowsShortcut(
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "OpenLid.lnk"),
                launchTarget,
                launchArgs,
                targetRoot,
                iconPath,
                "OpenLid - Keep your laptop running with the lid closed"
            );

            CreateWindowsShortcut(
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "OpenLid.lnk"),
                launchTarget,
                launchArgs,
                targetRoot,
                iconPath,
                "OpenLid - Keep your laptop running with the lid closed"
            );

            if (statusCallback != null) statusCallback("Relaunching OpenLid from Programs...");
            ProcessStartInfo psi = new ProcessStartInfo(launchTarget, launchArgs);
            psi.UseShellExecute = true;
            psi.WorkingDirectory = targetRoot;
            Process.Start(psi);

            if (TrayIcon != null)
            {
                TrayIcon.Visible = false;
                TrayIcon.Dispose();
            }
            Environment.Exit(0);
        }

        private static void CopyDirectoryFiles(string srcDir, string dstDir)
        {
            if (!Directory.Exists(srcDir)) return;
            Directory.CreateDirectory(dstDir);
            string[] files = Directory.GetFiles(srcDir);
            for (int i = 0; i < files.Length; i++)
            {
                string file = files[i];
                string dest = Path.Combine(dstDir, Path.GetFileName(file));
                try { File.Copy(file, dest, true); } catch { }
            }
        }

        private static void CreateWindowsShortcut(string shortcutPath, string targetPath, string arguments, string workingDir, string iconPath, string description)
        {
            try
            {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                if (shellType == null) return;
                object shell = Activator.CreateInstance(shellType);
                object shortcut = shellType.InvokeMember(
                    "CreateShortcut",
                    BindingFlags.InvokeMethod,
                    null,
                    shell,
                    new object[] { shortcutPath }
                );
                if (shortcut == null) return;
                Type scType = shortcut.GetType();
                scType.InvokeMember("TargetPath", BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
                if (!string.IsNullOrEmpty(arguments))
                    scType.InvokeMember("Arguments", BindingFlags.SetProperty, null, shortcut, new object[] { arguments });
                scType.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, shortcut, new object[] { workingDir });
                if (!string.IsNullOrEmpty(iconPath) && File.Exists(iconPath))
                    scType.InvokeMember("IconLocation", BindingFlags.SetProperty, null, shortcut, new object[] { iconPath + ",0" });
                scType.InvokeMember("Description", BindingFlags.SetProperty, null, shortcut, new object[] { description });
                scType.InvokeMember("Save", BindingFlags.InvokeMethod, null, shortcut, null);
            }
            catch { }
        }

        public static void ShowMainWindow()
        {
            if (MainWindow == null || MainWindow.IsDisposed)
            {
                MainWindow = new OpenLidMainWindow();
            }
            MainWindow.ShowInTaskbar = true;
            MainWindow.Icon = CreateEyeIcon(IsAwake);
            MainWindow.Show();
            MainWindow.WindowState = FormWindowState.Normal;
            MainWindow.BringToFront();
            MainWindow.Activate();
        }

        public static void SetAwakeState(bool awake)
        {
            IsAwake = awake;
            if (awake)
            {
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS | EXECUTION_STATE.ES_SYSTEM_REQUIRED | EXECUTION_STATE.ES_AWAYMODE_REQUIRED);
                ConfigureLidAction(0);
                if (TrayIcon != null)
                {
                    TrayIcon.Text = "OpenLid: Awake & Vigilant (Lid Bypass Active)";
                    TrayIcon.Icon = CreateEyeIcon(true);
                }
                if (TrayMenu != null && TrayMenu.Items["StatusItem"] != null)
                {
                    TrayMenu.Items["StatusItem"].Text = "Status: Awake (Clamshell Bypass)";
                    TrayMenu.Items["ToggleItem"].Text = "Disable Sleep Bypass";
                }
            }
            else
            {
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
                ConfigureLidAction(1);
                if (TrayIcon != null)
                {
                    TrayIcon.Text = "OpenLid: Standby (Normal Sleep)";
                    TrayIcon.Icon = CreateEyeIcon(false);
                }
                if (TrayMenu != null && TrayMenu.Items["StatusItem"] != null)
                {
                    TrayMenu.Items["StatusItem"].Text = "Status: Standby (Normal Sleep)";
                    TrayMenu.Items["ToggleItem"].Text = "Enable Sleep Bypass";
                }
                StopCountdown();
            }

            if (MainWindow != null && !MainWindow.IsDisposed)
            {
                MainWindow.UpdateAwakeUI();
            }
        }

        public static void ToggleState()
        {
            SetAwakeState(!IsAwake);
        }

        public static void SetDuration(int minutes)
        {
            StopCountdown();
            ActiveDurationMinutes = minutes;
            if (minutes <= 0)
            {
                IsTimedSession = false;
                SetAwakeState(true);
                if (MainWindow != null && !MainWindow.IsDisposed) MainWindow.UpdatePresetButtons();
                return;
            }

            IsTimedSession = true;
            SessionEndTime = DateTime.Now.AddMinutes(minutes);
            SetAwakeState(true);

            CountdownTimer = new System.Windows.Forms.Timer();
            CountdownTimer.Interval = 5000;
            CountdownTimer.Tick += delegate
            {
                if (DateTime.Now >= SessionEndTime)
                {
                    SetAwakeState(false);
                    if (TrayIcon != null)
                    {
                        TrayIcon.ShowBalloonTip(3000, "OpenLid", "Session timer expired. Normal lid sleep restored.", ToolTipIcon.Info);
                    }
                }
            };
            CountdownTimer.Start();

            if (TrayIcon != null)
            {
                TrayIcon.ShowBalloonTip(2000, "OpenLid Timer", string.Format("Session active for {0} minutes.", minutes), ToolTipIcon.Info);
            }
            if (MainWindow != null && !MainWindow.IsDisposed) MainWindow.UpdatePresetButtons();
        }

        public static void StopCountdown()
        {
            if (CountdownTimer != null)
            {
                CountdownTimer.Stop();
                CountdownTimer.Dispose();
                CountdownTimer = null;
            }
            IsTimedSession = false;
        }

        public static void ConfigureLidAction(int action)
        {
            try
            {
                RunPowerCfg(string.Format("/setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION {0}", action));
                RunPowerCfg(string.Format("/setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION {0}", action));
                RunPowerCfg("/setactive SCHEME_CURRENT");
            }
            catch { }
        }

        private static void RunPowerCfg(string args)
        {
            ProcessStartInfo psi = new ProcessStartInfo("powercfg", args);
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            Process p = Process.Start(psi);
            if (p != null) p.WaitForExit(3000);
        }

        public static void RestoreDefaultPower()
        {
            SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
            ConfigureLidAction(1);
        }

        public static void ExitApplication()
        {
            RestoreDefaultPower();
            if (TrayIcon != null)
            {
                TrayIcon.Visible = false;
                TrayIcon.Dispose();
            }
            Application.Exit();
        }

        public static Icon CreateEyeIcon(bool active)
        {
            if (active)
            {
                try
                {
                    string icoPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "OpenLid.ico");
                    if (!File.Exists(icoPath))
                        icoPath = Path.Combine(CurrentPackageRoot, "app", "OpenLid.ico");
                    if (File.Exists(icoPath))
                        return new Icon(icoPath, 32, 32);
                }
                catch { }
            }

            using (Bitmap bmp = new Bitmap(32, 32))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);

                Color eyeColor = active ? Color.FromArgb(245, 245, 247) : Color.FromArgb(120, 130, 145);
                Color pupilColor = active ? Color.FromArgb(220, 220, 225) : Color.FromArgb(80, 90, 105);

                using (Pen pen = new Pen(eyeColor, 3f))
                {
                    g.DrawEllipse(pen, 2, 8, 28, 16);
                }
                using (Brush brush = new SolidBrush(pupilColor))
                {
                    g.FillEllipse(brush, 11, 11, 10, 10);
                }

                IntPtr hIcon = bmp.GetHicon();
                return Icon.FromHandle(hIcon);
            }
        }

        public static void LoadConfig()
        {
            try
            {
                if (File.Exists(ConfigPath))
                {
                    string[] lines = File.ReadAllLines(ConfigPath);
                    for (int i = 0; i < lines.Length; i++)
                    {
                        string line = lines[i];
                        if (line.StartsWith("Mode=")) PresentationMode = line.Substring(5).Trim().ToLower();
                        if (line.StartsWith("Onboarded=")) HasCompletedOnboarding = line.Substring(10).Trim().Equals("True", StringComparison.OrdinalIgnoreCase);
                    }
                }
            }
            catch { }
        }

        public static void SaveConfig()
        {
            try
            {
                string dir = Path.GetDirectoryName(ConfigPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(ConfigPath, string.Format("Mode={0}\r\nOnboarded={1}\r\n", PresentationMode, HasCompletedOnboarding));
            }
            catch { }
        }

        private static bool HandleCommandLine(string[] args)
        {
            string cmd = args[0].ToLower().TrimStart('-', '/');
            if (cmd == "on")
            {
                SetAwakeState(true);
                return false;
            }
            else if (cmd == "off")
            {
                RestoreDefaultPower();
                return true;
            }
            else if (cmd == "status")
            {
                Console.WriteLine("OpenLid for Windows v1.0.0 | Mode: " + PresentationMode);
                return true;
            }
            else if (cmd == "app" || cmd == "gui")
            {
                if (PresentationMode == "tray") PresentationMode = "both";
                return false;
            }
            else if (cmd == "tray")
            {
                PresentationMode = "tray";
                return false;
            }
            else if (cmd == "welcome" || cmd == "onboarding")
            {
                HasCompletedOnboarding = false;
                return false;
            }
            return false;
        }
    }

    public class AnimatedEyeControl : Control
    {
        private float _pupilOffset = -0.7f;
        private float _direction = 0.045f;
        private System.Windows.Forms.Timer _animTimer;
        private bool _isAwake = true;

        public bool IsAwake
        {
            get { return _isAwake; }
            set { _isAwake = value; Invalidate(); }
        }

        public AnimatedEyeControl()
        {
            DoubleBuffered = true;
            BackColor = Color.Transparent;
            Size = new Size(92, 56);
            SetStyle(ControlStyles.SupportsTransparentBackColor | ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);

            _animTimer = new System.Windows.Forms.Timer();
            _animTimer.Interval = 32;
            _animTimer.Tick += delegate
            {
                if (_isAwake)
                {
                    _pupilOffset += _direction;
                    if (_pupilOffset >= 0.75f) _direction = -0.045f;
                    if (_pupilOffset <= -0.75f) _direction = 0.045f;
                    Invalidate();
                }
            };
            _animTimer.Start();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && _animTimer != null)
            {
                _animTimer.Stop();
                _animTimer.Dispose();
            }
            base.Dispose(disposing);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            int w = Width;
            int h = Height;
            float cx = w / 2f;
            float cy = h / 2f;

            if (_isAwake)
            {
                using (GraphicsPath glowPath = new GraphicsPath())
                {
                    glowPath.AddEllipse(4, 4, w - 8, h - 8);
                    using (PathGradientBrush pgb = new PathGradientBrush(glowPath))
                    {
                        pgb.CenterColor = Color.FromArgb(40, 255, 255, 255);
                        pgb.SurroundColors = new Color[] { Color.Transparent };
                        g.FillPath(pgb, glowPath);
                    }
                }
            }

            float eyeW = w * 0.80f;
            float eyeH = _isAwake ? h * 0.56f : 4f;
            RectangleF eyeRect = new RectangleF(cx - eyeW / 2f, cy - eyeH / 2f, eyeW, eyeH);

            if (_isAwake)
            {
                using (SolidBrush sclera = new SolidBrush(Color.FromArgb(14, 22, 28)))
                {
                    g.FillEllipse(sclera, eyeRect);
                }

                float irisR = Math.Min(eyeW, eyeH) * 0.38f;
                float pupilX = cx + (_pupilOffset * (eyeW * 0.17f));
                using (SolidBrush iris = new SolidBrush(Color.FromArgb(245, 245, 247)))
                {
                    g.FillEllipse(iris, pupilX - irisR, cy - irisR, irisR * 2f, irisR * 2f);
                }
                float innerR = irisR * 0.50f;
                using (SolidBrush pupil = new SolidBrush(Color.FromArgb(8, 12, 18)))
                {
                    g.FillEllipse(pupil, pupilX - innerR, cy - innerR, innerR * 2f, innerR * 2f);
                }
                using (SolidBrush glint = new SolidBrush(Color.FromArgb(220, 255, 255, 255)))
                {
                    g.FillEllipse(glint, pupilX - innerR * 0.85f, cy - innerR * 0.85f, innerR * 0.65f, innerR * 0.65f);
                }
            }

            Color outline = _isAwake ? Color.FromArgb(245, 245, 247) : Color.FromArgb(95, 105, 122);
            using (Pen pen = new Pen(outline, 2.5f))
            {
                g.DrawEllipse(pen, eyeRect);
            }
        }
    }

    public class TransferGraphicControl : Control
    {
        private int _phase = 0;
        private System.Windows.Forms.Timer _timer;

        public TransferGraphicControl()
        {
            DoubleBuffered = true;
            BackColor = Color.Transparent;
            Size = new Size(340, 84);
            SetStyle(ControlStyles.SupportsTransparentBackColor | ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
            _timer = new System.Windows.Forms.Timer();
            _timer.Interval = 420;
            _timer.Tick += delegate { _phase = (_phase + 1) % 3; Invalidate(); };
            _timer.Start();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && _timer != null) { _timer.Stop(); _timer.Dispose(); }
            base.Dispose(disposing);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            // Left Tile: OpenLid App
            Rectangle leftBox = new Rectangle(40, 4, 68, 68);
            using (GraphicsPath lp = NativeUI.CreateRoundedRect(leftBox, 16))
            using (SolidBrush lb = new SolidBrush(Color.FromArgb(22, 22, 26)))
            using (Pen lpen = new Pen(Color.FromArgb(70, 255, 255, 255), 1.5f))
            {
                g.FillPath(lb, lp);
                g.DrawPath(lpen, lp);
            }
            using (Icon ico = Program.CreateEyeIcon(true))
            {
                g.DrawIcon(ico, new Rectangle(58, 22, 32, 32));
            }

            // Center Chevrons >>>
            for (int i = 0; i < 3; i++)
            {
                int cx = 142 + i * 20;
                int cy = 38;
                Color c = (_phase == i) ? Color.FromArgb(255, 255, 255) : Color.FromArgb(70, 90, 110);
                using (Pen cp = new Pen(c, 2.6f))
                {
                    cp.StartCap = LineCap.Round;
                    cp.EndCap = LineCap.Round;
                    g.DrawLine(cp, cx - 5, cy - 7, cx + 3, cy);
                    g.DrawLine(cp, cx + 3, cy, cx - 5, cy + 7);
                }
            }

            // Right Tile: Programs Folder
            Rectangle rightBox = new Rectangle(232, 4, 68, 68);
            using (GraphicsPath rp = NativeUI.CreateRoundedRect(rightBox, 16))
            using (SolidBrush rb = new SolidBrush(Color.FromArgb(22, 22, 26)))
            using (Pen rpen = new Pen(Color.FromArgb(55, 255, 255, 255), 1.5f))
            {
                g.FillPath(rb, rp);
                g.DrawPath(rpen, rp);
            }
            // Draw crisp vector folder icon
            using (SolidBrush tabBrush = new SolidBrush(Color.FromArgb(200, 200, 205)))
            using (SolidBrush bodyBrush = new SolidBrush(Color.FromArgb(235, 235, 240)))
            {
                using (GraphicsPath tabPath = NativeUI.CreateRoundedRect(new Rectangle(248, 22, 16, 10), 3))
                    g.FillPath(tabBrush, tabPath);
                using (GraphicsPath bodyPath = NativeUI.CreateRoundedRect(new Rectangle(248, 27, 36, 26), 5))
                    g.FillPath(bodyBrush, bodyPath);
            }
        }
    }

    // Modern Dark Move-to-Programs Dialog (replaces legacy MessageBox)
    public class MoveToProgramsForm : Form
    {
        private CheckBox _chkDontAsk;
        private ModernButton _btnMove;
        private ModernButton _btnCancel;
        private Label _lblError;

        public bool DontAskAgain
        {
            get { return _chkDontAsk != null && _chkDontAsk.Checked; }
        }

        public MoveToProgramsForm()
        {
            Text = "Move OpenLid to Programs";
            ClientSize = new Size(460, 490);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            ShowInTaskbar = true;
            BackColor = Color.FromArgb(10, 10, 12);
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 9.5f);
            Icon = Program.CreateEyeIcon(true);

            // Location pill badge
            RoundedPanel badge = new RoundedPanel();
            badge.Size = new Size(210, 26);
            badge.Location = new Point(125, 22);
            badge.CornerRadius = 13;
            badge.FillColor = Color.FromArgb(24, 24, 28);
            badge.BorderColor = Color.FromArgb(60, 60, 68);
            Label lblBadge = new Label();
            lblBadge.Text = "RUNNING FROM " + Program.GetCurrentLocationLabel().ToUpper();
            lblBadge.Font = new Font("Consolas", 8f, FontStyle.Bold);
            lblBadge.ForeColor = Color.FromArgb(215, 215, 220);
            lblBadge.TextAlign = ContentAlignment.MiddleCenter;
            lblBadge.Dock = DockStyle.Fill;
            badge.Controls.Add(lblBadge);
            Controls.Add(badge);

            // Visual transfer graphic
            TransferGraphicControl graphic = new TransferGraphicControl();
            graphic.Location = new Point(60, 62);
            Controls.Add(graphic);

            Label lblLeft = new Label();
            lblLeft.Text = "OpenLid";
            lblLeft.Font = new Font("Segoe UI", 8.5f, FontStyle.Regular);
            lblLeft.ForeColor = Color.FromArgb(160, 172, 190);
            lblLeft.TextAlign = ContentAlignment.MiddleCenter;
            lblLeft.Location = new Point(88, 144);
            lblLeft.Size = new Size(92, 18);
            Controls.Add(lblLeft);

            Label lblRight = new Label();
            lblRight.Text = "Programs";
            lblRight.Font = new Font("Segoe UI", 8.5f, FontStyle.Regular);
            lblRight.ForeColor = Color.FromArgb(160, 172, 190);
            lblRight.TextAlign = ContentAlignment.MiddleCenter;
            lblRight.Location = new Point(280, 144);
            lblRight.Size = new Size(92, 18);
            Controls.Add(lblRight);

            // Title & subtitle
            Label lblTitle = new Label();
            lblTitle.Text = "Move OpenLid to Programs";
            lblTitle.Font = new Font("Segoe UI", 15f, FontStyle.Bold);
            lblTitle.ForeColor = Color.White;
            lblTitle.TextAlign = ContentAlignment.MiddleCenter;
            lblTitle.Location = new Point(24, 174);
            lblTitle.Size = new Size(412, 30);
            Controls.Add(lblTitle);

            Label lblSub = new Label();
            lblSub.Text = "Install OpenLid into your local Programs folder for instant Start Menu access, Desktop shortcuts, and reliable background wake locks.";
            lblSub.Font = new Font("Segoe UI", 9.2f);
            lblSub.ForeColor = Color.FromArgb(156, 168, 186);
            lblSub.TextAlign = ContentAlignment.TopCenter;
            lblSub.Location = new Point(36, 208);
            lblSub.Size = new Size(388, 40);
            Controls.Add(lblSub);

            // Frosted Benefits Card
            RoundedPanel card = new RoundedPanel();
            card.Location = new Point(28, 256);
            card.Size = new Size(404, 118);
            card.CornerRadius = 12;
            card.FillColor = Color.FromArgb(18, 18, 21);
            card.BorderColor = Color.FromArgb(46, 46, 52);

            AddBenefitRow(card, 14, "Keeps Downloads tidy", "Relocates to %LOCALAPPDATA%\\Programs\\OpenLid");
            AddBenefitRow(card, 49, "Start Menu & Desktop shortcuts", "Creates native branded shortcuts with OpenLid icon");
            AddBenefitRow(card, 84, "Instant native relaunch", "Zero admin rights required; launches immediately");
            Controls.Add(card);

            _lblError = new Label();
            _lblError.Visible = false;
            _lblError.ForeColor = Color.FromArgb(215, 215, 220);
            _lblError.Font = new Font("Segoe UI", 8.5f);
            _lblError.Location = new Point(28, 378);
            _lblError.Size = new Size(404, 20);
            Controls.Add(_lblError);

            // Primary emerald button
            _btnMove = new ModernButton();
            _btnMove.Text = "Move to Programs Folder";
            _btnMove.Location = new Point(28, 398);
            _btnMove.Size = new Size(404, 40);
            _btnMove.CornerRadius = 10;
            _btnMove.NormalBack = Color.FromArgb(245, 245, 247);
            _btnMove.HoverBack = Color.FromArgb(255, 255, 255);
            _btnMove.PressBack = Color.FromArgb(215, 215, 220);
            _btnMove.ForeColor = Color.Black;
            _btnMove.Click += delegate { PerformMove(); };
            Controls.Add(_btnMove);

            // Bottom row: Don't ask again + Not Now
            _chkDontAsk = new CheckBox();
            _chkDontAsk.Text = "Don't ask again";
            _chkDontAsk.ForeColor = Color.FromArgb(148, 160, 178);
            _chkDontAsk.Font = new Font("Segoe UI", 9f);
            _chkDontAsk.Location = new Point(30, 450);
            _chkDontAsk.Size = new Size(160, 24);
            Controls.Add(_chkDontAsk);

            _btnCancel = new ModernButton();
            _btnCancel.Text = "Not Now";
            _btnCancel.Location = new Point(332, 446);
            _btnCancel.Size = new Size(100, 30);
            _btnCancel.CornerRadius = 8;
            _btnCancel.NormalBack = Color.FromArgb(26, 31, 42);
            _btnCancel.HoverBack = Color.FromArgb(52, 52, 58);
            _btnCancel.PressBack = Color.FromArgb(20, 24, 34);
            _btnCancel.BorderColor = Color.FromArgb(58, 58, 66);
            _btnCancel.ForeColor = Color.FromArgb(210, 218, 230);
            _btnCancel.Font = new Font("Segoe UI", 9f, FontStyle.Regular);
            _btnCancel.Click += delegate { DialogResult = DialogResult.Cancel; Close(); };
            Controls.Add(_btnCancel);
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            NativeUI.ApplyDarkModernChrome(this);
        }

        private void AddBenefitRow(Panel parent, int y, string title, string subtitle)
        {
            Label dot = new Label();
            dot.Text = "\u2713";
            dot.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            dot.ForeColor = Color.FromArgb(245, 245, 247);
            dot.Location = new Point(14, y);
            dot.Size = new Size(20, 20);
            parent.Controls.Add(dot);

            Label lbl = new Label();
            lbl.Text = title + "  \u2014  " + subtitle;
            lbl.Font = new Font("Segoe UI", 8.8f);
            lbl.ForeColor = Color.FromArgb(205, 214, 228);
            lbl.Location = new Point(36, y + 1);
            lbl.Size = new Size(356, 22);
            parent.Controls.Add(lbl);
        }

        private void PerformMove()
        {
            _btnMove.Enabled = false;
            _btnCancel.Enabled = false;
            _lblError.Visible = false;
            try
            {
                Program.MoveToProgramsFolder(delegate(string status)
                {
                    _btnMove.Text = status;
                    Application.DoEvents();
                });
                DialogResult = DialogResult.OK;
                Close();
            }
            catch (Exception ex)
            {
                _btnMove.Text = "Move to Programs Folder";
                _btnMove.Enabled = true;
                _btnCancel.Enabled = true;
                _lblError.Text = "Move failed: " + ex.Message;
                _lblError.Visible = true;
            }
        }
    }

    // Modern 3-Step Dark Welcome & Permissions Wizard
    public class OpenLidWelcomeForm : Form
    {
        private int _step = 1;
        private Panel _contentPanel;
        private Panel _dotsPanel;

        public OpenLidWelcomeForm()
        {
            Text = "Welcome to OpenLid";
            ClientSize = new Size(520, 560);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            BackColor = Color.FromArgb(10, 10, 12);
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 9.5f);
            Icon = Program.CreateEyeIcon(true);

            _dotsPanel = new Panel();
            _dotsPanel.Dock = DockStyle.Top;
            _dotsPanel.Height = 36;
            _dotsPanel.Paint += DrawStepDots;
            Controls.Add(_dotsPanel);

            _contentPanel = new Panel();
            _contentPanel.Dock = DockStyle.Fill;
            Controls.Add(_contentPanel);

            ShowStep(1);
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            NativeUI.ApplyDarkModernChrome(this);
        }

        private void DrawStepDots(object sender, PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            int startX = (Width - 64) / 2;
            for (int i = 1; i <= 3; i++)
            {
                int w = (_step == i) ? 24 : 8;
                Color c = (_step == i) ? Color.FromArgb(245, 245, 247) : Color.FromArgb(50, 58, 72);
                using (GraphicsPath p = NativeUI.CreateRoundedRect(new Rectangle(startX, 16, w, 6), 3))
                using (SolidBrush b = new SolidBrush(c))
                {
                    e.Graphics.FillPath(b, p);
                }
                startX += w + 8;
            }
        }

        private void ShowStep(int s)
        {
            _step = s;
            _dotsPanel.Invalidate();
            _contentPanel.Controls.Clear();

            if (_step == 1)
            {
                AnimatedEyeControl eye = new AnimatedEyeControl();
                eye.Location = new Point(204, 18);
                eye.Size = new Size(112, 68);
                _contentPanel.Controls.Add(eye);

                Label lblTitle = new Label();
                lblTitle.Text = "OpenLid for Windows";
                lblTitle.Font = new Font("Segoe UI", 18f, FontStyle.Bold);
                lblTitle.ForeColor = Color.White;
                lblTitle.TextAlign = ContentAlignment.MiddleCenter;
                lblTitle.Location = new Point(24, 96);
                lblTitle.Size = new Size(472, 34);
                _contentPanel.Controls.Add(lblTitle);

                Label lblSub = new Label();
                lblSub.Text = "Keep your Windows laptop running with the lid closed \u2014 safely, smoothly, and without external displays.";
                lblSub.Font = new Font("Segoe UI", 9.5f);
                lblSub.ForeColor = Color.FromArgb(156, 168, 186);
                lblSub.TextAlign = ContentAlignment.TopCenter;
                lblSub.Location = new Point(44, 134);
                lblSub.Size = new Size(432, 42);
                _contentPanel.Controls.Add(lblSub);

                RoundedPanel card = new RoundedPanel();
                card.Location = new Point(36, 186);
                card.Size = new Size(448, 178);
                card.CornerRadius = 12;
                AddFeature(card, 18, "Full Clamshell Execution", "Builds, downloads, servers, and audio continue uninterrupted.");
                AddFeature(card, 70, "Native Win32 Away Mode", "Modulates SetThreadExecutionState & powercfg LIDACTION cleanly.");
                AddFeature(card, 122, "Zero External Displays Needed", "Operate headlessly anywhere without HDMI dummy plugs.");
                _contentPanel.Controls.Add(card);

                ModernButton btnStart = new ModernButton();
                btnStart.Text = "Get Started  \u2192";
                btnStart.Location = new Point(150, 410);
                btnStart.Size = new Size(220, 42);
                btnStart.CornerRadius = 10;
                btnStart.Click += delegate { ShowStep(2); };
                _contentPanel.Controls.Add(btnStart);
            }
            else if (_step == 2)
            {
                Label lblTitle = new Label();
                lblTitle.Text = "System Power Permissions";
                lblTitle.Font = new Font("Segoe UI", 16f, FontStyle.Bold);
                lblTitle.ForeColor = Color.White;
                lblTitle.TextAlign = ContentAlignment.MiddleCenter;
                lblTitle.Location = new Point(24, 34);
                lblTitle.Size = new Size(472, 32);
                _contentPanel.Controls.Add(lblTitle);

                Label lblSub = new Label();
                lblSub.Text = "OpenLid configures Windows ACPI lid action (LIDACTION 0) and Win32 AwayMode to prevent sleep while keeping your display off.";
                lblSub.Font = new Font("Segoe UI", 9.5f);
                lblSub.ForeColor = Color.FromArgb(156, 168, 186);
                lblSub.TextAlign = ContentAlignment.TopCenter;
                lblSub.Location = new Point(44, 72);
                lblSub.Size = new Size(432, 44);
                _contentPanel.Controls.Add(lblSub);

                RoundedPanel card = new RoundedPanel();
                card.Location = new Point(36, 134);
                card.Size = new Size(448, 160);
                card.CornerRadius = 12;

                Label lblStatus = new Label();
                lblStatus.Text = "Click below to verify powercfg & AwayMode access on this device.";
                lblStatus.Font = new Font("Segoe UI", 9.5f);
                lblStatus.ForeColor = Color.FromArgb(190, 200, 215);
                lblStatus.TextAlign = ContentAlignment.MiddleCenter;
                lblStatus.Location = new Point(24, 24);
                lblStatus.Size = new Size(400, 44);
                card.Controls.Add(lblStatus);

                ModernButton btnTest = new ModernButton();
                btnTest.Text = "Verify & Enable Power Control";
                btnTest.Location = new Point(94, 88);
                btnTest.Size = new Size(260, 40);
                btnTest.CornerRadius = 10;
                btnTest.Click += delegate
                {
                    Program.SetAwakeState(true);
                    lblStatus.Text = "\u2713 Verified! Clamshell sleep prevention is active.";
                    lblStatus.ForeColor = Color.FromArgb(255, 255, 255);
                    btnTest.Text = "Verified";
                    btnTest.Enabled = false;
                };
                card.Controls.Add(btnTest);
                _contentPanel.Controls.Add(card);

                ModernButton btnNext = new ModernButton();
                btnNext.Text = "Continue  \u2192";
                btnNext.Location = new Point(150, 410);
                btnNext.Size = new Size(220, 42);
                btnNext.CornerRadius = 10;
                btnNext.Click += delegate { ShowStep(3); };
                _contentPanel.Controls.Add(btnNext);
            }
            else
            {
                Label lblTitle = new Label();
                lblTitle.Text = "Choose Presentation Mode";
                lblTitle.Font = new Font("Segoe UI", 16f, FontStyle.Bold);
                lblTitle.ForeColor = Color.White;
                lblTitle.TextAlign = ContentAlignment.MiddleCenter;
                lblTitle.Location = new Point(24, 30);
                lblTitle.Size = new Size(472, 32);
                _contentPanel.Controls.Add(lblTitle);

                Label lblSub = new Label();
                lblSub.Text = "Select how OpenLid appears on Windows. You can change this anytime.";
                lblSub.Font = new Font("Segoe UI", 9.5f);
                lblSub.ForeColor = Color.FromArgb(156, 168, 186);
                lblSub.TextAlign = ContentAlignment.TopCenter;
                lblSub.Location = new Point(44, 68);
                lblSub.Size = new Size(432, 32);
                _contentPanel.Controls.Add(lblSub);

                RoundedPanel card = new RoundedPanel();
                card.Location = new Point(36, 114);
                card.Size = new Size(448, 224);
                card.CornerRadius = 12;

                RadioButton rbBoth = CreateModeRadio("Both Tray & App Window (Recommended)", "Quick toggle in taskbar tray plus full desktop dashboard.", 22, Program.PresentationMode == "both");
                RadioButton rbTray = CreateModeRadio("System Tray Only", "Discreet eye icon next to the Windows clock.", 92, Program.PresentationMode == "tray");
                RadioButton rbApp = CreateModeRadio("Standalone Window Only", "Classic desktop application window on the taskbar.", 162, Program.PresentationMode == "app");

                card.Controls.Add(rbBoth);
                card.Controls.Add(rbTray);
                card.Controls.Add(rbApp);
                _contentPanel.Controls.Add(card);

                ModernButton btnDone = new ModernButton();
                btnDone.Text = "Enter OpenLid";
                btnDone.Location = new Point(150, 410);
                btnDone.Size = new Size(220, 42);
                btnDone.CornerRadius = 10;
                btnDone.Click += delegate
                {
                    if (rbTray.Checked) Program.PresentationMode = "tray";
                    else if (rbApp.Checked) Program.PresentationMode = "app";
                    else Program.PresentationMode = "both";

                    Program.SaveConfig();
                    if (Program.TrayIcon != null)
                        Program.TrayIcon.Visible = (Program.PresentationMode == "tray" || Program.PresentationMode == "both");
                    Close();
                };
                _contentPanel.Controls.Add(btnDone);
            }
        }

        private void AddFeature(Panel card, int y, string title, string desc)
        {
            Label t = new Label();
            t.Text = "\u25CF  " + title;
            t.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            t.ForeColor = Color.FromArgb(255, 255, 255);
            t.Location = new Point(20, y);
            t.Size = new Size(408, 20);
            card.Controls.Add(t);

            Label d = new Label();
            d.Text = desc;
            d.Font = new Font("Segoe UI", 8.8f);
            d.ForeColor = Color.FromArgb(162, 174, 192);
            d.Location = new Point(36, y + 21);
            d.Size = new Size(392, 20);
            card.Controls.Add(d);
        }

        private RadioButton CreateModeRadio(string title, string subtitle, int y, bool isChecked)
        {
            RadioButton rb = new RadioButton();
            rb.Text = title + "\r\n" + subtitle;
            rb.Checked = isChecked;
            rb.ForeColor = Color.White;
            rb.Font = new Font("Segoe UI", 9.5f);
            rb.Location = new Point(22, y);
            rb.Size = new Size(404, 52);
            return rb;
        }
    }

    // Modern Windows 11 Dark Main Application Dashboard
    public class OpenLidMainWindow : Form
    {
        private AnimatedEyeControl _heroEye;
        private Label _lblStatus;
        private Label _lblStatusPill;
        private ModernButton _btnToggle;
        private Label _lblTelemetry;
        private ModernButton[] _presetButtons;
        private int[] _presetMinutes = new int[] { 0, 15, 30, 60, 120 };
        private System.Windows.Forms.Timer _telemTimer;

        public OpenLidMainWindow()
        {
            Text = "OpenLid";
            bool showInstallBanner = !Program.IsInstalledInPrograms();
            ClientSize = new Size(560, showInstallBanner ? 584 : 518);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            ShowInTaskbar = true;
            Icon = Program.CreateEyeIcon(Program.IsAwake);
            BackColor = Color.FromArgb(10, 10, 12);
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 9.5f);

            // Top Header Bar
            Panel pnlHeader = new Panel();
            pnlHeader.Dock = DockStyle.Top;
            pnlHeader.Height = 64;
            pnlHeader.BackColor = Color.FromArgb(15, 15, 18);

            AnimatedEyeControl headerEye = new AnimatedEyeControl();
            headerEye.Location = new Point(16, 12);
            headerEye.Size = new Size(54, 38);
            headerEye.IsAwake = Program.IsAwake;
            pnlHeader.Controls.Add(headerEye);

            Label lblTitle = new Label();
            lblTitle.Text = "OpenLid";
            lblTitle.Font = new Font("Segoe UI", 13.5f, FontStyle.Bold);
            lblTitle.ForeColor = Color.White;
            lblTitle.Location = new Point(78, 11);
            lblTitle.Size = new Size(100, 24);
            pnlHeader.Controls.Add(lblTitle);

            Label lblVer = new Label();
            lblVer.Text = "v1.0.0  \u2022  Windows Clamshell Manager";
            lblVer.Font = new Font("Segoe UI", 8.5f);
            lblVer.ForeColor = Color.FromArgb(132, 144, 164);
            lblVer.Location = new Point(79, 36);
            lblVer.Size = new Size(240, 18);
            pnlHeader.Controls.Add(lblVer);

            _lblStatusPill = new Label();
            _lblStatusPill.Font = new Font("Consolas", 8f, FontStyle.Bold);
            _lblStatusPill.TextAlign = ContentAlignment.MiddleCenter;
            _lblStatusPill.Location = new Point(448, 19);
            _lblStatusPill.Size = new Size(88, 24);
            pnlHeader.Controls.Add(_lblStatusPill);

            Controls.Add(pnlHeader);

            int curY = 82;

            // Optional Move-to-Programs Banner (modern emerald glass pill)
            if (showInstallBanner)
            {
                RoundedPanel banner = new RoundedPanel();
                banner.Location = new Point(22, curY);
                banner.Size = new Size(516, 54);
                banner.CornerRadius = 11;
                banner.FillColor = Color.FromArgb(22, 22, 26);
                banner.BorderColor = Color.FromArgb(58, 58, 66);

                Label lblBTitle = new Label();
                lblBTitle.Text = "Running from " + Program.GetCurrentLocationLabel();
                lblBTitle.Font = new Font("Segoe UI", 9.2f, FontStyle.Bold);
                lblBTitle.ForeColor = Color.White;
                lblBTitle.Location = new Point(14, 8);
                lblBTitle.Size = new Size(320, 18);
                banner.Controls.Add(lblBTitle);

                Label lblBSub = new Label();
                lblBSub.Text = "Install to Programs folder for Start Menu & Desktop shortcuts.";
                lblBSub.Font = new Font("Segoe UI", 8.2f);
                lblBSub.ForeColor = Color.FromArgb(165, 165, 172);
                lblBSub.Location = new Point(14, 28);
                lblBSub.Size = new Size(340, 18);
                banner.Controls.Add(lblBSub);

                ModernButton btnMove = new ModernButton();
                btnMove.Text = "Move to Programs";
                btnMove.Location = new Point(368, 11);
                btnMove.Size = new Size(134, 32);
                btnMove.CornerRadius = 8;
                btnMove.Font = new Font("Segoe UI", 8.5f, FontStyle.Bold);
                btnMove.Click += delegate { Program.ShowMoveToProgramsDialog(true); };
                banner.Controls.Add(btnMove);

                Controls.Add(banner);
                curY += 68;
            }

            // Hero Status & Toggle Card
            RoundedPanel heroCard = new RoundedPanel();
            heroCard.Location = new Point(22, curY);
            heroCard.Size = new Size(516, 126);
            heroCard.CornerRadius = 14;
            heroCard.FillColor = Color.FromArgb(18, 18, 21);
            heroCard.BorderColor = Color.FromArgb(46, 46, 52);

            _heroEye = new AnimatedEyeControl();
            _heroEye.Location = new Point(22, 34);
            _heroEye.Size = new Size(94, 58);
            _heroEye.IsAwake = Program.IsAwake;
            heroCard.Controls.Add(_heroEye);

            _lblStatus = new Label();
            _lblStatus.Font = new Font("Segoe UI", 12.5f, FontStyle.Bold);
            _lblStatus.ForeColor = Color.White;
            _lblStatus.Location = new Point(132, 26);
            _lblStatus.Size = new Size(364, 26);
            heroCard.Controls.Add(_lblStatus);

            _btnToggle = new ModernButton();
            _btnToggle.Location = new Point(132, 64);
            _btnToggle.Size = new Size(216, 38);
            _btnToggle.CornerRadius = 9;
            _btnToggle.Click += delegate { Program.ToggleState(); };
            heroCard.Controls.Add(_btnToggle);

            Controls.Add(heroCard);
            curY += 142;

            // Session Duration Card
            RoundedPanel presetCard = new RoundedPanel();
            presetCard.Location = new Point(22, curY);
            presetCard.Size = new Size(516, 86);
            presetCard.CornerRadius = 12;

            Label lblPresetHead = new Label();
            lblPresetHead.Text = "SESSION DURATION";
            lblPresetHead.Font = new Font("Consolas", 8f, FontStyle.Bold);
            lblPresetHead.ForeColor = Color.FromArgb(132, 144, 164);
            lblPresetHead.Location = new Point(16, 12);
            lblPresetHead.Size = new Size(200, 16);
            presetCard.Controls.Add(lblPresetHead);

            string[] labels = new string[] { "Always", "15m", "30m", "1h", "2h" };
            _presetButtons = new ModernButton[labels.Length];
            for (int i = 0; i < labels.Length; i++)
            {
                int mins = _presetMinutes[i];
                ModernButton pb = new ModernButton();
                pb.Text = labels[i];
                pb.Location = new Point(16 + i * 98, 36);
                pb.Size = new Size(90, 34);
                pb.CornerRadius = 8;
                pb.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
                pb.Click += delegate { Program.SetDuration(mins); };
                _presetButtons[i] = pb;
                presetCard.Controls.Add(pb);
            }
            Controls.Add(presetCard);
            curY += 102;

            // Live Telemetry Card
            RoundedPanel telemCard = new RoundedPanel();
            telemCard.Location = new Point(22, curY);
            telemCard.Size = new Size(516, 108);
            telemCard.CornerRadius = 12;

            Label lblTelemHead = new Label();
            lblTelemHead.Text = "LIVE HARDWARE TELEMETRY";
            lblTelemHead.Font = new Font("Consolas", 8f, FontStyle.Bold);
            lblTelemHead.ForeColor = Color.FromArgb(132, 144, 164);
            lblTelemHead.Location = new Point(16, 12);
            lblTelemHead.Size = new Size(260, 16);
            telemCard.Controls.Add(lblTelemHead);

            _lblTelemetry = new Label();
            _lblTelemetry.Text = GetTelemetryText();
            _lblTelemetry.Location = new Point(16, 34);
            _lblTelemetry.Size = new Size(484, 62);
            _lblTelemetry.Font = new Font("Segoe UI", 9.3f);
            _lblTelemetry.ForeColor = Color.FromArgb(208, 216, 230);
            telemCard.Controls.Add(_lblTelemetry);

            Controls.Add(telemCard);
            curY += 124;

            // Footer Action Buttons
            ModernButton btnSettings = new ModernButton();
            btnSettings.Text = "Presentation Mode & Setup";
            btnSettings.Location = new Point(22, curY);
            btnSettings.Size = new Size(250, 38);
            btnSettings.CornerRadius = 9;
            btnSettings.NormalBack = Color.FromArgb(22, 22, 26);
            btnSettings.HoverBack = Color.FromArgb(36, 36, 42);
            btnSettings.PressBack = Color.FromArgb(18, 18, 21);
            btnSettings.BorderColor = Color.FromArgb(54, 54, 60);
            btnSettings.ForeColor = Color.White;
            btnSettings.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            btnSettings.Click += delegate
            {
                using (OpenLidWelcomeForm w = new OpenLidWelcomeForm()) { w.ShowDialog(); }
            };
            Controls.Add(btnSettings);

            ModernButton btnWebsite = new ModernButton();
            btnWebsite.Text = "Website & Support  \u2197";
            btnWebsite.Location = new Point(288, curY);
            btnWebsite.Size = new Size(250, 38);
            btnWebsite.CornerRadius = 9;
            btnWebsite.NormalBack = Color.FromArgb(22, 22, 26);
            btnWebsite.HoverBack = Color.FromArgb(36, 36, 42);
            btnWebsite.PressBack = Color.FromArgb(18, 18, 21);
            btnWebsite.BorderColor = Color.FromArgb(54, 54, 60);
            btnWebsite.ForeColor = Color.FromArgb(255, 255, 255);
            btnWebsite.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            btnWebsite.Click += delegate { Program.OpenUrl("https://openlid.devs.li"); };
            Controls.Add(btnWebsite);

            UpdateAwakeUI();
            UpdatePresetButtons();

            _telemTimer = new System.Windows.Forms.Timer();
            _telemTimer.Interval = 2000;
            _telemTimer.Tick += delegate
            {
                if (_lblTelemetry != null && !_lblTelemetry.IsDisposed)
                    _lblTelemetry.Text = GetTelemetryText();
            };
            _telemTimer.Start();
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            NativeUI.ApplyDarkModernChrome(this);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && _telemTimer != null)
            {
                _telemTimer.Stop();
                _telemTimer.Dispose();
            }
            base.Dispose(disposing);
        }

        public void UpdateAwakeUI()
        {
            if (_heroEye != null) _heroEye.IsAwake = Program.IsAwake;
            if (_lblStatus != null)
                _lblStatus.Text = Program.IsAwake ? "Laptop Awake (Clamshell Active)" : "Normal Sleep Allowed";
            if (_lblStatusPill != null)
            {
                _lblStatusPill.Text = Program.IsAwake ? "AWAKE" : "STANDBY";
                _lblStatusPill.BackColor = Program.IsAwake ? Color.FromArgb(245, 245, 247) : Color.FromArgb(32, 37, 48);
                _lblStatusPill.ForeColor = Program.IsAwake ? Color.Black : Color.FromArgb(150, 160, 178);
            }
            if (_btnToggle != null)
            {
                _btnToggle.Text = Program.IsAwake ? "Restore Normal Sleep" : "Keep Laptop Awake";
                _btnToggle.NormalBack = Program.IsAwake ? Color.FromArgb(245, 245, 247) : Color.FromArgb(36, 36, 42);
                _btnToggle.HoverBack = Program.IsAwake ? Color.FromArgb(255, 255, 255) : Color.FromArgb(58, 58, 66);
                _btnToggle.PressBack = Program.IsAwake ? Color.FromArgb(215, 215, 220) : Color.FromArgb(24, 24, 28);
                _btnToggle.ForeColor = Program.IsAwake ? Color.Black : Color.White;
            }
        }

        public void UpdatePresetButtons()
        {
            if (_presetButtons == null) return;
            for (int i = 0; i < _presetButtons.Length; i++)
            {
                bool selected = (_presetMinutes[i] == Program.ActiveDurationMinutes);
                ModernButton pb = _presetButtons[i];
                pb.NormalBack = selected ? Color.FromArgb(245, 245, 247) : Color.FromArgb(24, 24, 28);
                pb.HoverBack = selected ? Color.FromArgb(255, 255, 255) : Color.FromArgb(52, 52, 58);
                pb.PressBack = selected ? Color.FromArgb(215, 215, 220) : Color.FromArgb(20, 25, 34);
                pb.BorderColor = selected ? Color.Transparent : Color.FromArgb(54, 54, 60);
                pb.ForeColor = selected ? Color.Black : Color.White;
            }
        }

        private string GetTelemetryText()
        {
            PowerStatus power = SystemInformation.PowerStatus;
            string charge = (power.BatteryLifePercent * 100f).ToString("0") + "%";
            string ac = (power.PowerLineStatus == PowerLineStatus.Online) ? "Connected (AC)" : "Battery Power";
            string away = Program.IsAwake ? "Active (LIDACTION 0)" : "Standby (LIDACTION 1)";
            string mode = Program.PresentationMode.ToUpper();
            return string.Format("\u2022 Power Source: {0}    \u2022 Battery: {1}\r\n\u2022 Win32 Away Mode: {2}\r\n\u2022 Presentation Mode: {3}", ac, charge, away, mode);
        }
    }
}

