#!/bin/bash
# Usage: mptest.sh <chapter> <seconds> "<host test tokens>" "<client test tokens>" [nclients]
# Builds the patched chapter, launches a host (display :91) and clients (:92, :93...)
# with automated test flags, waits, then screenshots every instance.
# Linux: Wine on Xvfb displays. Windows (Git Bash): native game windows tiled on the desktop.
set -e
. "$(dirname "$0")/platform.sh"
CH=$1; SECS=$2; HT=$3; CT=$4; NC=${5:-1}
OUT=${MPTEST_OUT:-$ROOT/work/test}
# MP_SPEED=n runs the games n times faster (test token speed:n). <seconds> and SHOTS stay in game
# time at normal speed: the first 10 s (starting the games, joining) are real time, the rest is
# divided by n.
SPEED=${MP_SPEED:-1}
if [ "$SPEED" != 1 ]; then
  # (players: speed up once everyone is in, not when the first one joins)
  [[ ",$HT," == *",speed:"* ]] || HT="$HT,speed:$SPEED,players:$((NC + 1))"
  [[ ",$CT," == *",speed:"* ]] || CT="$CT,speed:$SPEED,players:$((NC + 1))"
fi
gtime() { awk -v t="$1" -v s="$SPEED" 'BEGIN { r = t <= 10 ? t : 10 + (t - 10) / s; print (r == int(r)) ? r : int(r) + 1 }'; }
SECS=$(gtime "$SECS"); SH=""; for t in ${SHOTS:-}; do SH="$SH $(gtime $t)"; done; SHOTS=$SH
mkdir -p "$OUT" "$ROOT/build"; rm -f "$OUT"/*.log "$OUT"/*.png "$OUT"/*.pid "$OUT"/restarts.txt
rm -f "$SAVEDIR/multiplayer.ini"
if [ -z "$NOBUILD" ]; then
  "$PATCHER" "$DR/chapter${CH}_windows/data.win" "$ROOT/build/ch$CH.win" "$ROOT/mod" "$CH" | tail -2
fi
"$ROOT/tools/mkgamedir.sh" "$ROOT/build/game" "$CH" "$ROOT/build/ch$CH.win"
mp_killall "$ROOT/build/game"; sleep 1
export MP_SLOTS=${MP_SLOTS:-$((NC + 1))}   # (Windows: one place per game in the window grid)

# shot <instance name> <display> <png>
shot() {
  if [ -n "$MP_WIN" ]; then
    local p; p=$(cat "$OUT/$1.pid" 2>/dev/null)
    [ -n "$p" ] && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$ROOT/tools/winwindow.ps1")" shot "$p" "$(cygpath -w "$3")" -Slot $(($2 - 91)) >/dev/null 2>&1
  else
    DISPLAY=:$2 scrot -o "$3"
  fi
  return 0
}

start_host() {
  MP_PIDFILE=$OUT/host.pid "$ROOT/tools/run_game.sh" 91 "$ROOT/build/game" "$CH" -mphost -mpname Host -mpchar 1 -mptest "$HT" > "$OUT/host.log" 2>&1 &
}
start_client() {
  MP_PIDFILE=$OUT/client$1.pid "$ROOT/tools/run_game.sh" $((91+$1)) "$ROOT/build/game" "$CH" -mpjoin 127.0.0.1 -mpname P$(($1+1)) -mpchar $(echo ${MPCHARS:-2 3 4 1 2 3 4} | cut -d" " -f$1) -mptest "$CT" > "$OUT/client$1.log" 2>&1 &
}
# A game sometimes hangs while it starts (seen on Windows: the log stops at the graphics setup, before
# any mod code). One that hasn't reached its main loop after 15 s is stopped and started again
# (written to restarts.txt).
started() { grep -q "Entering main loop" "$OUT/$1.log" 2>/dev/null; }
retry_hung() {  # <name> <start command...>
  local n=$1; shift
  [ -n "$MP_WIN" ] || return 0
  for _ in $(seq 1 75); do started $n && return; sleep 0.2; done
  echo "$(date +%T) $n hung while starting: $(tail -1 "$OUT/$n.log" | cut -c1-80)" >> "$OUT/restarts.txt"
  mp_kill_pid "$(cat "$OUT/$n.pid" 2>/dev/null)"
  "$@"
}
start_host
retry_hung host start_host
sleep 4
for i in $(seq 1 $NC); do start_client $i; done
for i in $(seq 1 $NC); do retry_hung client$i start_client $i; done
# CRASH_AT=<s>: client 1's game is killed <s> real seconds after the clients started (like a crash)
# and started again at once (it joins again; its log goes on in client1.log after a "restarted" line).
T=0
if [ -n "$CRASH_AT" ]; then
  sleep "$CRASH_AT"; T=$CRASH_AT
  mp_kill_pid "$(cat "$OUT/client1.pid" 2>/dev/null)"; sleep 1
  cp "$OUT/client1.log" "$OUT/client1_before_crash.log"
  start_client 1; retry_hung client1 start_client 1
fi
# Optional series of side-by-side screenshots: SHOTS="10 15 20" (seconds after start)
for t in ${SHOTS:-}; do
  sleep $((t - T)); T=$t
  shot host 91 "$OUT/h_$t.png"
  for i in $(seq 1 $NC); do shot client$i $((91+i)) "$OUT/c${i}_$t.png"; done
  $PY -c "
from PIL import Image
import os
fs=[f for f in ['$OUT/h_$t.png']+['$OUT/c%d_$t.png'%i for i in range(1,$NC+1)] if os.path.exists(f)]
im=Image.new('RGB',(640*max(1,len(fs)),480))
for k,f in enumerate(fs):
    s=Image.open(f).convert('RGB')
    # Xvfb: the 640x480 game in an 800x600 screen. Windows: the whole game window.
    s=s.crop((80,60,720,540)) if s.size==(800,600) else s.resize((640,480))
    im.paste(s,(640*k,0))
im.save('$OUT/all_$t.png')" 2>/dev/null || true
done
sleep $((SECS > T ? SECS - T : 0))
shot host 91 "$OUT/host.png"
for i in $(seq 1 $NC); do shot client$i $((91+i)) "$OUT/client$i.png"; done
# Don't leave the games running (each one uses several CPU cores); KEEP=1 to keep them.
[ -z "$KEEP" ] && mp_killall "$ROOT/build/game"
echo "screens in $OUT"
