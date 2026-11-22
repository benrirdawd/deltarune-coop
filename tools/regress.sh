#!/bin/bash
# Runs a synchronized-battle test in every chapter and reports whether all players'
# per-turn battle state matched.  Usage: regress.sh [seconds] [nclients] [chapters...]
# (Linux with Wine + Xvfb, or Git Bash on Windows with the native game; see tools/platform.sh.)
. "$(dirname "$0")/platform.sh"
# Games run 20x faster once connected (test token speed:20); MP_SPEED=1 for normal speed.
export MP_SPEED=${MP_SPEED:-20}
SECS=${1:-100}; NC=${2:-1}; shift 2; CHS=${@:-1 2 3 4 5}
declare -A ROOM=([1]=room_field1 [2]=room_dw_cyber_maze_virokun [3]=room_dw_couch_overworld_02 [4]=room_dw_church_worshiproom [5]=room_dw_garden_intro)
declare -A ENC=([1]=13 [2]=53 [3]=110 [4]=150 [5]=200)
# (fastboot: the title screen before the party setup runs fast too)
FB=""; [ "$MP_SPEED" != 1 ] && FB=",fastboot"
for c in $CHS; do
  OUT=$ROOT/work/reg$c
  MPTEST_OUT=$OUT NOBUILD=1 "$ROOT/tools/mptest.sh" $c $SECS "party,room:${ROOM[$c]},plot:100,battle:${ENC[$c]},bot,botrand,log,tough$FB" "party,room:${ROOM[$c]},plot:100,bot,botrand,log,tough$FB" $NC >/dev/null 2>&1
  $PY - "$(mp_path "$OUT")" $NC $c <<'PY'
import sys,glob
out,nc,c=sys.argv[1],int(sys.argv[2]),sys.argv[3]
logs=[out+'/host.log']+[f'{out}/client{i}.log' for i in range(1,nc+1)]
turns=[]
for l in logs:
    d={}
    try: f=open(l,errors='ignore')
    except OSError: f=[]
    for line in f:
        if line.startswith('@'): line=line.split(' ',1)[1]
        if line.startswith('[MPLOG]'): d[line.split()[1]]=line.strip()
    turns.append(d)
common=set(turns[0]).intersection(*turns[1:])
same=bool(common) and all(len({t[k] for t in turns})==1 for k in common)
print(f"chapter {c}: turns per player {[len(t) for t in turns]}, shared {len(common)}, identical={same}")
PY
done
mp_killall "$ROOT/build/game"
