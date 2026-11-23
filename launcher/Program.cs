using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Threading;
using System.Windows.Forms;

namespace DeltaruneOnline
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Test hooks: --render <folder> draws every screen to PNGs; --auto installs or updates without a window.
            if (args.Length >= 2 && args[0] == "--render") { MainForm.RenderScreens(args[1]); return 0; }
            if (args.Length >= 1 && args[0] == "--auto") return Auto();
            // DELTARUNE COOP.exe (in the DELTARUNE folder) or --play: straight into the co-op game.
            if (Array.IndexOf(args, "--play") >= 0 || string.Equals(Path.GetFileName(Core.RunningExe), Core.CoopExe, StringComparison.OrdinalIgnoreCase))
                return PlayNow();

            using (var mutex = new Mutex(true, "DeltaruneOnlineLauncher", out bool first))
            {
                if (!first) return 0;   // already open
                var core = new Core();
                core.CleanOldLauncher();
                // Started from a download while it's already installed: hand over to the installed launcher.
                var local = Core.LocalPackage();
                bool isInstalledExe = string.Equals(Path.GetFullPath(Core.RunningExe), Path.GetFullPath(core.InstalledExe), StringComparison.OrdinalIgnoreCase);
                if (!isInstalledExe && core.IsInstalled && File.Exists(core.InstalledExe)
                    && (local == null || Core.ReadVersion(local) <= core.AppVersion))
                {
                    mutex.ReleaseMutex();
                    Process.Start(core.InstalledExe);
                    return 0;
                }
                Application.Run(new MainForm(core, Array.IndexOf(args, "--after-update") >= 0, local != null && core.IsInstalled && !isInstalledExe));
            }
            return 0;
        }

        // Starts the co-op game when it is installed and up to date; anything else (first install, a new
        // version, a Steam update to patch for) goes to the launcher's window.
        static int PlayNow()
        {
            var core = new Core();
            try
            {
                if (core.IsInstalled && Core.IsGame(core.GameDir) && core.CanPlay && !core.NeedsPatch)
                {
                    if (!core.GameRunning()) core.StartGame();
                    return 0;
                }
            }
            catch (Exception e) { core.Log("play: " + e.Message); }
            // Installed but not ready to play (a Steam update needs patching again, say): the launcher's
            // window does that, also when it's this very exe.
            var exe = File.Exists(core.InstalledExe) ? core.InstalledExe : null;
            if (exe != null)
                Process.Start(new ProcessStartInfo(exe) { UseShellExecute = true });
            else
                MessageBox.Show("DELTARUNE Online isn't installed yet: open the DELTARUNE Online launcher first.", "DELTARUNE COOP");
            return 0;
        }

        static int Auto()
        {
            var core = new Core();
            try
            {
                if (!Core.IsGame(core.GameDir)) core.GameDir = Core.FindGame();
                string note = core.IsInstalled ? Flow.Update(core, true, out _) : Flow.Install(core);
                core.Log("auto: " + note);
                return 0;
            }
            catch (Exception e)
            {
                core.Log("auto failed: " + e);
                return 1;
            }
        }
    }
}
