#!/bin/bash
# The whole sweep: every story scenario (work/sweep/scen_chN.txt, tools/sweepgen.py) and every
# encounter (work/sweep/enc_chN.txt) of the chapters, split between several pairs of games that
# run at the same time (each pair: its own ports and window slots, see tools/sweep.py --pair).
# Usage: sweepall.sh [pairs=4] [chapters...]
#   SAMPLE=n   only the first n scenarios of each chapter's lists (a quick check)
#   MP_SPEED=n game speed (default 20)
#   KINDS="story battles"   what to run
# Results: work/sweep/ch<N>_<kind>_p<k>/results.txt; the summary is printed at the end and
# written to work/sweep/summary.txt. One CPU core per game is about right (pairs = cores / 2 - 1).
. "$(dirname "$0")/platform.sh"
P=${1:-4}; shift; CHS=${@:-1 2 3 4 5}
KINDS=${KINDS:-story battles}
SW=$ROOT/work/sweep
for c in $CHS; do
  "$ROOT/tools/mkgamedir.sh" "$ROOT/build/game" $c "$ROOT/build/ch$c.win"
  for kind in $KINDS; do rm -rf "$SW"/ch${c}_${kind}_p*; done
done

# One shared queue of tickets (work/sweep/queue/*.todo, one per scenario): each pair takes the next
# free one when it is done (tools/sweep.py --queue), so none of them sits idle while others still
# have a long share left. Battles (longer) go first, so the run doesn't end with one alone.
Q=$SW/queue
rm -rf "$Q"; mkdir -p "$Q"
for kind in $KINDS; do
  [ $kind = battles ] && o=0 || o=1
  for c in $CHS; do
    if [ $kind = story ]; then f=$SW/scen_ch$c.txt; else f=$SW/enc_ch$c.txt; fi
    [ -f "$f" ] || { echo "missing $f"; continue; }
    grep . "$f" | head -n ${SAMPLE:-100000} | awk -v c=$c -v k=$kind -v o=$o -v q="$Q" \
      '{ t = sprintf("%s/%d_ch%d_%s_%05d.todo", q, o, c, k, NR); printf "%d %s %s %s\n", c, k, $1, $2 > t; close(t) }'
  done
done
echo "$(ls "$Q" | wc -l) scenarios queued for $P pairs"

# The game windows are tiled in a grid with a place for each of them (tools/winwindow.ps1).
export MP_SLOTS=${MP_SLOTS:-$((P * 2))}
# ... and kept on top of the other windows, to watch them (MP_WATCH=0: behind, as in the other tests).
export MP_WATCH=${MP_WATCH:-1}
# One window watcher for the whole run instead of one per game (MP_NOPLACE: none of it).
if [ -n "$MP_WIN" ] && [ -z "$MP_NOPLACE" ]; then
  export MP_WATCH_STOP=$(cygpath -w "$SW/watcher.stop"); rm -f "$SW/watcher.stop"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$ROOT/tools/winwindow.ps1")" watch 0 "$(cygpath -w "$ROOT/build/game")" >/dev/null 2>&1 &
  WATCHER=$!
  trap 'touch "$SW/watcher.stop"' EXIT
fi
export MP_NOPLACE=1
rm -f "$SW"/worker*.txt
T0=$(date +%s)
for k in $(seq 0 $((P - 1))); do
  $PY "$(mp_path "$ROOT/tools/sweep.py")" --pair $k --queue "$(mp_path "$Q")" --battle-secs 120 > "$SW/worker$k.txt" 2>&1 &
done
wait
T1=$(date +%s)
# What crashed is played again alone (one game, not connected). If it crashes then too, the crash
# is the game's own (encounter numbers left in scr_encountersetup that need enemies the chapter
# doesn't have, rooms entered at a story point they can't be reached at), not multiplayer.
for c in $CHS; do
  for kind in $KINDS; do
    rm -rf "$SW/ch${c}_${kind}_solo"
    cat "$SW"/ch${c}_${kind}_p*/results.txt 2>/dev/null | awk '$3 == "CRASH" { print $1, $2 }' > "$SW/crash_${kind}_ch$c.txt"
    [ -s "$SW/crash_${kind}_ch$c.txt" ] || continue
    extra=""; [ $kind = battles ] && extra="--battles"
    $PY "$(mp_path "$ROOT/tools/sweep.py")" $c --solo $extra --secs 20 --scenfile "$(mp_path "$SW/crash_${kind}_ch$c.txt")" --tag _${kind}_solo >> "$SW/worker0.txt" 2>&1
  done
done
{
  N=$(for c in $CHS; do for kind in $KINDS; do cat "$SW"/ch${c}_${kind}_p*/results.txt 2>/dev/null; done; done | grep -c .)
  echo "sweep: $P pairs at ${MP_SPEED:-20}x, chapters $CHS: $N scenarios in $((T1 - T0)) s ($(awk -v n=$N -v t=$((T1 - T0)) 'BEGIN { printf "%.1f", n * 60 / (t > 0 ? t : 1) }') a minute), $(( ($(date +%s) - T0) / 60 )) min with the crash re-checks"
  for c in $CHS; do
    for kind in $KINDS; do
      r=$(cat "$SW"/ch${c}_${kind}_p*/results.txt 2>/dev/null)
      [ -z "$r" ] && continue
      solo=$(awk '$3 == "CRASH" { print $1, $2 }' "$SW/ch${c}_${kind}_solo/results.txt" 2>/dev/null)
      own=0
      [ -n "$solo" ] && own=$(echo "$r" | awk '$3 == "CRASH" { print $1, $2 }' | grep -cxF "$solo")
      echo "chapter $c $kind: $(echo "$r" | awk '$3 == "PASS"' | grep -c .) pass, $(echo "$r" | awk '$3 == "FAIL"' | grep -c .) fail, $(( $(echo "$r" | awk '$3 == "CRASH"' | grep -c .) - own )) crash, $own game's own crash (also alone)"
      echo "$r" | grep -v ' PASS' | while read -r a b rest; do
        if [ -n "$solo" ] && echo "$solo" | grep -qxF "$a $b"; then continue; fi
        echo "    $a $b $rest" | cut -c1-300
      done
      if [ "$own" -gt 0 ]; then echo "    game's own: $(echo "$solo" | awk '{ printf "%s:%s ", $1, $2 }')"; fi
    done
  done
} | tee "$SW/summary.txt"
