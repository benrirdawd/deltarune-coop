# Windows stand-in for the Xvfb displays and scrot of the Linux test scripts.
#   winwindow.ps1 place <pid> <slot>        tile the game window (slot 0, 1, 2... left to right,
#                                           wrapping into rows) and lower its CPU priority
#   winwindow.ps1 shot <pid> <png> [slot]   screenshot the game window (brought on top for a moment)
#   winwindow.ps1 watch 0 <game folder>     place every test game started from that folder (runs until stopped)
# MP_SLOTS: how many places the grid has (default 6); MP_WATCH=1: the windows stay on top.
# The window is moved from outside: changing fullscreen inside the game would write to its settings.
param([string]$Action, [int]$ProcId, [string]$Arg, [int]$Slot = -1)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT { public int L, T, R, B; }
public static class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
}
"@
[void][W]::SetProcessDPIAware()
$TOP = [IntPtr](-1); $NOTOP = [IntPtr](-2)
$SHOW = [uint32]0x0040; $NOMOVESIZE = [uint32]0x0003; $NOACTIVATE = [uint32]0x0010; $NOZORDER = [uint32]0x0004

function Get-Window($id) {
    for ($i = 0; $i -lt 40; $i++) {
        $p = Get-Process -Id $id -ErrorAction SilentlyContinue
        if (-not $p) { return $null }
        if ($p.MainWindowHandle -ne 0) { return $p }
        Start-Sleep -Milliseconds 250
    }
    return $p
}

function Place($p, $slot) {
    # A grid over the primary screen with room for MP_SLOTS windows (default 6), no overlaps:
    # the column count that gives the biggest 4:3 game picture, the grid centred on the screen.
    $n = 6
    if ($env:MP_SLOTS) { $n = [math]::Max(1, [int]$env:MP_SLOTS) }
    $slot = $slot % $n
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $title = 32   # window title bar and borders
    $best = 0; $cols = 1
    for ($c = 1; $c -le $n; $c++) {
        $r = [math]::Ceiling($n / $c)
        $w = [math]::Floor([math]::Min($wa.Width / $c, ($wa.Height / $r - $title) * 4 / 3))
        if ($w -gt $best) { $best = $w; $cols = $c }
    }
    $rows = [math]::Ceiling($n / $cols)
    $w = [int]$best; $h = [int]($w * 3 / 4) + $title
    $x0 = $wa.X + [int](($wa.Width - $cols * $w) / 2); $y0 = $wa.Y + [int](($wa.Height - $rows * $h) / 2)
    $x = $x0 + ($slot % $cols) * $w; $y = $y0 + [math]::Floor($slot / $cols) * $h
    if ($script:OnlyIfMoved) {
        # (watch: nothing to do while the window is where it belongs)
        $cur = New-Object RECT
        [void][W]::GetWindowRect($p.MainWindowHandle, [ref]$cur)
        if ($cur.L -eq $x -and $cur.T -eq $y -and ($cur.R - $cur.L) -eq $w -and ($cur.B - $cur.T) -eq $h) { return }
    }
    # MP_WATCH=1: always on top (to watch the tests over the other windows), without taking the focus.
    # (Two calls: together with a move, the change of layer didn't take.)
    $z = $NOTOP
    if ($env:MP_WATCH -eq "1") { $z = $TOP }
    [void][W]::SetWindowPos($p.MainWindowHandle, [IntPtr]::Zero, $x, $y, $w, $h, $SHOW -bor $NOACTIVATE -bor $NOZORDER)
    [void][W]::SetWindowPos($p.MainWindowHandle, $z, 0, 0, 0, 0, $NOMOVESIZE -bor $NOACTIVATE)
}

if ($Action -eq "watch") {
    # One watcher for a whole run (tools/sweepall.sh): every half second it looks for new test games
    # (started from <Arg>, the game folder) and puts back any that isn't in its place. Its place in the
    # grid comes from its command line: the pair from the port (27000 + 1000 * pair, see sweep.py),
    # host first, then P2, P3... (MP_PAIRSIZE games per pair, default 2). No process per game.
    $script:OnlyIfMoved = $true
    $size = 2
    if ($env:MP_PAIRSIZE) { $size = [int]$env:MP_PAIRSIZE }
    $seen = @{}
    # (It stops when the file MP_WATCH_STOP exists, or after 90 s without any test game.)
    $last = Get-Date
    while (-not ($env:MP_WATCH_STOP -and (Test-Path $env:MP_WATCH_STOP)) -and ((Get-Date) - $last).TotalSeconds -lt 90) {
        $games = @(Get-Process DELTARUNE -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Arg\*" })
        if ($games.Count -gt 0) { $last = Get-Date }
        foreach ($g in $games) {
            if (-not $seen.ContainsKey($g.Id)) {
                $cl = (Get-CimInstance Win32_Process -Filter "ProcessId=$($g.Id)" -ErrorAction SilentlyContinue).CommandLine
                $slot = 0
                if ($cl -match '(?:-mpport |-mpjoin \S*?:)(\d+)') { $port = [int]$Matches[1]; if ($port -ge 27000) { $slot = [math]::Floor(($port - 27000) / 1000) * $size } }
                if ($cl -match '-mpname P(\d+)') { $slot += [int]$Matches[1] - 1 }
                $seen[$g.Id] = @{ Slot = $slot; Since = Get-Date }
                try { $g.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
            }
            # Placed again whenever it isn't where it belongs (the game sizes and centres its window
            # itself a few seconds after it opens, later when the PC is busy).
            if ($g.MainWindowHandle -ne 0) { Place $g $seen[$g.Id].Slot }
        }
        Start-Sleep -Milliseconds 500
    }
}

$p = Get-Window $ProcId
if (-not $p -or $p.MainWindowHandle -eq 0) { "no window for process $ProcId"; exit 1 }
switch ($Action) {
    "place" {
        # The game sizes and centres its window itself a few seconds after it opens: placed again
        # every half second for 8 s, the grid wins. (Runs beside the game: no test time.)
        for ($i = 0; $i -lt 16; $i++) {
            $p.Refresh()
            if ($p.HasExited) { break }
            Place $p ([int]$Arg)
            Start-Sleep -Milliseconds 500
        }
        try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
    }
    "shot" {
        if ($Slot -ge 0) { Place $p $Slot }
        [void][W]::SetWindowPos($p.MainWindowHandle, $TOP, 0, 0, 0, 0, $NOMOVESIZE -bor $NOACTIVATE)
        Start-Sleep -Milliseconds 250
        $r = New-Object RECT
        [void][W]::GetWindowRect($p.MainWindowHandle, [ref]$r)
        $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
        $bmp.Save($Arg, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose(); $bmp.Dispose()
        if ($env:MP_WATCH -ne "1") { [void][W]::SetWindowPos($p.MainWindowHandle, $NOTOP, 0, 0, 0, 0, $NOMOVESIZE -bor $NOACTIVATE) }
    }
    default { "usage: winwindow.ps1 place|shot <pid> <slot|png>"; exit 2 }
}
