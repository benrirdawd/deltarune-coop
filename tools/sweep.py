#!/usr/bin/env python3
"""Story-scene sweep: for each (room, plot) scenario from tools/sweepgen.py, a host starts in
that room at that point of the story and a client joins from another room (so it is moved
there by the mod, the way a joining player is). Both play with bots (mash, wander) for a
while; the result is checked with tools/mpcheck.py. One pair at a time.

Results: work/sweep/ch<N>/results.txt, one line per scenario:
  <room> <plot> PASS|FAIL|CRASH <details>
Failing scenarios keep their logs and final screenshots in work/sweep/ch<N>/<room>_<plot>/.

Usage: sweep.py <chapter> [--secs 45] [--from N] [--limit N] [--only room[:plot]] [--solo]
  --solo: host only, not hosting (is a crash the game's own / the test setup's?)
  --speed N: run the games N times faster once connected (default MP_SPEED, else 20; 1 = normal).
  --secs: game time from the moment everyone joined (host frames / 30), however fast the games run.
Several pairs can run at once (--pair 0, 1, 2 ...): each has its own ports and window slots.
Linux (Wine + Xvfb) or Windows (native game; the shell scripts run through Git Bash).
"""
import argparse, os, re, shutil, signal, subprocess, sys, time

WIN = os.name == "nt"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BATTLE_ROOM = {1: ("room_field1", 100), 2: ("room_dw_cyber_maze_virokun", 100), 3: ("room_dw_couch_overworld_02", 100),
               4: ("room_dw_church_worshiproom", 100), 5: ("room_dw_garden_intro", 100)}
START = {1: "room_field1", 2: "room_dw_cyber_maze_virokun", 3: "room_dw_couch_overworld_02",
         4: "room_dw_church_worshiproom", 5: "room_dw_garden_intro"}


def run(cmd, **kw):
    return subprocess.run(cmd, **kw)


def bash():
    # Git Bash (not WSL's System32 bash.exe) runs the tools' shell scripts on Windows.
    b = shutil.which("bash")
    if b and "system32" not in b.lower():
        return b
    return r"C:\Program Files\Git\bin\bash.exe"


def script(name):
    path = os.path.join(ROOT, "tools", name)
    return [bash(), path] if WIN else [path]


def ps(command, **kw):
    return run(["powershell.exe", "-NoProfile", "-Command", command], **kw)


BUILD = os.environ.get("SWEEP_BUILD", "build")  # "buildv" = the vanilla test variant (tools/buildv.sh)
PREFIX = os.path.expanduser("~/.wine-dr")


def game(disp, ch, args, log):
    env = dict(os.environ, WINEPREFIX=PREFIX, MP_PIDFILE=log[:-4] + ".pid")
    return subprocess.Popen(script("run_game.sh") + [str(disp), os.path.join(ROOT, BUILD, "game"), str(ch)] + args,
                            stdout=open(log, "w"), stderr=subprocess.STDOUT, env=env)


def shot(log, disp, png):
    if not WIN:
        run(["scrot", "-o", png], env=dict(os.environ, DISPLAY=f":{disp}"))
        return
    try:
        pid = open(log[:-4] + ".pid").read().strip()
    except OSError:
        return
    if pid:
        run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", os.path.join(ROOT, "tools", "winwindow.ps1"),
             "shot", pid, png, "-Slot", str(disp - 91)], capture_output=True)


def tail(path, n=8192):
    """The last n bytes of a log ('' while it doesn't exist)."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - n))
            return f.read().decode("utf-8", "ignore")
    except OSError:
        return ""


def host_frame(path):
    """The frame number of the newest self-check line (-mptest check) in a log, 0 before the first."""
    for line in reversed(tail(path).splitlines()):
        if "[MPCHK] t=" in line:
            m = re.search(r" f=(\d+)", line)
            if m:
                return int(m.group(1))
    return 0


def wait_for(cond, limit):
    end = time.time() + limit
    while time.time() < end and not cond():
        time.sleep(0.2)


def restart_if_hung(proc, start, log, notes):
    """A game that hangs while starting (seen on Windows: the log stops at the graphics setup, before
    any mod code) and hasn't reached its main loop after 15 s is started again."""
    if not WIN:
        return proc
    wait_for(lambda: "Entering main loop" in tail(log, 1 << 16), 15)
    if "Entering main loop" not in tail(log, 1 << 16):
        notes.append(os.path.basename(log)[:-4] + " hung while starting, restarted")
        try:
            os.kill(int(open(log[:-4] + ".pid").read().strip()), signal.SIGTERM)
        except (OSError, ValueError):
            pass
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
        proc = start()
    return proc


def crashed(paths):
    for p in paths:
        try:
            if "[MPCRASH]" in open(p, errors="ignore").read():
                return True
        except FileNotFoundError:
            pass
    return False


def claim(qdir, pair):
    """Takes the next free ticket of a shared queue (tools/sweepall.sh). A ticket is taken by creating
    its .lock file, which only one pair can do (exclusive create); the ticket itself never moves.
    (Renaming it was not safe on Windows: several pairs got the same one, and then none.)
    Returns its 'chapter kind room plot' fields, or None when every ticket is taken."""
    for n in sorted(os.listdir(qdir)):
        if not n.endswith(".todo"):
            continue
        src = os.path.join(qdir, n)
        try:
            fd = os.open(src[:-5] + ".lock", os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            continue  # someone else's
        os.write(fd, str(pair).encode())
        os.close(fd)
        return open(src).read().split()
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("chapter", type=int, nargs="?", default=0)
    ap.add_argument("--secs", type=int, default=45)
    ap.add_argument("--from", dest="start", type=int, default=0)
    ap.add_argument("--limit", type=int, default=100000)
    ap.add_argument("--only", default="")
    ap.add_argument("--solo", action="store_true")
    ap.add_argument("--scenfile", default="", help="scenario list (default work/sweep/scen_chN.txt)")
    ap.add_argument("--clients", type=int, default=1, help="number of clients (each pair uses clients+1 displays)")
    ap.add_argument("--keep", action="store_true", help="keep logs of passing scenarios too")
    ap.add_argument("--battles", action="store_true", help="scenarios are 'enc <N>': fight encounter N")
    ap.add_argument("--tag", default="")
    ap.add_argument("--pair", type=int, default=0, help="run several sweeps at once: 0, 1, ... (own displays/port)")
    ap.add_argument("--speed", type=int, default=int(os.environ.get("MP_SPEED", "20")), help="game speed (test token speed:N)")
    ap.add_argument("--queue", default="", help="take scenarios from this shared queue folder (tools/sweepall.sh) instead")
    ap.add_argument("--battle-secs", type=int, default=120, help="with --queue: game time of a battle scenario")
    a = ap.parse_args()
    # (fastboot: the title screen before the scenario's setup runs fast too.)
    spd = f",speed:{a.speed},fastboot,players:{a.clients + 1}" if a.speed > 1 and not a.solo else ""

    # The scenarios: (chapter, battles?, room or "enc", plot or encounter, results folder).
    if a.queue:
        jobs = None
        total = "?"
    else:
        ch = a.chapter
        sf = a.scenfile or os.path.join(ROOT, f"work/sweep/scen_ch{ch}.txt")
        scen = [l.split()[:2] for l in open(sf) if l.strip()]
        if a.only:
            r, _, p = a.only.partition(":")
            scen = [s for s in scen if s[0] == r and (not p or s[1] == p)] or [[r, p or "0"]]
        scen = scen[a.start:a.start + a.limit]
        base = os.path.join(ROOT, f"work/sweep/ch{ch}{a.tag}")
        jobs = iter([(ch, a.battles, rm, plot, base) for rm, plot in scen])
        total = len(scen)
        run(script("mkgamedir.sh") + [os.path.join(ROOT, BUILD, "game"), str(ch), os.path.join(ROOT, BUILD, f"ch{ch}.win")], check=True)

    def next_job():
        if jobs is not None:
            return next(jobs, None)
        t = claim(a.queue, a.pair)
        if t is None:
            return None
        ch, kind, rm, plot = int(t[0]), t[1], t[2], t[3]
        return (ch, kind == "battles", rm, plot, os.path.join(ROOT, f"work/sweep/ch{ch}_{kind}_p{a.pair}"))

    global PREFIX
    # Each pair has its own Wine prefix (and so its own wineserver), restarted between
    # scenarios: killed games leak sockets and handles into the wineserver, which slows
    # every later game down. (~/.wine-dr-pN: `cp -al ~/.wine-dr`, with its own save folder.)
    if a.pair:
        PREFIX = os.path.expanduser(f"~/.wine-dr-p{a.pair}")
    d0 = 91 + (a.clients + 1) * a.pair

    def kill_pattern():
        # Only this pair's games (their command lines name a port in this pair's range).
        if WIN:
            ps(r"""Get-CimInstance Win32_Process -Filter "Name='DELTARUNE.exe'" | Where-Object { $_.CommandLine -match '-mp(port|join) \S*?:?%d\d\d\d(\s|$)' } """
               "| ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" % (27 + a.pair), capture_output=True)
            return
        pat = f"DELTARUNE.exe .*-mp(port|join) [^ ]*:?{27 + a.pair}[0-9][0-9][0-9]( |$)"
        run(["pkill", "-f", pat])
        run(["wineserver", "-k"], env=dict(os.environ, WINEPREFIX=PREFIX))
        # Wait until they're really gone (and the UDP port is free again).
        for _ in range(40):
            if run(["pgrep", "-f", pat], capture_output=True).returncode != 0:
                break
            time.sleep(0.5)
        else:
            run(["pkill", "-9", "-f", pat])
            time.sleep(2)

    def kill_mine(procs, logs):
        if not WIN:
            kill_pattern()
            return
        # Windows: the games' own process ids (run_game.sh writes them), no process search.
        for l in logs:
            try:
                os.kill(int(open(l[:-4] + ".pid").read().strip()), signal.SIGTERM)  # TerminateProcess
            except (OSError, ValueError):
                pass
        for pr in procs:
            try:
                pr.wait(timeout=10)
            except subprocess.TimeoutExpired:
                pr.kill()

    def check(out):
        r = run([sys.executable, os.path.join(ROOT, "tools/mpcheck.py"), out, "--strict-end"], capture_output=True, text=True)
        lines = r.stdout.splitlines()
        bad = [l.strip() for l in lines if l.startswith("FAIL")]
        status = "CRASH" if any("crash" in l for l in bad) else ("FAIL" if r.returncode else "PASS")
        # first problem line under each failing check
        detail = " ; ".join(bad)
        for j, l in enumerate(lines):
            if l.startswith("FAIL") and j + 1 < len(lines) and lines[j + 1].startswith("       "):
                detail += " || " + lines[j + 1].strip()[:250]
        return status, detail, r.stdout

    kill_pattern()  # leftovers of an earlier run of this pair
    i = -1
    while True:
        job = next_job()
        if job is None:
            break
        i += 1
        ch, battles, rm, plot, base = job
        secs = a.battle_secs if (a.queue and battles) else a.secs
        os.makedirs(base, exist_ok=True)
        # A fresh port per scenario: Wine can keep a killed game's socket open for a while.
        port = str(27000 + a.pair * 1000 + (i + a.start) % 1000)
        out = os.path.join(base, f"{rm}_{plot}")
        # (Windows: a log the stopped game just closed can stay locked for a moment.)
        for _ in range(20):
            shutil.rmtree(out, ignore_errors=True)
            if not os.path.exists(out):
                break
            time.sleep(0.25)
        os.makedirs(out, exist_ok=True)
        if not WIN:
            kill_pattern()
            time.sleep(1)
        host_t = f"party,room:{rm},plot:{plot},check,mash,wander,log"
        # Light World rooms start in the Light World (Kris and Susie), like the real game.
        lw_ch1 = ("room_krisroom", "room_alphysclass", "room_insidecloset", "room_schooldoor", "room_torhouse")
        lw_other = ("room_lw_", "room_town", "room_krisroom", "room_torhouse", "room_schooldoor", "room_library", "room_alphysclass", "room_diner", "room_torbathroom", "room_kris")
        if rm.startswith(lw_ch1 if ch == 1 else lw_other):
            host_t += ",lightworld"
        client_t = f"party,room:{START[ch]},plot:{plot},check,mash,wander,log"
        host_t += spd
        client_t += spd
        if battles:
            # Both in the same room; the host starts the encounter, bots fight (tough enemies).
            room0, p0 = BATTLE_ROOM[ch]
            host_t = f"party,room:{room0},plot:{p0},battle:{plot},bot,botrand,log,tough,check"
            client_t = f"party,room:{room0},plot:{p0},bot,botrand,log,tough,check" + os.environ.get("SWEEP_CLIENT_EXTRA", "") + spd
            host_t += spd
        logs = [os.path.join(out, "host.log")]
        procs = []
        notes = []
        t0 = time.time()
        if a.solo:
            starts = [lambda: game(d0, ch, ["-mpport", port, "-mptest", host_t], logs[0])]
        else:
            # Host and clients start together: a client connects only after its own setup (a second
            # after the host's, which has nothing more to load), and tries again every 2 s anyway.
            starts = [lambda: game(d0, ch, ["-mpport", port, "-mphost", "-mpname", "Host", "-mpchar", "1", "-mptest", host_t], logs[0])]
            for k in range(1, a.clients + 1):
                logs.append(os.path.join(out, f"client{k}.log"))
                starts.append(lambda k=k: game(d0 + k, ch, ["-mpjoin", "127.0.0.1:" + port, "-mpname", f"P{k + 1}", "-mpchar", str(k + 1),
                                                           "-mptest", client_t], logs[k]))
        procs = [s() for s in starts]
        for k in range(len(procs)):
            procs[k] = restart_if_hung(procs[k], starts[k], logs[k], notes)
        t_host = time.time()
        # The scenario lasts `secs` of game time (counted in the host's frames, 30 a second) from the
        # moment everyone has joined, however fast the games really run. A game that stops
        # (freeze, crash) ends it after a real-time limit.
        if not a.solo:
            wait_for(lambda: all("Joined the session" in tail(l, 1 << 16) for l in logs[1:]) or crashed(logs), 40)
        t_join = time.time()
        f0 = host_frame(logs[0])
        wait_for(lambda: host_frame(logs[0]) >= f0 + secs * 30 or crashed(logs), 20 + secs * 1.5)
        t_play = time.time()
        if crashed(logs):
            time.sleep(0.5)  # (let the crash report reach the log)
        if a.solo:
            status = "CRASH" if crashed(logs) else "PASS"
        else:
            status = check(out)[0]
        # Screenshots only of what failed (passing scenarios' folders are deleted anyway).
        if status != "PASS" or a.keep:
            for k, l in enumerate(logs):
                shot(l, d0 + k, os.path.join(out, f"end_{k}.png"))
        t_check = time.time()
        kill_mine(procs, logs)
        t_kill = time.time()
        if a.solo:
            detail = ""
            if crashed(logs):
                for line in open(logs[0], errors="ignore"):
                    if "[MPCRASH]" in line:
                        detail = line.split("[MPCRASH]", 1)[1].strip()[:300]
        else:
            status, detail, text = check(out)
            open(os.path.join(out, "check.txt"), "w").write(text)
        line = f"{rm} {plot} {status} {detail}" + (" [" + "; ".join(notes) + "]" if notes else "")
        # Where the time went: starting the games, joining, play, check (+ screenshots), stop, final check.
        tm = f"start {t_host - t0:.1f} join {t_join - t_host:.1f} play {t_play - t_join:.1f} check {t_check - t_play:.1f} stop {t_kill - t_check:.1f} end {time.time() - t_kill:.1f}"
        print(f"[{i + 1}/{total}] (ch{ch} {time.time() - t0:.0f}s: {tm}) {line}", flush=True)
        with open(os.path.join(base, "results.txt"), "a") as results:
            results.write(line + "\n")
        if status == "PASS" and not a.keep:
            shutil.rmtree(out, ignore_errors=True)
    kill_pattern()


if __name__ == "__main__":
    main()
