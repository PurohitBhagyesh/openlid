// OpenLid for Windows — Native System Tray Clamshell Awakener
// Compiles directly with csc.exe or runs via PowerShell/Windows Forms without dependencies.

using System;
using System.Drawing;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Threading;

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

        private static NotifyIcon trayIcon;
        private static ContextMenuStrip trayMenu;
        private static bool isAwake = true;
        private static System.Windows.Forms.Timer countdownTimer;
        private static DateTime sessionEndTime;
        private static bool isTimedSession = false;

        [STAThread]
        public static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Handle CLI flags if passed
            if (args.Length > 0)
            {
                HandleCommandLine(args);
                return;
            }

            // Set up System Tray Context Menu
            trayMenu = new ContextMenuStrip();
            trayMenu.Items.Add("OpenLid for Windows (v1.0.0)").Enabled = false;
            trayMenu.Items.Add(new ToolStripSeparator());

            var statusItem = new ToolStripMenuItem("Status: Awake (Clamshell Bypass)", null, (s, e) => ShowStatus());
            statusItem.Name = "StatusItem";
            statusItem.Font = new Font(statusItem.Font, FontStyle.Bold);
            trayMenu.Items.Add(statusItem);

            var toggleItem = new ToolStripMenuItem("Toggle Sleep Bypass", null, (s, e) => ToggleState());
            toggleItem.Name = "ToggleItem";
            trayMenu.Items.Add(toggleItem);

            var durationMenu = new ToolStripMenuItem("Timed Session");
            durationMenu.DropDownItems.Add("Indefinite (Until stopped)", null, (s, e) => SetDuration(0));
            durationMenu.DropDownItems.Add("15 Minutes", null, (s, e) => SetDuration(15));
            durationMenu.DropDownItems.Add("30 Minutes", null, (s, e) => SetDuration(30));
            durationMenu.DropDownItems.Add("1 Hour", null, (s, e) => SetDuration(60));
            durationMenu.DropDownItems.Add("2 Hours", null, (s, e) => SetDuration(120));
            trayMenu.Items.Add(durationMenu);

            trayMenu.Items.Add(new ToolStripSeparator());
            trayMenu.Items.Add("Website: openlid.devs.li", null, (s, e) => Process.Start("https://openlid.devs.li"));
            trayMenu.Items.Add(new ToolStripSeparator());
            trayMenu.Items.Add("Exit OpenLid", null, (s, e) => ExitApplication());

            // Create Tray Icon with Eye Symbol
            trayIcon = new NotifyIcon();
            trayIcon.Text = "OpenLid: Awake & Vigilant";
            trayIcon.Icon = CreateEyeIcon(true);
            trayIcon.ContextMenuStrip = trayMenu;
            trayIcon.Visible = true;

            trayIcon.DoubleClick += (s, e) => ToggleState();

            // Set default Awake state
            SetAwakeState(true);

            // Handle clean shutdown on logoff or exit
            Application.ApplicationExit += (s, e) => RestoreDefaultPower();
            AppDomain.CurrentDomain.ProcessExit += (s, e) => RestoreDefaultPower();

            // Show initial notification
            trayIcon.ShowBalloonTip(3000, "OpenLid Active", "Your laptop will keep running with the lid closed.", ToolTipIcon.Info);

            Application.Run();
        }

        private static void SetAwakeState(bool awake)
        {
            isAwake = awake;
            if (awake)
            {
                // Prevent system sleep, allow display sleep if lid is closed (Away Mode)
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS | EXECUTION_STATE.ES_SYSTEM_REQUIRED | EXECUTION_STATE.ES_AWAYMODE_REQUIRED);
                ConfigureLidAction(0); // 0 = Do nothing
                trayIcon.Text = "OpenLid: Awake & Vigilant (Lid Bypass Active)";
                trayIcon.Icon = CreateEyeIcon(true);
                trayMenu.Items["StatusItem"].Text = "Status: Awake (Clamshell Bypass)";
                trayMenu.Items["ToggleItem"].Text = "Disengage Sleep Bypass";
            }
            else
            {
                // Clear execution state
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
                ConfigureLidAction(1); // 1 = Sleep (default)
                trayIcon.Text = "OpenLid: Normal Sleep (Standby)";
                trayIcon.Icon = CreateEyeIcon(false);
                trayMenu.Items["StatusItem"].Text = "Status: Normal Sleep Mode";
                trayMenu.Items["ToggleItem"].Text = "Engage Sleep Bypass";
            }
        }

        private static void ToggleState()
        {
            SetAwakeState(!isAwake);
            string msg = isAwake ? "OpenLid is ACTIVE. Closed-lid sleep prevented." : "OpenLid is STANDBY. Default sleep restored.";
            trayIcon.ShowBalloonTip(2000, "OpenLid", msg, ToolTipIcon.Info);
        }

        private static void SetDuration(int minutes)
        {
            if (minutes <= 0)
            {
                isTimedSession = false;
                if (countdownTimer != null) countdownTimer.Stop();
                SetAwakeState(true);
                trayIcon.ShowBalloonTip(2000, "OpenLid", "Session set to Indefinite.", ToolTipIcon.Info);
            }
            else
            {
                isTimedSession = true;
                sessionEndTime = DateTime.Now.AddMinutes(minutes);
                SetAwakeState(true);

                if (countdownTimer == null)
                {
                    countdownTimer = new System.Windows.Forms.Timer();
                    countdownTimer.Interval = 1000;
                    countdownTimer.Tick += (s, e) =>
                    {
                        var remaining = sessionEndTime - DateTime.Now;
                        if (remaining.TotalSeconds <= 0)
                        {
                            countdownTimer.Stop();
                            isTimedSession = false;
                            SetAwakeState(false);
                            trayIcon.ShowBalloonTip(3000, "OpenLid Session Ended", "Timer expired. Default sleep restored.", ToolTipIcon.Warning);
                        }
                    };
                }
                countdownTimer.Start();
                trayIcon.ShowBalloonTip(2000, "OpenLid Timer", $"Session set for {minutes} minutes.", ToolTipIcon.Info);
            }
        }

        private static void ShowStatus()
        {
            string state = isAwake ? "ACTIVE (Clamshell Bypass Engaged)" : "STANDBY (Default Sleep)";
            MessageBox.Show($"OpenLid for Windows v1.0.0\n\nState: {state}\nTarget: Windows 11 / 10\nAPI: SetThreadExecutionState & PowerScheme\nWebsite: https://openlid.devs.li", "OpenLid Status", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private static void ConfigureLidAction(int action)
        {
            // 0 = Do nothing, 1 = Sleep, 2 = Hibernate, 3 = Shut down
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

        private static void RestoreDefaultPower()
        {
            try
            {
                SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
                ConfigureLidAction(1); // Restore sleep
            }
            catch {}
        }

        private static void ExitApplication()
        {
            RestoreDefaultPower();
            if (trayIcon != null)
            {
                trayIcon.Visible = false;
                trayIcon.Dispose();
            }
            Application.Exit();
        }

        private static Icon CreateEyeIcon(bool active)
        {
            using (Bitmap bmp = new Bitmap(32, 32))
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);

                Color eyeColor = active ? Color.FromArgb(16, 185, 129) : Color.FromArgb(120, 130, 145);
                Color pupilColor = active ? Color.FromArgb(6, 182, 212) : Color.FromArgb(80, 90, 105);

                using (Pen pen = new Pen(eyeColor, 3f))
                {
                    // Eye outline ellipse
                    g.DrawEllipse(pen, 2, 8, 28, 16);
                }

                using (Brush brush = new SolidBrush(pupilColor))
                {
                    // Center pupil
                    g.FillEllipse(brush, 11, 11, 10, 10);
                }

                IntPtr hIcon = bmp.GetHicon();
                return Icon.FromHandle(hIcon);
            }
        }

        private static void HandleCommandLine(string[] args)
        {
            string cmd = args[0].ToLower().TrimStart('-', '/');
            if (cmd == "on")
            {
                ConfigureLidAction(0);
                Console.WriteLine("OpenLid for Windows: ACTIVE (Lid action: Do nothing)");
            }
            else if (cmd == "off")
            {
                ConfigureLidAction(1);
                Console.WriteLine("OpenLid for Windows: STANDBY (Lid action: Sleep)");
            }
            else if (cmd == "status")
            {
                Console.WriteLine("OpenLid for Windows v1.0.0");
                Console.WriteLine("Platform: Windows 10 / Windows 11");
                Console.WriteLine("Website:  https://openlid.devs.li");
            }
        }
    }
}
