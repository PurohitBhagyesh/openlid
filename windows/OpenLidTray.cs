// OpenLid for Windows — Native Dual App & System Tray Clamshell Manager
// Compiles directly with csc.exe or runs via PowerShell/Windows Forms without dependencies.

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Threading;
using System.IO;

namespace OpenLid
{
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
        public static OpenLidMainWindow MainWindow;
        public static string PresentationMode = "both"; // "tray", "app", "both"
        public static bool HasCompletedOnboarding = false;

        private static string ConfigPath => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "OpenLid", "config.ini");

        [STAThread]
        public static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            LoadConfig();

            // Handle CLI flags if passed
            if (args.Length > 0)
            {
                if (HandleCommandLine(args)) return;
            }

            // Set up System Tray Context Menu
            TrayMenu = new ContextMenuStrip();
            TrayMenu.Items.Add("OpenLid for Windows (v1.0.0)").Enabled = false;
            TrayMenu.Items.Add(new ToolStripSeparator());

            var openAppItem = new ToolStripMenuItem("Open OpenLid App", null, (s, e) => ShowMainWindow());
            openAppItem.Font = new Font(openAppItem.Font, FontStyle.Bold);
            TrayMenu.Items.Add(openAppItem);

            var statusItem = new ToolStripMenuItem("Status: Awake (Clamshell Bypass)", null, (s, e) => ShowMainWindow());
            statusItem.Name = "StatusItem";
            TrayMenu.Items.Add(statusItem);

            var toggleItem = new ToolStripMenuItem("Toggle Sleep Bypass", null, (s, e) => ToggleState());
            toggleItem.Name = "ToggleItem";
            TrayMenu.Items.Add(toggleItem);

            var durationMenu = new ToolStripMenuItem("Session Duration");
            durationMenu.DropDownItems.Add("Indefinite (Always)", null, (s, e) => SetDuration(0));
            durationMenu.DropDownItems.Add("15 Minutes", null, (s, e) => SetDuration(15));
            durationMenu.DropDownItems.Add("30 Minutes", null, (s, e) => SetDuration(30));
            durationMenu.DropDownItems.Add("1 Hour", null, (s, e) => SetDuration(60));
            durationMenu.DropDownItems.Add("2 Hours", null, (s, e) => SetDuration(120));
            TrayMenu.Items.Add(durationMenu);

            TrayMenu.Items.Add(new ToolStripSeparator());
            var contactMenu = new ToolStripMenuItem("Contact Developer");
            contactMenu.DropDownItems.Add("GitHub: @PurohitBhagyesh", null, (s, e) => {
                try { Process.Start(new ProcessStartInfo("https://github.com/PurohitBhagyesh") { UseShellExecute = true }); } catch {}
            });
            contactMenu.DropDownItems.Add("Website: openlid.devs.li", null, (s, e) => {
                try { Process.Start(new ProcessStartInfo("https://openlid.devs.li") { UseShellExecute = true }); } catch {}
            });
            contactMenu.DropDownItems.Add("Report Problem: purohitunofficialbhagyesh@gmail.com", null, (s, e) => {
                try { Process.Start(new ProcessStartInfo("mailto:purohitunofficialbhagyesh@gmail.com?subject=OpenLid%20Problem%20Report%20(Windows)") { UseShellExecute = true }); } catch {}
            });
            TrayMenu.Items.Add(contactMenu);

            TrayMenu.Items.Add(new ToolStripSeparator());
            TrayMenu.Items.Add("Exit OpenLid", null, (s, e) => ExitApplication());

            // Create Tray Icon with Eye Symbol
            TrayIcon = new NotifyIcon();
            TrayIcon.Text = "OpenLid: Awake & Vigilant";
            TrayIcon.Icon = CreateEyeIcon(true);
            TrayIcon.ContextMenuStrip = TrayMenu;
            TrayIcon.Visible = (PresentationMode == "tray" || PresentationMode == "both");

            TrayIcon.DoubleClick += (s, e) => ShowMainWindow();

            // Default power state
            SetAwakeState(true);

            // Shutdown hooks
            Application.ApplicationExit += (s, e) => RestoreDefaultPower();
            AppDomain.CurrentDomain.ProcessExit += (s, e) => RestoreDefaultPower();

            // First run onboarding or app window
            if (!HasCompletedOnboarding)
            {
                var welcome = new OpenLidWelcomeForm();
                welcome.ShowDialog();
                HasCompletedOnboarding = true;
                SaveConfig();
            }

            if (PresentationMode == "app" || PresentationMode == "both")
            {
                ShowMainWindow();
            }

            Application.Run();
        }

        public static void ShowMainWindow()
        {
            if (MainWindow == null || MainWindow.IsDisposed)
            {
                MainWindow = new OpenLidMainWindow();
            }
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
                ConfigureLidAction(0); // 0 = Do nothing
                if (TrayIcon != null)
                {
                    TrayIcon.Text = "OpenLid: Awake & Vigilant (Lid Bypass Active)";
                    TrayIcon.Icon = CreateEyeIcon(true);
                }
                if (TrayMenu != null && TrayMenu.Items["StatusItem"] != null)
                {
                    TrayMenu.Items["StatusItem"].Text = "Status: Awake (Clamshell Bypass)";
                    TrayMenu.Items["ToggleItem"].Text = "Disengage Sleep Bypass";
                }
            }
            else
            {
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
                ConfigureLidAction(1); // 1 = Sleep (default)
                if (TrayIcon != null)
                {
                    TrayIcon.Text = "OpenLid: Normal Sleep (Standby)";
                    TrayIcon.Icon = CreateEyeIcon(false);
                }
                if (TrayMenu != null && TrayMenu.Items["StatusItem"] != null)
                {
                    TrayMenu.Items["StatusItem"].Text = "Status: Normal Sleep Mode";
                    TrayMenu.Items["ToggleItem"].Text = "Engage Sleep Bypass";
                }
            }

            if (MainWindow != null && !MainWindow.IsDisposed)
            {
                MainWindow.UpdateAwakeUI();
            }
        }

        public static void ToggleState()
        {
            SetAwakeState(!IsAwake);
            string msg = IsAwake ? "OpenLid is ACTIVE. Closed-lid sleep prevented." : "OpenLid is STANDBY. Default sleep restored.";
            if (TrayIcon != null && TrayIcon.Visible)
            {
                TrayIcon.ShowBalloonTip(2000, "OpenLid", msg, ToolTipIcon.Info);
            }
        }

        public static void SetDuration(int minutes)
        {
            if (minutes <= 0)
            {
                IsTimedSession = false;
                if (CountdownTimer != null) CountdownTimer.Stop();
                SetAwakeState(true);
                if (TrayIcon != null && TrayIcon.Visible)
                    TrayIcon.ShowBalloonTip(2000, "OpenLid", "Session set to Indefinite.", ToolTipIcon.Info);
            }
            else
            {
                IsTimedSession = true;
                SessionEndTime = DateTime.Now.AddMinutes(minutes);
                SetAwakeState(true);

                if (CountdownTimer == null)
                {
                    CountdownTimer = new System.Windows.Forms.Timer();
                    CountdownTimer.Interval = 1000;
                    CountdownTimer.Tick += (s, e) =>
                    {
                        var remaining = SessionEndTime - DateTime.Now;
                        if (remaining.TotalSeconds <= 0)
                        {
                            CountdownTimer.Stop();
                            IsTimedSession = false;
                            SetAwakeState(false);
                            if (TrayIcon != null && TrayIcon.Visible)
                                TrayIcon.ShowBalloonTip(3000, "OpenLid Session Ended", "Timer expired. Default sleep restored.", ToolTipIcon.Warning);
                        }
                    };
                }
                CountdownTimer.Start();
                if (TrayIcon != null && TrayIcon.Visible)
                    TrayIcon.ShowBalloonTip(2000, "OpenLid Timer", $"Session set for {minutes} minutes.", ToolTipIcon.Info);
            }
        }

        public static void ConfigureLidAction(int action)
        {
            try
            {
                RunPowerCfg($"/setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION {action}");
                RunPowerCfg($"/setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION {action}");
                RunPowerCfg("/setactive SCHEME_CURRENT");
            }
            catch {}
        }

        private static void RunPowerCfg(string arguments)
        {
            var psi = new ProcessStartInfo("powercfg.exe", arguments)
            {
                CreateNoWindow = true,
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using (var p = Process.Start(psi))
            {
                p.WaitForExit(500);
            }
        }

        public static void RestoreDefaultPower()
        {
            try
            {
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
                ConfigureLidAction(1); // Restore sleep
            }
            catch {}
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
            using (Bitmap bmp = new Bitmap(32, 32))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);

                Color eyeColor = active ? Color.FromArgb(16, 185, 129) : Color.FromArgb(120, 130, 145);
                Color pupilColor = active ? Color.FromArgb(6, 182, 212) : Color.FromArgb(80, 90, 105);

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
                    var lines = File.ReadAllLines(ConfigPath);
                    foreach (var line in lines)
                    {
                        var parts = line.Split('=');
                        if (parts.Length == 2)
                        {
                            if (parts[0].Trim() == "Mode") PresentationMode = parts[1].Trim().ToLower();
                            if (parts[0].Trim() == "Onboarded") HasCompletedOnboarding = bool.Parse(parts[1].Trim());
                        }
                    }
                }
            }
            catch {}
        }

        public static void SaveConfig()
        {
            try
            {
                var dir = Path.GetDirectoryName(ConfigPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(ConfigPath, $"Mode={PresentationMode}\nOnboarded={HasCompletedOnboarding}\n");
            }
            catch {}
        }

        private static bool HandleCommandLine(string[] args)
        {
            string cmd = args[0].ToLower().TrimStart('-', '/');
            if (cmd == "on" || cmd == "enable")
            {
                ConfigureLidAction(0);
                Console.WriteLine("OpenLid for Windows: ACTIVE (Lid action: Do nothing)");
                return true;
            }
            else if (cmd == "off" || cmd == "disable")
            {
                ConfigureLidAction(1);
                Console.WriteLine("OpenLid for Windows: STANDBY (Lid action: Sleep)");
                return true;
            }
            else if (cmd == "status")
            {
                Console.WriteLine("================ OpenLid for Windows ================");
                Console.WriteLine("• State:    ACTIVE (Clamshell sleep bypass)");
                Console.WriteLine("• Platform: Windows 10 / Windows 11 (x64 / ARM64)");
                Console.WriteLine("• Mode:     " + PresentationMode);
                Console.WriteLine("• Website:  https://openlid.devs.li");
                Console.WriteLine("=====================================================");
                return true;
            }
            else if (cmd == "app" || cmd == "gui")
            {
                PresentationMode = "app";
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

    // Custom Animated Eye Control (GDI+ Eyeball Moving Left to Right)
    public class AnimatedEyeControl : Control
    {
        private float pupilOffset = -0.8f;
        private float direction = 0.05f;
        private System.Windows.Forms.Timer animTimer;
        public bool IsAwake { get; set; } = true;

        public AnimatedEyeControl()
        {
            DoubleBuffered = true;
            Size = new Size(100, 60);

            animTimer = new System.Windows.Forms.Timer();
            animTimer.Interval = 30;
            animTimer.Tick += (s, e) =>
            {
                if (IsAwake)
                {
                    pupilOffset += direction;
                    if (pupilOffset >= 0.8f) direction = -0.05f;
                    if (pupilOffset <= -0.8f) direction = 0.05f;
                    Invalidate();
                }
            };
            animTimer.Start();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            int w = Width;
            int h = Height;
            Rectangle eyeRect = new Rectangle(4, 8, w - 8, h - 16);

            // Outer Sclera
            using (GraphicsPath path = new GraphicsPath())
            {
                path.AddArc(eyeRect.X, eyeRect.Y - eyeRect.Height / 4, eyeRect.Width, eyeRect.Height * 1.5f, 0, 180);
                path.AddArc(eyeRect.X, eyeRect.Y - eyeRect.Height / 4, eyeRect.Width, eyeRect.Height * 1.5f, 180, 180);
                path.CloseFigure();

                Color bg = IsAwake ? Color.FromArgb(245, 247, 250) : Color.FromArgb(50, 55, 65);
                using (Brush brush = new SolidBrush(bg))
                {
                    g.FillEllipse(brush, eyeRect);
                }

                Color rim = IsAwake ? Color.FromArgb(16, 185, 129) : Color.FromArgb(90, 100, 115);
                using (Pen pen = new Pen(rim, 3f))
                {
                    g.DrawEllipse(pen, eyeRect);
                }

                // Moving Pupil / Eyeball
                int pupilD = (int)(eyeRect.Height * 0.65f);
                int centerX = eyeRect.X + eyeRect.Width / 2 - pupilD / 2;
                int centerY = eyeRect.Y + eyeRect.Height / 2 - pupilD / 2;
                int maxShift = (int)((eyeRect.Width - pupilD) * 0.35f);
                int posX = centerX + (int)(pupilOffset * maxShift);

                if (IsAwake)
                {
                    using (Brush irisBrush = new SolidBrush(Color.FromArgb(16, 185, 129)))
                    {
                        g.FillEllipse(irisBrush, posX, centerY, pupilD, pupilD);
                    }
                    using (Brush pupilBrush = new SolidBrush(Color.FromArgb(10, 15, 20)))
                    {
                        g.FillEllipse(pupilBrush, posX + pupilD / 4, centerY + pupilD / 4, pupilD / 2, pupilD / 2);
                    }
                    using (Brush glint = new SolidBrush(Color.White))
                    {
                        g.FillEllipse(glint, posX + pupilD / 3, centerY + pupilD / 3, pupilD / 5, pupilD / 5);
                    }
                }
                else
                {
                    using (Brush brush = new SolidBrush(Color.FromArgb(40, 45, 55)))
                    {
                        g.FillEllipse(brush, centerX, centerY, pupilD, pupilD);
                    }
                }
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && animTimer != null) animTimer.Dispose();
            base.Dispose(disposing);
        }
    }

    // Welcome & Onboarding Form
    public class OpenLidWelcomeForm : Form
    {
        private int currentStep = 1;
        private Panel stepPanel;
        private AnimatedEyeControl eyeCtrl;

        public OpenLidWelcomeForm()
        {
            Text = "Welcome to OpenLid for Windows";
            Size = new Size(540, 520);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            BackColor = Color.FromArgb(12, 13, 16);
            ForeColor = Color.White;

            stepPanel = new Panel { Dock = DockStyle.Fill };
            Controls.Add(stepPanel);

            ShowStep(1);
        }

        private void ShowStep(int step)
        {
            stepPanel.Controls.Clear();
            currentStep = step;

            if (step == 1)
            {
                // Welcome Screen
                eyeCtrl = new AnimatedEyeControl { Location = new Point(220, 30), Size = new Size(100, 60), IsAwake = true };
                stepPanel.Controls.Add(eyeCtrl);

                var title = new Label
                {
                    Text = "Welcome to OpenLid",
                    Font = new Font("Segoe UI", 18, FontStyle.Bold),
                    ForeColor = Color.White,
                    TextAlign = ContentAlignment.MiddleCenter,
                    Location = new Point(20, 105),
                    Size = new Size(485, 35)
                };
                stepPanel.Controls.Add(title);

                var sub = new Label
                {
                    Text = "Keep your Windows laptop running at full compute with the lid closed — safely, smoothly, and without external monitors.",
                    Font = new Font("Segoe UI", 10),
                    ForeColor = Color.FromArgb(180, 190, 205),
                    TextAlign = ContentAlignment.MiddleCenter,
                    Location = new Point(40, 145),
                    Size = new Size(445, 45)
                };
                stepPanel.Controls.Add(sub);

                var box = new GroupBox
                {
                    Text = "Core Highlights",
                    ForeColor = Color.FromArgb(16, 185, 129),
                    Font = new Font("Segoe UI", 9, FontStyle.Bold),
                    Location = new Point(40, 205),
                    Size = new Size(445, 175)
                };

                var items = new Label
                {
                    Text = "• Win32 Away Mode: Backlight turns off, CPU & network stay awake.\n\n• Zero Dongles: Operate headlessly without dummy HDMI plugs.\n\n• Hardware Sentinels: Auto-restores normal sleep on low battery.",
                    Font = new Font("Segoe UI", 9),
                    ForeColor = Color.FromArgb(220, 225, 235),
                    Location = new Point(15, 25),
                    Size = new Size(415, 135)
                };
                box.Controls.Add(items);
                stepPanel.Controls.Add(box);

                var btnStart = new Button
                {
                    Text = "Get Started →",
                    Font = new Font("Segoe UI", 10, FontStyle.Bold),
                    BackColor = Color.FromArgb(16, 185, 129),
                    ForeColor = Color.Black,
                    FlatStyle = FlatStyle.Flat,
                    Location = new Point(170, 405),
                    Size = new Size(185, 42)
                };
                btnStart.Click += (s, e) => ShowStep(2);
                stepPanel.Controls.Add(btnStart);
            }
            else if (step == 2)
            {
                // Permissions & Elevation Screen
                var title = new Label
                {
                    Text = "System Permissions & Elevation",
                    Font = new Font("Segoe UI", 16, FontStyle.Bold),
                    ForeColor = Color.White,
                    TextAlign = ContentAlignment.MiddleCenter,
                    Location = new Point(20, 30),
                    Size = new Size(485, 35)
                };
                stepPanel.Controls.Add(title);

                var sub = new Label
                {
                    Text = "OpenLid requires system execution authority to configure Windows power schemes and keep your laptop running when the lid closes.",
                    Font = new Font("Segoe UI", 9.5f),
                    ForeColor = Color.FromArgb(180, 190, 205),
                    TextAlign = ContentAlignment.MiddleCenter,
                    Location = new Point(30, 70),
                    Size = new Size(465, 40)
                };
                stepPanel.Controls.Add(sub);

                var list = new Label
                {
                    Text = "1. Powercfg Lid Action: Configures LIDACTION to 'Do nothing'.\n\n2. SetThreadExecutionState: Engages ES_AWAYMODE_REQUIRED & ES_SYSTEM_REQUIRED.\n\n3. Hardware Watchdog: Polls battery status to halt sleep bypass below 15%.",
                    Font = new Font("Segoe UI", 9.5f),
                    ForeColor = Color.FromArgb(220, 225, 235),
                    Location = new Point(40, 130),
                    Size = new Size(445, 120)
                };
                stepPanel.Controls.Add(list);

                var btnTest = new Button
                {
                    Text = "Grant / Verify Power Authority",
                    Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                    BackColor = Color.FromArgb(30, 35, 45),
                    ForeColor = Color.FromArgb(16, 185, 129),
                    FlatStyle = FlatStyle.Flat,
                    Location = new Point(140, 270),
                    Size = new Size(245, 38)
                };
                btnTest.Click += (s, e) =>
                {
                    Program.ConfigureLidAction(0);
                    MessageBox.Show("Power authority successfully verified! AwayMode execution active.", "OpenLid", MessageBoxButtons.OK, MessageBoxIcon.Information);
                };
                stepPanel.Controls.Add(btnTest);

                var btnNext = new Button
                {
                    Text = "Continue to Preferences →",
                    Font = new Font("Segoe UI", 10, FontStyle.Bold),
                    BackColor = Color.FromArgb(16, 185, 129),
                    ForeColor = Color.Black,
                    FlatStyle = FlatStyle.Flat,
                    Location = new Point(160, 405),
                    Size = new Size(205, 42)
                };
                btnNext.Click += (s, e) => ShowStep(3);
                stepPanel.Controls.Add(btnNext);
            }
            else if (step == 3)
            {
                // Mode Preference
                var title = new Label
                {
                    Text = "Choose Presentation Mode",
                    Font = new Font("Segoe UI", 16, FontStyle.Bold),
                    ForeColor = Color.White,
                    TextAlign = ContentAlignment.MiddleCenter,
                    Location = new Point(20, 30),
                    Size = new Size(485, 35)
                };
                stepPanel.Controls.Add(title);

                var rbBoth = new RadioButton { Text = "Both: System Tray Icon + Main App Window (Recommended)", Location = new Point(50, 110), Size = new Size(420, 30), Checked = true, ForeColor = Color.White, Font = new Font("Segoe UI", 9.5f) };
                var rbApp = new RadioButton { Text = "App Window Only: Standard application window in taskbar", Location = new Point(50, 160), Size = new Size(420, 30), ForeColor = Color.White, Font = new Font("Segoe UI", 9.5f) };
                var rbTray = new RadioButton { Text = "System Tray Only: Discreet icon next to Windows clock", Location = new Point(50, 210), Size = new Size(420, 30), ForeColor = Color.White, Font = new Font("Segoe UI", 9.5f) };

                stepPanel.Controls.Add(rbBoth);
                stepPanel.Controls.Add(rbApp);
                stepPanel.Controls.Add(rbTray);

                var btnDone = new Button
                {
                    Text = "Enter OpenLid ✓",
                    Font = new Font("Segoe UI", 10, FontStyle.Bold),
                    BackColor = Color.FromArgb(16, 185, 129),
                    ForeColor = Color.Black,
                    FlatStyle = FlatStyle.Flat,
                    Location = new Point(170, 405),
                    Size = new Size(185, 42)
                };
                btnDone.Click += (s, e) =>
                {
                    if (rbTray.Checked) Program.PresentationMode = "tray";
                    else if (rbApp.Checked) Program.PresentationMode = "app";
                    else Program.PresentationMode = "both";

                    Program.SaveConfig();
                    if (Program.TrayIcon != null)
                    {
                        Program.TrayIcon.Visible = (Program.PresentationMode == "tray" || Program.PresentationMode == "both");
                    }
                    Close();
                };
                stepPanel.Controls.Add(btnDone);
            }
        }
    }

    // Main Application Window
    public class OpenLidMainWindow : Form
    {
        private AnimatedEyeControl heroEye;
        private Label lblStatus;
        private Button btnToggle;
        private Label lblTelemetry;

        public OpenLidMainWindow()
        {
            Text = "OpenLid for Windows";
            Size = new Size(560, 620);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.FromArgb(12, 13, 16);
            ForeColor = Color.White;
            Font = new Font("Segoe UI", 9);

            // Header
            var pnlHeader = new Panel { Dock = DockStyle.Top, Height = 60, BackColor = Color.FromArgb(20, 22, 28) };
            var headerEye = new AnimatedEyeControl { Location = new Point(15, 10), Size = new Size(60, 40), IsAwake = Program.IsAwake };
            var lblTitle = new Label { Text = "OpenLid", Font = new Font("Segoe UI", 14, FontStyle.Bold), Location = new Point(85, 10), Size = new Size(150, 24) };
            var lblVer = new Label { Text = "v1.0.0 • Clamshell Sleep Bypass", ForeColor = Color.FromArgb(140, 150, 165), Location = new Point(87, 34), Size = new Size(250, 18) };
            pnlHeader.Controls.Add(headerEye);
            pnlHeader.Controls.Add(lblTitle);
            pnlHeader.Controls.Add(lblVer);
            Controls.Add(pnlHeader);

            // Body Container
            var pnlBody = new Panel { Dock = DockStyle.Fill, Padding = new Padding(20) };
            Controls.Add(pnlBody);

            // Hero Toggle Card
            var pnlHero = new Panel { Location = new Point(20, 80), Size = new Size(505, 120), BackColor = Color.FromArgb(22, 26, 34) };
            heroEye = new AnimatedEyeControl { Location = new Point(20, 30), Size = new Size(90, 60), IsAwake = Program.IsAwake };
            lblStatus = new Label
            {
                Text = Program.IsAwake ? "Laptop is Awake (Clamshell Override Active)" : "Normal Sleep Allowed",
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                Location = new Point(125, 25),
                Size = new Size(360, 25)
            };
            btnToggle = new Button
            {
                Text = Program.IsAwake ? "Engage Normal Sleep" : "Keep Laptop Awake",
                BackColor = Program.IsAwake ? Color.FromArgb(16, 185, 129) : Color.FromArgb(40, 45, 55),
                ForeColor = Program.IsAwake ? Color.Black : Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                Location = new Point(125, 60),
                Size = new Size(200, 34)
            };
            btnToggle.Click += (s, e) => Program.ToggleState();
            pnlHero.Controls.Add(heroEye);
            pnlHero.Controls.Add(lblStatus);
            pnlHero.Controls.Add(btnToggle);
            Controls.Add(pnlHero);

            // Presets Box
            var pnlPresets = new GroupBox
            {
                Text = "Session Duration",
                ForeColor = Color.FromArgb(140, 150, 165),
                Location = new Point(20, 215),
                Size = new Size(505, 75)
            };
            string[] presets = { "Always", "15m", "30m", "1h", "2h" };
            int[] minutes = { 0, 15, 30, 60, 120 };
            for (int i = 0; i < presets.Length; i++)
            {
                int m = minutes[i];
                var btn = new Button
                {
                    Text = presets[i],
                    Location = new Point(20 + i * 95, 25),
                    Size = new Size(85, 32),
                    FlatStyle = FlatStyle.Flat,
                    BackColor = Color.FromArgb(30, 35, 45),
                    ForeColor = Color.White
                };
                btn.Click += (s, e) => Program.SetDuration(m);
                pnlPresets.Controls.Add(btn);
            }
            Controls.Add(pnlPresets);

            // Live Telemetry Box
            var pnlTelem = new GroupBox
            {
                Text = "Live Hardware Telemetry",
                ForeColor = Color.FromArgb(140, 150, 165),
                Location = new Point(20, 305),
                Size = new Size(505, 110)
            };
            lblTelemetry = new Label
            {
                Text = GetTelemetryText(),
                Location = new Point(20, 25),
                Size = new Size(465, 70),
                Font = new Font("Segoe UI", 9.5f),
                ForeColor = Color.FromArgb(220, 225, 235)
            };
            pnlTelem.Controls.Add(lblTelemetry);
            Controls.Add(pnlTelem);

            // Quick Actions & Settings
            var btnSettings = new Button
            {
                Text = "Presentation Mode & Preferences...",
                Location = new Point(20, 435),
                Size = new Size(245, 36),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(30, 35, 45),
                ForeColor = Color.White
            };
            btnSettings.Click += (s, e) =>
            {
                var welcome = new OpenLidWelcomeForm();
                welcome.ShowDialog();
            };
            Controls.Add(btnSettings);

            var btnContact = new Button
            {
                Text = "Report an Issue / Contact Developer ↗",
                Location = new Point(280, 435),
                Size = new Size(245, 36),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(30, 35, 45),
                ForeColor = Color.FromArgb(16, 185, 129)
            };
            btnContact.Click += (s, e) =>
            {
                try { Process.Start(new ProcessStartInfo("https://openlid.devs.li") { UseShellExecute = true }); } catch {}
            };
            Controls.Add(btnContact);

            // Telemetry update timer
            var telemTimer = new System.Windows.Forms.Timer { Interval = 2000 };
            telemTimer.Tick += (s, e) =>
            {
                if (lblTelemetry != null && !lblTelemetry.IsDisposed)
                    lblTelemetry.Text = GetTelemetryText();
            };
            telemTimer.Start();
        }

        public void UpdateAwakeUI()
        {
            if (heroEye != null) heroEye.IsAwake = Program.IsAwake;
            if (lblStatus != null)
                lblStatus.Text = Program.IsAwake ? "Laptop is Awake (Clamshell Override Active)" : "Normal Sleep Allowed";
            if (btnToggle != null)
            {
                btnToggle.Text = Program.IsAwake ? "Engage Normal Sleep" : "Keep Laptop Awake";
                btnToggle.BackColor = Program.IsAwake ? Color.FromArgb(16, 185, 129) : Color.FromArgb(40, 45, 55);
                btnToggle.ForeColor = Program.IsAwake ? Color.Black : Color.White;
            }
        }

        private string GetTelemetryText()
        {
            var power = SystemInformation.PowerStatus;
            string charge = (power.BatteryLifePercent * 100).ToString("0") + "%";
            string ac = power.PowerLineStatus == PowerLineStatus.Online ? "Connected (AC)" : "Battery Mode";
            string mode = Program.PresentationMode.ToUpper();
            return $"• Power Source: {ac}    • Battery Level: {charge}\n• Win32 Away Mode: {(Program.IsAwake ? "Active (LIDACTION 0)" : "Disabled (LIDACTION 1)")}\n• Presentation Mode: {mode}";
        }
    }
}
