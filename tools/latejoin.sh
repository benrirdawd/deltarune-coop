#!/bin/bash
# Joining in the middle of a cutscene, one scenario per chapter: the host's story cutscene starts while
# it's alone; the client connects late (connectat:) and must be pulled into it and watch it with the
# host (not start the room's scene again in its own game). ch2crash: the client's game is killed
# mid-scene and started again (CRASH_AT); it must join the host's scene again.
# XT=<tokens>: added to both sides of every scenario (XT=chaos:10:120:60 for a bad network).
# ch1crash..ch5crash: the same for each chapter (always with the bad-network tokens).
# Usage: tools/latejoin.sh ch1 ch2 ch2c ch2crash ch3 ch4 ch5 ch1crash ch3crash ch4crash ch5crash   (CH=<tokens>: the bad-network tokens of ch2c)
cd "$(dirname "$0")/.."
run() { local n=$1 ch=$2 ht=$3${XT:+,$XT} ct=$4${XT:+,$XT}; OUT=work/t_late_$n${XT:+_x}
  DRM_SAVE_NAME=DELTARUNE_MP_TEST MP_SPEED=20 MPTEST_OUT=$PWD/$OUT NOBUILD=1 MPCHARS="2" timeout 500 tools/mptest.sh $ch ${SECS:-900} "$ht" "$ct" 1 >/dev/null 2>&1
  echo "=== $n"; [ -n "$CRASH_AT" ] && echo "  (client restarted after $CRASH_AT s)"; grep -ah "sharing it\|Watching\|got pull\|mirror: start\|scene lock: held" $OUT/*.log | cut -c20-140 | head -6
  python tools/mpcheck.py $OUT --strict-end | grep -v "^PASS" | head -8; }
C=${CH:-chaos:10:120:60}
for s in "$@"; do case $s in
 ch2c) run ch2c 2 "party,room:room_dw_cyber_queen_boxing,plot:53,check,log,partyat:400,mash,mashfrom:700,$C" "party,room:room_dw_cyber_intro_2,plot:53,check,log,connectat:600,mash,mashfrom:700,$C";;
 ch2) run ch2 2 "party,room:room_dw_cyber_queen_boxing,plot:53,check,log,partyat:400,mash,mashfrom:700" "party,room:room_dw_cyber_intro_2,plot:53,check,log,connectat:600,mash,mashfrom:700";;
 ch2crash) SECS=1610 CRASH_AT=24 run ch2crash 2 "party,room:room_dw_cyber_queen_boxing,plot:53,check,log,partyat:400,mash,mashfrom:30000,$C" "party,room:room_dw_cyber_intro_2,plot:53,check,log,$C";;
 ch1crash) SECS=1610 CRASH_AT=24 run ch1crash 1 "party,room:room_alphysclass,plot:2,lightworld,check,log,setcon:obj_classscene:20:100,mash,mashfrom:30000,$C" "party,room:room_torhouse,plot:2,lightworld,check,log,$C";;
 ch3crash) SECS=1610 CRASH_AT=24 run ch3crash 3 "party,room:room_dw_snow_zone,plot:250,check,log,partyat:400,walk:r:30:400,mash,mashfrom:30000,$C" "party,room:room_dw_couch_overworld_01,plot:250,check,log,$C";;
 ch4crash) SECS=1610 CRASH_AT=24 run ch4crash 4 "party,room:room_dw_church_glass,plot:110,check,log,partyat:400,mash,mashfrom:30000,$C" "party,room:room_dw_church_bookcase,plot:110,check,log,$C";;
 ch5crash) SECS=1610 CRASH_AT=24 run ch5crash 5 "party,room:room_dw_garden_intro,plot:100,check,log,partyat:400,mash,mashfrom:30000,$C" "party,room:room_dw_garden_meetflowery,plot:100,check,log,$C";;
 ch1) run ch1 1 "party,room:room_alphysclass,plot:2,lightworld,check,log,setcon:obj_classscene:20:100,mash,mashfrom:700" "party,room:room_torhouse,plot:2,lightworld,check,log,connectat:600,mash,mashfrom:700";;
 ch3) run ch3 3 "party,room:room_dw_snow_zone,plot:250,check,log,partyat:400,walk:r:30:400,mash,mashfrom:900" "party,room:room_dw_couch_overworld_01,plot:250,check,log,connectat:700,mash,mashfrom:900";;
 ch4) run ch4 4 "party,room:room_dw_church_glass,plot:110,check,log,partyat:400,mash,mashfrom:700" "party,room:room_dw_church_bookcase,plot:110,check,log,connectat:600,mash,mashfrom:700";;
 ch5) run ch5 5 "party,room:room_dw_garden_intro,plot:100,check,log,partyat:400,mash,mashfrom:700" "party,room:room_dw_garden_meetflowery,plot:100,check,log,connectat:600,mash,mashfrom:700";;
esac; done
