# Contributing to DELTARUNE Online

Thanks for helping. This page is for people who want to change the code: how to build it, how to test
a change, and where each thing lives. Players reporting a bug only need the last section.

Talk to the maintainer on Discord (**b.001**), on the coop-anything server, or open an issue or pull
request on [benrirdawd/deltarune-coop](https://github.com/benrirdawd/deltarune-coop). Open work is in
[`TODO.md`](TODO.md) (sizes S/M/L); finished work, and how it was tested, is in [`DONE.md`](DONE.md).
Pick anything from TODO.md; say on Discord what you're taking so two people don't do the same thing.

## How it works, in one paragraph

DELTARUNE is a GameMaker game: each chapter is a `data.win` file with all its code (GML), sprites and
rooms. The mod is plain GML (`mod/gml/`) plus small edits to the game's own code (`mod/hooks/core.hook`).
`drm-patcher` (`patcher/`, built on UndertaleModLib) compiles both into a copy of a chapter's `data.win`.
Every player runs the whole game; the mod keeps the games in step over its own reliable UDP layer (or
Steam's relays): positions, story state, cutscenes (one player's game plays it, the others mirror what
it draws) and battles (every game runs the battle, button presses are replayed). The host is the hub
and forwards messages to everyone. README.md, "How it works", has a table with each part.

## What you need

* DELTARUNE (Steam) on the PC. Never commit or upload any of its files.
* Windows with Git Bash (Linux with Wine + Xvfb works too; `tools/platform.sh` holds the differences).
* .NET 10 SDK (for the patcher) and an
  [UndertaleModTool](https://github.com/UnderminersTeam/UndertaleModTool) checkout cloned with
  `--recursive` (last checked with commit `fbd4e79b`, 2026-11-21). The launcher also builds with it.
* Python 3 for the test tools (`pip install pillow` only for side-by-side screenshots).
* Optional: Zig, only to rebuild the Steam extension `mod/dll/drm_steam.dll` (`tools/buildsteam.sh`).
* Windows: Developer Mode on (the test game folder `build/game` is made of symlinks).

## Building

```
# once, and after changing patcher/*.cs
dotnet build patcher/DRMPatcher.csproj -c Release -p:UTMTRoot=<UndertaleModTool> -o patcher/bin/out

# after every change to mod/: patches all five chapters into build/ch1.win .. build/ch5.win
DELTARUNE_DIR=/d/Games/DELTARUNE tools/build.sh > work/build_out.txt 2>&1
grep -c FAILED work/build_out.txt          # must print 0; details in build/chN.log

# the launcher (DELTARUNE Online.exe)
dotnet build launcher/Launcher.csproj -c Release
```

The game folder comes from `DELTARUNE_DIR`, else `./DELTARUNE` (a link), else Steam's. `tools/build.sh 2 3`
builds only those chapters. The patcher refuses to build when the mod names an object, sprite, sound,
script or room the chapter doesn't have, so a compile error or a missing asset shows up in `build/chN.log`.

To read the game's own code: `drm-patcher --decompile <data.win> <code entry>` (for example
`gml_Object_obj_mainchara_Step_0`), or dump everything once into `work/chN/AllCode/` with
UndertaleModTool and search it. `drm-patcher --find-object <data.win> <object>` lists the rooms an
object is in.

## Testing

The tests start real game windows on this PC that play against each other over 127.0.0.1, driven by
test tokens (`-mptest "<tokens>"`). Always build with **`DRM_SAVE_NAME=DELTARUNE_MP_TEST`** (the
default in the tools): test games then save to `%LOCALAPPDATA%\DELTARUNE_MP_TEST`, never to real saves.
Games run 20 times faster once connected (`MP_SPEED`, default 20; `MP_SPEED=1` to watch at normal speed).

One targeted test, host and one client:

```
MP_SPEED=20 MPTEST_OUT=$PWD/work/fol/mytest NOBUILD=1 DRM_SAVE_NAME=DELTARUNE_MP_TEST SHOTS="" \
  timeout 500 tools/mptest.sh <chapter> <seconds> "<host tokens>" "<client tokens>" 1
python tools/mpcheck.py work/fol/mytest
```

* `<seconds>` is game time at normal speed. `NOBUILD=1` uses what `tools/build.sh` made.
* Each game's log is `work/fol/mytest/host.log`, `client1.log`... (the same lines as a player's
  `multiplayer_log.txt`), with a screenshot at the end.
* `mpcheck.py` reads the `[MPCHK]` lines (token `check`) and reports PASS/FAIL for: char, follower,
  ghost, state, sync, moved, scene, music, world. "moved" fails when nobody walks, which is expected in
  tests that don't walk.
* Common tokens: `party,room:<room>,plot:<n>` (start somewhere with a full party), `check,log`,
  `fastboot`, `mash` (press Z in cutscenes; add `bot` for battles), `walk:<dir>:<frames>:<at>`,
  `battle:<encounter>`, `connectat:<frame>` (join late), `chaos:10:120:60` (bad network: 10% loss,
  120 ms lag, 60 ms jitter; in `scr_mp_net`). The full list is at the top of
  `mod/gml/gml_GlobalScript_scr_mp_test.gml`; add a new token there when a test needs one (with a line
  in that list).
* `CRASH_AT=<s>` kills client 1's game after `<s>` seconds and starts it again (reconnect tests).

Ready-made scenarios: `tools/latejoin.sh ch1 ... ch5crash` (joining mid-cutscene, coming back after a
crash), `tools/cutscenes.sh` (shared cutscenes), `tools/regress.sh` (battles in every chapter, a few
minutes). Please run **only the test that covers your change**, and the same one again with
`chaos:10:120:60` when it touches the network: the long suites take a long time and some scenarios
write saves. Don't add tests that save the game.

Write in `DONE.md` what you changed and how you tested it (command, result, output folder), newest
first, and take the item out of `TODO.md`. Something you couldn't test or finish goes back into
`TODO.md` with the reason.

## Where things are

```
mod/gml/                     the mod's code (one GML file per part; read each file's header first)
  scr_mp_core                init, players, settings, per-frame entry points, message dispatch
  scr_mp_net                 reliable UDP: datagrams, acks, resends, the host as hub, joining
  scr_mp_steam               the same over Steam lobbies and relays (drm_steam.dll)
  scr_mp_world               map: positions, other players' figures (ghosts), character sprites,
                             shared story state (plot, flags, items...), doors, puzzles, Game Over
  scr_mp_sync                cutscenes and pulls: who leads, pulling everyone in, music following
  scr_mp_lock                the host as referee: one shared cutscene at a time
  scr_mp_mirror              watchers see the leader's cutscene (sprites, text boxes, sounds)
  scr_mp_timing              shared clock, ready checks, starting fights at the same moment
  scr_mp_battle              battles: menus driven by each hero's player, attacks, HP, game over
  scr_mp_group               which fight each player is in (several fights at once)
  scr_mp_inv                 money and the bag as changes (two players shopping at once)
  scr_mp_spec                watching another player on the map (F9 Watch)
  scr_mp_voice               proximity voice chat
  scr_mp_climb               Chapters 4-5 climbing walls
  scr_mp_ui                  F9 menu, HUD, notifications, name tags
  scr_mp_test                test tokens and the [MPCHK] self-check lines
  ch3/scr_mp_board           Chapter 3 board game (the top-level file is a stub for other chapters)
  ch5/scr_mp_plat            Chapter 5 platforming (same: stub elsewhere)
  obj_mp_controller_*        the persistent object that calls everything each frame
  obj_mp_ghost_*, obj_mp_mirror_*   other players' figures, the cutscene mirror's drawing
mod/hooks/core.hook          edits to the game's own code (see below)
mod/objects.txt              new objects the patcher creates (persistent, visible, depth)
mod/extensions.txt           DLL functions the patcher declares (drm_steam)
mod/dll/                     drm_steam.dll (built from steam/drm_steam.c) and Valve's steam_api64
patcher/Program.cs           drm-patcher: loads data.win, compiles mod/gml, applies hooks, installs
patcher/MirrorInfo.cs        works out, from each object's Draw event, what the mirror must draw
launcher/                    DELTARUNE Online.exe (WinForms, .NET Framework 4.8): install, update
                             (installer/update.txt lists where it looks), patch, play
installer/                   READ ME FIRST.txt and update.txt shipped in the package
tools/                       build and test scripts (build.sh, mptest.sh, mpcheck.py, latejoin.sh...)
```

### Hooks (`mod/hooks/core.hook`)

```
;; comment                      (at column 0)
#chapters 1,2                   following hooks only for these chapters ("#chapters all" resets)
@prepend <code entry>           the lines until the next directive go before the entry's code
@append <code entry>            ... after it
@replace <code entry>           ... instead of it
@find <code entry>              text to look for, then "@with", the replacement, then "@end"
@regex <code entry>             the same with a regular expression
@find? / @append? ...           optional: no error when the entry or text is missing
```

Keep hook bodies to one call into a `mp_*` function and put the logic in `mod/gml/`. A function
called from a hook can run before the mod is set up (title screen, a chapter with no session), so
start it with `if (!variable_global_exists("mp_inited") || !mp_on()) return;` like the others.
A GML file whose first line is `// @chapters 1,2` is only compiled into those chapters.

### Messages

A message is built with `mp_begin(<type>)`, `mp_wu8` / `mp_wu16` / `mp_ws16` / `mp_wstr` / `mp_wval`...,
then `mp_send()`, and handled in `mp_handle` (`scr_mp_core`, `if (type == N)`; battle messages in
`scr_mp_battle`). Types below 8 are link-level; the host forwards everything from 8 up to the other
players. The next free type is **85** (check with `grep -n "type == 85" mod/gml/*.gml`). Only one
message can be built at a time: don't call anything that sends while you are in the middle of one
(collect what to send and send it after). When you change what an existing message carries, raise
`global.mp_version` (`scr_mp_core`): players on different versions can't join each other.

### GML notes

* The mod's compiler doesn't take the struct accessor `s[$ "key"]`: use arrays, or
  `variable_struct_get` / `variable_struct_set`.
* Game objects differ between chapters; look a name up with `asset_get_index("obj_...")` (it returns
  -1 when the chapter doesn't have it) instead of naming an object another chapter lacks.
* Log with `mp_log("...")` (goes to the log file); `mp_notify("...")` shows a line on screen.

## Code style

* Comments say what the code is for and why, in plain sentences; the files' headers explain each part.
* Small, focused commits; the commit message says what changes for players.
* Credit: this project continues traebon's DELTARUNE Online and uses AeEn123AI's work; it is GPL-3.0,
  and contributions are released under the same license (see `LICENSE`, `THIRD_PARTY.md`).

## Reporting a bug

Say which chapter, where (room or story moment), what happened and what you expected, and attach
the zip that F9 "Save logs for a bug report" puts on your desktop, from every player if you can (it
holds `multiplayer_log.txt`, the session before's `multiplayer_log_prev.txt` and `multiplayer_crash.txt`
from `%LOCALAPPDATA%\DELTARUNE_ONLINE`). Send it on Discord (**b.001**) or in a GitHub issue.
