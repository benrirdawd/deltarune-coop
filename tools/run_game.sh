#!/bin/bash
# Usage: run_game.sh <display_num> <game_dir> <chapter> [extra args...]
# Linux: starts an Xvfb display (if not running) and launches a chapter under Wine.
# Windows (Git Bash): launches the native game; the display number (91, 92, ...) picks where
# its window is tiled on the desktop (tools/winwindow.ps1). MP_PIDFILE=<file> receives the
# game's Windows process id (used for screenshots).
DISP=$1; GAMEDIR=$2; CH=$3; shift 3
. "$(dirname "$0")/platform.sh"
# Every output line gets a wall-clock timestamp prefix ("@<unix time> "), used by
# tools/mpcheck.py to line up what different players saw at the same moment.
TS='
import sys, time
for line in sys.stdin:
    sys.stdout.write("@%.3f %s" % (time.time(), line))
'
if [ -n "$MP_WIN" ]; then
  # The native game writes its debug output to stdout when it is redirected.
  cd "$GAMEDIR/chapter${CH}_windows" || exit 1
  exec > >(exec $PY -u -c "$TS") 2>&1
  ../DELTARUNE.exe -game data.win "$@" &
  GP=$!
  # $! can be a stand-in process with the game as its child: the game's own Windows process id
  # is the child's (if there is one), so that stopping it and moving its window reach the game.
  WP=""
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    for d in /proc/[0-9]*; do
      [ "$(cat "$d/ppid" 2>/dev/null)" = "$GP" ] && WP=$(cat "$d/winpid" 2>/dev/null) && break
    done
    [ -n "$WP" ] && break
    [[ "$(cat /proc/$GP/exename 2>/dev/null)" == *DELTARUNE* ]] && break
    sleep 0.1
  done
  [ -z "$WP" ] && WP=$(cat /proc/$GP/winpid 2>/dev/null)
  [ -n "$MP_PIDFILE" ] && echo "$WP" > "$MP_PIDFILE"
  [ -n "$WP" ] && [ -z "$MP_NOPLACE" ] && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$ROOT/tools/winwindow.ps1")" place "$WP" $((DISP - 91)) >/dev/null 2>&1 &
  wait $GP
  exit
fi
# Three CPU cores per game (Wine's software rendering would otherwise use ~4-5 each).
N=$(nproc); C0=$(( (DISP - 91) * 3 % N )); CORES=${MP_CORES:-$C0,$(( (C0 + 1) % N )),$(( (C0 + 2) % N ))}
export WINEDEBUG=-all WINEPREFIX=${WINEPREFIX:-$HOME/.wine-dr} DISPLAY=:$DISP
if ! xdpyinfo -display :$DISP >/dev/null 2>&1; then
  Xvfb :$DISP -screen 0 800x600x24 -nolisten tcp >/dev/null 2>&1 &
  sleep 1
fi
cd "$GAMEDIR/chapter${CH}_windows" && nice -n 15 taskset -c $CORES wine ../DELTARUNE.exe -game data.win "$@" 2>&1 | $PY -u -c "$TS"
