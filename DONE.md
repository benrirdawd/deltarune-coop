# DELTARUNE Multiplayer — done

What was fixed or built, newest reports first, with how each was tested. These are the notes
that used to be in TODO.md; what is still open is in [`TODO.md`](TODO.md). A row marked "open",
"re-check" or "not done" here is also listed there.

## Code review fixes (local /code-review and the cloud ultrareview), 2026-11-23

| Finding | Fix | Test |
|---|---|---|
| The host's bag sync read `mp_inv_acked[-1]` for a peer still connecting (crash). | Peers without a player number are skipped (`mp_inv_send_state`). | Built; the 3-player buy test below. |
| A client's money change reached the other clients twice: the host's automatic relay of type 8+ messages already forwards type 22, and `mp_inv_forward` sent it again. | `mp_inv_forward` removed. | **Tested** (`buy:1` on two clients, 3 players): every game ends at -100 (before: -150 on the clients). Same with `chaos:10:120:60`. |
| A full snapshot from the host zeroed the clients' money changes it hadn't taken yet. | The host keeps `mp_gold_pending` through `mp_inv_reset` (its gold itself goes out in the snapshot). | Built. |
| A client's save never made the host save: `@prepend` on a GMS 2.3 global script put `mp_on_save()` before `function scr_save()`, so it ran once at start. | The hook goes inside the function (regex, like `scr_load`). | **Checked** by decompiling the built Chapter 1 and 4 `scr_save` (the installed v17 still has it outside). Saving itself not run (it would write saves). |
| Clients didn't store their own pick order, so each ranked itself first for a shared character. | PINFO about myself stores `mp_ppick` too. | Built. |
| The host's own choice box ignored the leader's answer when the leader picked alone after 30 s, so the host's game could take another branch; a late host answer could answer the next question. | In host-picks mode the host's box takes the leader's answer when it comes first; the leader drops one late host answer for 15 s after picking alone. | **Tested** (classroom, `fakechoice`): host picks (unchanged); host silent: after 30 s the leader picks 0 and the host's box gets 0. |
| The scene lock waited forever while someone was fighting. | After 5 minutes waiting for a fight the scene goes on. | Built. |
| "Players' heroes only" stripped Chapter 4's boss fights that need the whole party. | Skipped when the game set the party (`mp_enc_forced`). | Built. |
| Hosting or joining over UDP left an old Steam lobby open (and its code saved). | `mp_steam_leave()` on UDP host/join (not when the Steam join itself calls `mp_join`). | Built. |
| Migration: a UDP client was sent to the address "steam"; Steam clients stopped looking after ~60 s while the offer lasts 120 s; an extra search was started at once. | A clear message instead of connecting to "steam"; 40 retries; the extra timer removed. | Built. |
| Steam: C++ `bool` results declared as `int` (garbage upper bits); any Steam user's session was accepted and became a peer. | One-byte returns; sessions only from lobby members or known peers (requests rechecked for 10 s in case the member list comes later), and only those become peers. | DLL built; without Steam running the game says so and goes on. **Not testable here:** a real Steam session (needs two accounts). |
| Launcher: the disk check counted the chapter select's data.win twice; `--play` said "isn't installed yet" when the installed launcher only needed to patch again. | Fixed both. | Launcher built. |

## User test report 7 (Chapter 1, 2 players over the internet, user is host), 2026-11-22

Almost all done (2026-11-23); the open rows are listed in TODO.md. Grouped by area.

### The "server layer" idea: everyone sends inputs, the host decides and sends back what happened

What the user asked: separate a server layer from a user layer. Players send what they *want*
(inputs, "I talk to Berdly", "I start this fight"); the server answers everyone with what
happened, and whether it is local (only that player) or for everyone.

Possible, in this form: **the host as referee.** Today any player who touches a trigger starts the
cutscene and becomes its leader, and the others react; two players can start two at once (see
below). Instead, a player's game asks the host first ("start scene X here"), and only the host's
answer starts it, in every game at once, or only in that player's game for things marked local
(slopes, the checkerboard path, a minigame hit). One lock at a time per kind (scene, battle), held by
the host. That one change fixes several reports below (two scenes at once, a scene starting during
someone's fight, scenes playing twice, the host choosing for scenes others start) and gives a
natural place for a future vote. Battles already work this way (menu presses are sent and replayed
in every game), and the shop bag does since priority 2.

Not possible: a server that *runs* the game and sends everyone the result. The game's logic only
exists inside each player's own copy of DELTARUNE (GameMaker), so every game still has to play the
scene itself; the host can only decide *when*, *who* and *for whom*. Doing more would mean
rewriting the game.

Effort: L (every place that starts a scene, battle or pull goes through the request), but it can
be done step by step: cutscene start first, then NPC talk, then battle start.

Checked against the coop-anything playbook (github.com/cranebeaker/coop-anything, 2026-11-22):

* It is the playbook's own pattern: one story authority (the host) and **intents** from clients
  ("I activated X", numbered, run exactly once, acknowledged, resent until then;
  `effect-capture-story-sync.md` section 8), with "decide per kind of state who owns it" (shared /
  per player / local).
* Its lesson 41 fits DELTARUNE exactly: when every copy already runs the same scripted scene, sync
  the **start, the skip and the end**, not the scene itself (pause each copy at the start, the host
  says go, skipping tallied by the host). Our cutscene reading already syncs pages; the missing part
  is the start, which is what the referee adds.
* Its full "effect capture" (only the host runs story scripts, clients apply a recorded list of
  changes) does not fit: a DELTARUNE scene is something every player must *see* in their own game,
  and the story's lasting state is already one shared store (`global.flag` and friends, host
  authoritative since the start). Keep the store sync; add the referee.
* Worth taking along: an **epoch** per scene/room so late or repeated messages can't start a scene
  a second time ("scenes play twice"); a periodic **digest** of the shared flags compared with the
  host's, logged, to catch drift early; and **lag and loss tests** (the playbook's chaos tool), which
  we have never run. Room objects the scene changes directly (Alphys removed, the door's solid) are
  not in the flag store: the referee avoids the double scene that broke them, and the digest could
  later include a room census (lesson 70).
* Policy to write down per kind of state (playbook section 9): story flags host, money/bag shared
  through the host, HP per hero, positions per player, scene choices host (vote later), local-only
  events (slopes, checkerboard, a minigame hit) the player who caused them.

### Cutscenes and talking to NPCs

| Next | Issue | Status |
|---|---|---|
| done | Two cutscenes at once (Ch1 classroom: the user talked to Noelle while the friend talked to Berdly). Alphys vanished and the door lost its collision, even after resetting the room. | **Scene lock** (`scr_mp_lock`, messages 62-64, protocol 10): one shared scene at a time, granted by the host; a second one waits at its next box ("P1's scene is on: yours goes on after it"); the same scene from the same story point started in two games is watched from the first. **The classroom itself:** `obj_classscene` only makes Alphys (as an NPC) and the door's wall in the scene; a room built again at plot 2 (a join, a watched scene's room put back) had neither. Its Create now puts them back (`mp_classroom_restore`). Chapter 1 scene objects named otherwise than "...event" now count as scenes (the classroom, "...cutscene" ones, Kris's room, the fountain, Lancer's chase...; for these only a `con` that just changed counts, since the classroom sits at con 11 while played). **Tested:** the host starts the classroom scene (`setcon:obj_classscene:20:400`), the client watches it, both end at plot 3. |
| done | A player must not be able to start a cutscene while another is in a battle. | The host doesn't give the lock while anyone is fighting: the scene waits ("P2 is in a fight: the scene goes on when it's over"). **Tested.** |
| 1 | Cutscenes sometimes play twice. | Partly covered by the lock (stale or repeated pulls dropped; the same scene in two games is watched, not replayed). Re-check in play. |
| done | Choices in a scene someone else started: the host chooses. | With the host in another player's scene, only the host can pick (its own choice box); the leader takes that answer (message 65) and passes it on; status "Host is choosing...". The leader picks after 30 s if no answer comes. **Tested** (`fakechoice`, `pickright`: the host picked the right answer, the client's scene got it). Voting: future option (P3). |
| done | Talking to an NPC should be seen by everyone. | A bubble over the talking player with the text they're reading (message 66), on everyone's screen, without stopping anyone. **Tested** (screenshot, `saytext`). |
| done | Not synced: the Lancer escape (chase), Ralsei's lore at the start. | The chase (`obj_lancerchaseevent` and the scenes named otherwise) now pulls the others: **tested** in `room_dark_chase1`, the host watches each part. Ralsei's lore is a dialogue with Ralsei: seen by all through the talk bubble; the host answers the questions. Re-check in play. |
| done | Closet (Ch1): the friend entered a cutscene without pulling the user. | `obj_insideclosetcutscene` wasn't recognised (Chapter 1 only looked for "...event" objects); it is now. |
| done | Slopes and the checkerboard path shouldn't pull everyone. | Sliding (`obj_darkslide`) and the checker path's reset flash (`obj_ob_gen`) are never classified as scenes (`mp_local_action`). **Tested** (slope in `room_dark3`: "only mine", no pull). |
| 3 | Purple grass scene: a pulled player's sprite is stretched. | **Needs info:** which room / moment (a screenshot or multiplayer_log.txt). |

### Battles

| Next | Issue | Status |
|---|---|---|
| done | Choose the whole action ahead; on your turn just press Z. | While another player chooses: left/right the bar, Z opens what it leads to (enemy; ACT enemy then act; spell then target; item then hero), X goes back; a panel shows the plan ("Next for Ralsei: MAGIC > Heal Prayer > Kris (ready: Z on your turn)"). On your turn one Z plays it through the real menu; what became impossible falls back to the first possible choice, a press the menu refuses gives control back. Every menu press now carries its level's cursor (message 41). **Tested** (FIGHT > enemy as Susie, MAGIC > spell > hero as Ralsei: turns identical in both games; screenshot). |
| done | Battle text should advance for everyone; X speeds it for all. | Anyone's Z on a finished battle box turns it in every game, X held types it out for all (message 55). **Tested** (`botquiet`: the client never pressed Z, the host's turned its boxes; turns identical). |
| done | Waiting for a player freezes the battle. | A box over the held picture: "Waiting for P2..." with moving dots. |
| done | Downed SOUL: TP lost and gained at the same moment. | No TP gain for 45 frames after a hit while down. **Tested.** |
| done | TP-loss juice; no "-4 TP" label. | The bar flashes white and shakes; the label and the text are gone. |
| done | Ch1 Susie lock only in story fights she's in. | **Tested** (random encounter: normal; `story`: locked). |
| done | Remove the "focus" look. | No hero is darkened in multiplayer fights. |
| done | Don't pull a player into a battle on the turn the enemy dies. | Fight-ending state bit (128): no pull, no join. |
| done | Option: no AI party members. | F9 (host): "Story fights: Whole party / Players' heroes only" (off by default). On: a fight that brings the game's party keeps only the heroes some player plays. **Tested** (`playersonly`, story fight: party 123 -> 120 in both games, turns identical). |
| done | A player in a fight, seen from the map: battle idle pose. | Their character's battle stance (feet where they stood) with the white pulse. Watching them choose and dodge: future (L). |

### Overworld

| Next | Issue | Status |
|---|---|---|
| done | Out-of-battle damage hit the host instead of the friend. | A map hazard hits the character the player plays, in their own game (when that character is out on the map). |
| done | A player entering/leaving a room shows for one frame somewhere, then jumps; fade in/out. | Hidden for the first 150 ms after they change room, then fades in; leaving players fade out where they were last seen. |
| done | Map hazards: everyone's outline drawn as Kris's. | Each player's own character, outlined in white. |
| done | The house mirror reflects the wrong sprite. | The hallway mirror reflects the player's own character, and (2026-11-23) every other player in the room too, each as their character, flipped like the game does it for Kris. **Tested** (Ch1 `room_krishallway`, screenshots: the host's mirror shows P2's Susie as P2's own does). |

### Other

| Next | Issue | Status |
|---|---|---|
| 2 | The friend had no sound for a while; it came back later by itself. | **Needs info:** multiplayer_log.txt from that session. Possibly the game muted while unfocused or a song started late. |

## Bad network, drift check, minigames, voting, 2026-11-23

* **Bad-network tests** (from the coop-anything playbook): test token `chaos:<loss %>:<lag ms>:<jitter ms>`
  drops what a game receives with that chance and hands the rest over late (and out of order), with its
  own RNG. `cutscenes.sh` takes `CS_EXTRA` tokens for every game. **Found and fixed:** with
  `chaos:10:120:60` a Chapter 1 fight went out of step: Susie's last HP report and her player's "turn done"
  came in one datagram, the host wrote the next turn's state before taking the HP in, and every game got
  her old HP back. The HP is now applied first. **Tested:** Chapter 1 and 2 fights identical every turn
  (4 + 4 turns, about 10% of datagrams lost), Chapter 2 cutscenes `ch2_entry`, `ch2_queen`, `ch2_library`,
  `ch2_schooldoor`, `ch2_card_scene` pass.
* **Drift check:** every 5 s the host sends a fingerprint of the shared state (6 characters of md5 per
  variable, message 67). A client in free roam compares it and logs `[MPDRIFT]` with the names that
  differ; a difference seen three times in a row (about 15 s) gets the host's whole state, applied where
  the player stands (message 68, at most once a minute). **Tested** (`drift:<flag>:<frame>` changes a flag
  in one game without telling anyone): found, repaired, flags equal afterwards; no false alarm in four
  cutscene scenarios with and without a bad network.
* **Minigames, first step** (priority 3): the rhythm game, the chefs, the quizzes, the races, Susiezilla,
  Mike's game, pinball, the Chapter 5 minigames and climbing are recognised by their controller object.
  While I play one nobody else's figure is drawn over it; the others see "Playing the rhythm game..." over
  where I stand and `[rhythm game]` next to my name (message 69). **Tested** with `fakemg` (screenshots).
  Not done: playing them *together* (per minigame, see priority 3).
* **Climbing together** (Chapters 4-5, priority 3): while climbing, my climbing figure is what the others
  see (state bit 32, as the platformer), so climbers see each other on the wall, and each player climbs as
  their own character (Susie and Ralsei have climbing sprites; core.hook maps Kris's in `obj_climb_kris`
  and the rotating tower's Draw). On the rotating towers the others aren't shown (the tower projects the
  climber around it). **Tested** (`climb:<frame>`, `climbup`, `room_dw_church_trueclimbadventure`,
  screenshots: each game shows the other climber where they are, Susie as Susie).
* **Voting on scene choices** (priority 3): F9 (host) "Scene choices: Host picks / Everyone votes", off by
  default. Everyone in the scene gets the choice box and votes with Z; the status line shows each
  player's answer; the leader counts once all voted or 15 s after the first vote; most votes win, a tie
  goes to the host, then the leader (message 57). **Tested:** 2 players (1-1: the host's answer), 3 players
  (2 against the host: theirs); host-picks mode still passes.

## Native Windows test run, 2026-11-22

Tests now run on Windows with the native game (Git Bash; `tools/platform.sh`), 20x game speed.
* `regress.sh`: chapters 1-5 identical every turn with 2 and 3 players, no crashes.
* **Fixed:** a client joining while the host was on the title screen / file select was sent to the
  host's intro room (`room_intro_ch2` ...) and stayed there (the 1.0.1 join teleport accepted any
  `room_*`). It now waits until the host is in the game (`mp_room_title`).
* **Fixed (test setup):** the host's `party` token changed the story while connected without sending it;
  sent as ordinary changes it waited for the room's cutscene to end, and the client followed the host into
  room_dw_garden_intro with plot 0 and crashed in `obj_ch5_LW21_arrive` (`cutscenes.sh ch5_entry`).
  The host now sends its whole state, as after loading a save.
* `cutscenes.sh`: all 9 scenarios pass; the clients now really start elsewhere and are pulled in
  (before the fix five of them never left the intro room and passed without testing anything).

Full sweep on Windows (`tools/sweepall.sh`, chapter by chapter, 3-4 pairs at 20x, 756 scenarios: the
battle lists of chapters 2-5 keep only the encounters the chapter's code names, `tools/encused.py`).
Everything passes except test artifacts ("nobody moved": `room_krisroom` 0/1, `room_dw_rhythm` 132,
`room_lw_noellehouse_basement` 63, `room_cc_prisonlancer` 154 - the walking bot can't get out) and the
game's own crashes (also alone): encounters 4, 7, 12, 16, 31, 89-94, 174 kept by the filter, and the rooms
already listed below (`church_claw`, `churchb_library_alternate`, `snow_zone_battle` 290, Ch5 credits
rooms, `room_krisroom` 4, `room_town_school` 100).
* **Fixed:** a fight right after a cutscene I led left the watchers out and stuck watching (the
  cutscene's end only went out after 20 still frames). They are let go first and called in (Ch5 enc 1).
* **Fixed:** open-world fights have one hero per player, but some enemies need the others: Elnina &
  Lanino (Ch3 enc 113) read `obj_heroralsei.x`, Ch4's incense clouds take HP from all three and read
  `charinstance[2]`. Every story party member who isn't in the fight now gets an invisible stand-in
  (as Kris already did), and empty party places point at it.
* **Fixed:** Ch4's boss encounters 174-178 / 186 set the whole party themselves (`scr_setchar`); the host
  cut it down after that (Titan crashed without Ralsei), a client before it (the two parties differed).
  They are fought as story battles now (`mp_enc_game_party`, core.hook).
* **Fixed:** Noelle's house (Ch4, plot 66): a player who only watched the scene had the basement overlay
  but not the heart it follows (`obj_homealone_heart`), and crashed drawing it.
* **Fixed (test setup):** a test host still setting its scenario up takes nobody in (the client asks
  again); a host that started late had a client join it on the title screen. Self-checks also go on
  while waiting to join a fight (a long wait read as a freeze).
* Ch5 `room_alphysclass` 90 (one crash in `obj_ch5_LW21_arrive`) not reproduced; every class room
  scenario passes in the latest sweep.

Follow-up (only the related scenarios re-run after each fix):
* **Fixed:** Ch4 `room_town_church` 299: a client joining from a Dark World room into a Light World room
  whose scene starts on entry sent, with the cutscene pull, the world of its last room (the "before the
  cutscene" world is only taken while free, and it never was free there). The host watching it ended in
  the Dark World in the church. The pull now takes the current world when the saved one is from another
  room (`mp_calm_room`). 3 of 3 pass, the host watching the client's scene each time.
* **Fixed:** Ch1 text box closed in its first frame (a watcher getting the next box of the leader's
  scene): Chapter 1's `obj_dialoguer` only gets `myface` a frame later and its Destroy crashed
  (`room_cc_prisonlancer` 154, hidden before behind "nobody moved"). core.hook gives it a default.
* **Fixed (test setup):** `room_krisroom` plot 1+ started the players at the room's default spot, inside
  the bed (in play you're out of it after the wake-up scene and come back through the door): the test now
  moves a player out of anything solid in its first seconds (never during a cutscene). Checked by hand that
  in the real wake-up scene (plot 0, Ch1 and Ch2) both players get out of bed and walk. Noelle's basement:
  the player walks a heart (`obj_homealone_heart`), Kris is parked off screen; the self-check now logs it
  (`walk=`) and `mpcheck.py` counts it as moving. `room_dw_rhythm` 132 passes (was flaky).
* Rechecked, pass now: Ch4 `room_lw_church_main` 289, the door ghost cases (`room_library`, `room_diner`,
  `room_town_church` 100, `room_town_noellehouse` 89, `room_board_dungeon_3` 179).

## Battles: live TP, downed SOUL, Chapter 1 Susie, 2026-11-22

* **Live TP:** during the bullet phase each game sends its own TP change (message 53: turn, own gain
  since the phase began), and every game shows the phase's start plus everyone's gains, so the bar
  moves for all players as it happens. At the turn's end the leader recomputes it from the phase's
  start and each player's final count (gains can be negative now), so a lost update can't stick.
  Caveat: a TP change that every game makes by itself in the bullet phase would be counted once per
  player; none known.
* **Downed players keep playing their SOUL:** it stays visible in their own colour, darker, takes
  input and grazes for TP. A hit costs twice that bullet's graze TP (about 3% for a usual bullet),
  with the game's normal invincibility frames, a hurt sound and a "-N% TP" label. Players with no
  hero in the fight still only watch.
* **Chapter 1 Susie:** the player playing her (autopilot lent) now only gets FIGHT on the topmost
  enemy, as her autopilot does in the story, and does the attack timing.
* **Later (not now):** players left out of a fight (their hero isn't in the story party, isn't
  in the story yet, is taken by someone else, or a 4th+ player) only watch. Planned: support for up
  to 5 players and a proper spectator role for them.
* **Tested** (Ch1 encounter 13, 3 players: host Kris at 1 HP via the new `fragile` token, P2 Susie,
  P3 also Kris, random menus): the downed host's SOUL was hit and cost TP; the turn state, TP
  included, was identical in all three games; Susie's lock applied every turn; P3 watched. The
  fight ended in a real Game Over (both heroes down).

## Battle menu: choosing ahead, 2026-11-22

* While someone else chooses, the player whose hero comes next can already move that hero's
  main-row bar (FIGHT/ACT-MAGIC/ITEM/SPARE/DEFEND); Z only works on their own turn. If their option
  is greyed out (ITEM with an empty bag) the bar goes to the first one. A hero whose turn is used
  by someone else's action (an X-Action) just isn't asked, as before.
* Everyone sees the others' bars live: each move is sent (message 54) and shown in the status line
  ("P2: MAGIC"); the bar's position also travels with every menu press (message 41 gained a byte),
  so all games agree when that turn starts. The player choosing now is shown live as before (their
  presses replay in every game as they're made).
* Only the main row: entering a sub-menu (spells, targets) needs Z, so it waits for the turn.
* **Tested** (Ch2 encounter 53, random menus): the client moved its bar ahead 8-18 times per run,
  all turns identical in both games.
* Equipment: anyone could already change any hero's equipment from the C menu (synced); nothing to add.

## Reading cutscenes together, 2026-11-22

* **Everyone turns the pages:** in a shared cutscene, whoever presses Z on a box that has finished
  typing turns it for everyone (a follower's count goes to the leader, whose game turns it; the
  others follow the leader). The leader only follows a press made on its own box, so counts that are
  off by more never skip text. A box still typing when the page turns finishes at once.
* **X for everyone:** holding X on a box types it out at once on every screen on the same box (skip
  bit in message 60, next to "ready"; older games read it as ready).
* No more "Waiting for X..." / "X turns the pages..." / "Watching X's cutscene..." lines; the 15 s /
  30 s safety waits are gone with them.
* **Separate fights (open world):** while another player is still in their own fight, the scene waits
  at its first box for everyone in it ("X is in a fight: the scene goes on when it's over", at most
  5 minutes); the fighter is pulled in when the fight ends and catches up.
* Any player can start a shared cutscene and pull the others (not only the host): already so.
* **Tested** (Ch2 Queen intro, host walks in, client watching a copy of the host's scene and the
  only one pressing Z): all 39 pages were turned by the client, the scene ended for both. Three bugs
  found and fixed on the way: a watcher's Z/X were swallowed with every other key (only choices and
  arrows stay blocked now); a box that finished typing in the same frame as a Z closed without
  being counted (Z is held back while a box types, it does nothing there anyway); the X flag lasted
  one frame and was lost (now kept for the whole box). With the client holding X (`holdx` test
  token), the host's boxes were typed out 9 times on its X.

## Steam play and WASD, 2026-11-22

* **WASD** works as the arrow keys everywhere (`mp_wasd`, core.hook next to `obj_time`'s key checks), not
  while typing in F9 and not for a letter bound to push-to-talk. Checked in game (`holdkeys` token).
* **Steam** (F9: "Host on Steam", "Join on Steam with a code", "Join a Steam friend"; Steam's own "Join
  game" works too): `drm_steam.dll` (`steam/drm_steam.c`, `tools/buildsteam.sh`, Zig) on Valve's
  steam_api64 (shipped as `drm_steam_api64.dll`), app Spacewar (480). The host opens a public lobby with a
  6-letter code; messages go through Steam's relays (no port forwarding), the game's own protocol
  unchanged (peer "steam":n, `mp_pkt_send` / `mp_net_packet`). Without Steam running nothing changes.
  The patcher adds the DLL as a GameMaker extension (`mod/extensions.txt`); the installer copies `mod/dll`.
  **Tested:** Steam start, lobby + code, a second game finding the lobby by its code. **Not tested:** two
  different Steam accounts actually playing (one account can't connect to itself), the friends list.

## Roaring Knight fight (Chapter 3, encounter 115), found 2026-11-08 while taking screenshots

Tested with 3 bot players: room_dw_snow_zone, plot 320, the host walks to x 1850 and the scene plays.
* **Fixed:** players mirroring the cutscene ignored the battle pull at its end (mirroring switches off
  obj_mainchara, and mp_sync_try_pull took that for the title screen and declined). They join now.
* **Gone (2026-11-22):** the freeze after turn 0 (host's menu starting at Susie). With 3 players, both
  starting encounter 115 directly and through the scene (pos 1845,206), all three games choose turn 1's
  actions with identical HP/TP and reach the scripted game over together. Fixed by the earlier battle
  fixes. (The Knight is meant to win: tests can't go past turn 1.)
* **Not a problem:** the Christmas tree during the battle; the user checked it in play and it looks right.

* F7 / "Stop all music and sounds" (F9 menu): `audio_stop_all()`, for when the music desyncs; rooms start their song again on the next room entry (2026-10-11).

## User test report 6 (Chapter 1 battle loop with Rudinn), 2026-10-14

> I'm in a constant battle loop with Rudinn, the enemy isn't despawning after the battle. And I'd need to actively run away from the enemy which isn't like the gameplay that deltarune normally has.

Cause: every player has their own copy of each overworld enemy, and the game removes the touched one only in the toucher's game. The pulled player's copy (rebuilt fresh by the pull, right where they arrive) chased them after the battle, touched them and pulled everyone into the same battle again. Reproduced in room_field1 (`work/enemy.sh` with `noenemysync`): one Rudinn gave 4 battles bouncing between the two players.

**Fixed.** The touch handler (`obj_chaseenemy` user event 0 in Chapter 1, `obj_overworldenemy_parent` in Chapters 2-5) sends the enemy's object and starting point (message 36); every game removes that enemy now and whenever the room is built again (pull, rebuild), until the player leaves the room for another one (then it comes back, as in the game). Tested: Chapter 1 room_field1 and Chapter 2 cyber maze, one battle, enemy gone in both games.

## User test report 5 (Chapter 1 with 3-4 players), 2026-10-14

> Is there a reason you changed it so characters are reserved? [...] it essentially locks the character chooser if there's 3 players or more. [...] Also the health bar UI is still broken [...] some of the time even when I'm playing as a player not in the battle, it still makes me dodge the attacks for a different player. I managed to softlock the story and save file. After the Lancer battle, progressing to the room with Ralsei's training dummy is impossible due to Susie blocking it [...] Reloading the save doesn't help. I suggest looking out for anything which can cause a softlock like this, and adding a noclip feature.

| # | Problem | Cause | Fix / status |
|---|---|---|---|
| 1 | Character lock blocks the F9 picker with 3+ players. | A UX choice (TODO "same character twice"), not a bug fix: duplicates were already safe (the battle slot goes to the lowest-numbered player with that character). | **Removed.** Picker cycles freely, no auto-switch; the row says "(also P2: you watch battles)". Tested: 4 players all Kris, nobody switched. |
| 2 | HP bar drawn nearly empty while the numbers are right. | Numbers read from network buffers are int32; the game divides HP by max HP and int32 / int32 is an integer division (71 / 90 = 0). Logged: `int32/int32 ratio=0`. | **Fixed.** `mp_num()` turns every received number into a real (`mp_rval`, battle HP/QTE reads). Tested: Chapter 1 battle, bars match the numbers on both screens (screenshot). |
| 3 | Players whose character isn't in the battle still dodge. | A watcher got a normal SOUL (hits did nothing, but it flashed). | **Fixed.** A watcher's SOUL is dimmed and labelled WATCHING, no hit flash/sound, status line "Watching: Ralsei is not in this battle. No need to dodge." Tested with 3 players, party Kris+Susie. |
| 4 | Story softlock after the Lancer battle (Susie blocks the way, survives reloading). | `obj_darkcastle_event` (room_castle_front) runs in each player's game: plot 20/21, Lancer battle (22), Ralsei's story, plot 30. The lagging player's copy wrote plot 21 after 22; the host took it, its room was rebuilt during the story (con 100: the old `con < 90` cut-off missed it), the event deleted itself (it does when plot >= 20) and plot stayed 21. Reproduced with `staleplot:22:21` + `nomono`: plot ends at 21. | **Fixed.** (a) Ordinary updates can't move plot backwards (refused; the higher value is sent back); full snapshots still can. (b) A room is not rebuilt (plot refresh, post-battle rebuild) while a Chapter 1 event's `con` changed in the last 10 s. Same test with the fix: both games end at plot 30, party Kris+Ralsei (as in vanilla). (c) `scr_getchar` never adds a party member twice in multiplayer. |
| 5 | Way out of softlocks. | | **Added** (F9): noclip (F6, own game only), "replay this room's story" (host: room-entry checkpoint of the shared state, room re-entered for everyone), "story progress < N >" (host: set plot, re-enter). README has the recipe for this save (castle front door, 19). |

Tests after these changes: story tool on a stuck save (plot 21, Kris+Susie, real F9 key presses, set 19): the castle scene and Lancer battle replay, Susie not added twice, both games end at plot 30 with Kris+Ralsei; rewind (gold/flag/plot back to room entry on both games); noclip (real F6: through Susie's blocker into room_castle_tutorial; without it stuck at x=408). Regressions: `regress.sh` all 5 chapters identical, `cutscenes.sh` 9/9 pass, Chapter 1 story sweep 75/79 (the same 4 test artifacts as before).

## User test report 4 (Chapter 1 Ralsei cutscene into the Lancer battle: softlock), 2026-10-11

Reported by the user after playing it themselves (two screenshots; the window title is "The Beginning", i.e. Chapter 1, the Lancer-on-a-bike fight in the castle prison hall):

> I softlocked it. I skipped ahead on the ralsei story cutscene on one, then not on the other, then the battle only started for one, then the battle started for the other, the HP desynced, I finished the battle and now one of them is softlocked, pressing F8 shows "Can't go there right now"
>
> And the health bar broke for susie
>
> Plus both players had to dodge despite only one player being involved in the battle

What the screenshots show: (1) the two battle screens at the same moment: top says "ALFIE2 IS CHOOSING FOR KRIS..." with Kris 76/90, Susie 96/110 and the ACT text "Lancer is thinking about chips."; bottom says "YOUR TURN: CHOOSE KRIS'S ACTION!" with Kris **90/90** (HP differs between the players) and Susie's text reading 96/110 while her **HP bar is almost empty** (bar and number disagree). (2) afterwards: one player stands in the empty castle room with only Ralsei on screen, the other sees the same room with nobody visible and, after pressing F8 several times, five lines of "CAN'T GO THERE RIGHT NOW." (the softlocked one).

| # | Issue | Status |
|---|---|---|
| 1 | Skipping the cutscene on one player and not the other: the battle starts for one player first and for the other later. | **Cause found, fixed (not reproduced with the exact Chapter 1 scene).** A battle pull used to wait for the receiver's own cutscene ("never cut short a story cutscene"). If that cutscene then led into the same fight, the receiver started it itself from turn 0 while the other player was further on: two different battles for one encounter. A battle pull no longer waits (`mp_sync_try_pull`): the receiver joins at once and its own cutscene is cut short (`mp_kill_scenes`). Checked with the Chapter 2 Queen scene with one fast and one slow player, in both orders: identical battle logs on both sides. |
| 2 | HP of the same hero differs between the two players during the battle (Kris 76/90 vs 90/90). | Probably the same cause (the second player's own battle starting from its own, full HP). Not verified separately. |
| 3 | Susie's HP bar is drawn nearly empty while her HP reads 96/110. | Open: not reproduced; likely a consequence of two battles being set up for one player (the bar is drawn from the second battle's values). Re-check after a play-through. |
| 4 | Both players had to dodge although only one of them was in the battle. | Probably the same cause: the second player's own battle gave them a SOUL and bullets. Not verified separately. |
| 5 | After the battle one player is softlocked (hidden character, only Ralsei marker on screen, F8 says "Can't go there right now"). | **Fixed in two ways.** (a) After a battle in which my own scene was cut short (`mp_scenes_killed`), the room is rebuilt 2 seconds later at the same spot, the character made visible and interact released (`mp_postbattle_tick`, log "rebuilding the room after a battle that cut my scene short"): a scene cut off in the middle left the character hidden, the party replaced by markers and interact stuck. (b) F8 pressed twice within 5 seconds frees any stuck sync state (`mp_unstick`) and goes to the host; the first press says "press F8 again to force". Tested with the `stuck:<n>` token (faked stuck state): second F8 logs "Released a stuck state." and "Going to Host." |

## User test report 3 (Chapter 2 and Chapter 5 platforming), 2026-10-09

Reported by the user after playing it themselves (with screenshots: a Ralsei "Joining Alfie2 for a cutscene..." room with a pile of cards, a Kris in Hometown with a pile of cars and a "Joining Alfie..." banner, a Chapter 2 battle with garbled text, and a Chapter 2 battle where the party's HP bars look wrong):

> I tried in the aqua platforming room you suggested earlier, the sidescrolling parts are basically nonfunctional, just acts exactly like it does singleplayer. Then I decided to play chapter 2, when a player goes ahead of the other and triggers a cutscene, it can result things to break a lot, this was me grabbing the cards from the other room on one client, then on the other client it looked like this when jumping into the dark world, then the music desynced on both clients (one playing castle town, other playing empty town), and lancer was there on one while he wasn't on another. Other than that things were still fine. Also had the same thing when jumping into the library dark world. Then the cutscene introducing Queen broke everything, when i went ahead and left the other client behind, it seemed fine at first, until the battle started, and started playing the cutscene on the other client, even though it already played, while in battle. I saw the dialog appear over the battle and now it started another battle within the battle, leaving the game softlocked. I haven't managed to outright crash the game, but I managed to softlock it, which I feel like is an improvement. Also the health bars are seem broken.

| # | Issue | Status / cause |
|---|---|---|
| 1 | Chapter 5 platforming sections (e.g. `room_dw_garden_aquaplatforming`): players don't see each other, it behaves exactly like single-player. | **Mostly done.** The platformer is the game's own engine (`obj_plat_player`, always Kris's platformer sprites). New `gml/ch5/scr_mp_plat`: your platformer figure is sent (draw position, sprite, frame, direction; state bit 32) and the other players are shown as ghosts in the same room, hidden unless both are in a platforming section. Joiners only change room. Test bots now jump (`wander`), and `mpcheck.py` knows the platformer (looser ghost tolerance: jumps are fast). All 7 platforming rooms pass. **Not done:** each player is still drawn as Kris there (the platformer has no per-character figure), the figures' hits/enemies/pickups are not shared (everyone plays their own copy), and a real human has not tried it. |
| 2 | Chapter 2: a player runs ahead and triggers a cutscene (grabbing the cards, jumping into the dark world / library dark world): the other player sees a broken screen (piles of cars/cards), the music differs (castle town vs empty town) and Lancer is present for one only. | **Fixed (user's exact steps: exit the Dark World on one client, collect the things at the school, go back in; the castle town is built from them).** Three causes: (1) *music*: rooms only start a song when none plays; everyone now announces their song (type 34) and moved players follow it (earlier fix). (2) *Large sprites / piles*: the Light/Dark World state (`global.darkzone`) was never carried: a player in the Dark World pulled into a Light World room kept Dark World followers and sprites (drawn big) and the room's actors copied them. It is now sent with pulls (state from before the cutscene), cutscene ends, joins and the new "go to" action (state bit 64 in position messages, protocol v3); a change re-enters the room so followers/sprites are built for the right world. New `mpcheck.py` check "world" (same room = same world). (3) *Lancer / castle town not matching*: room objects are built from the story progress when the room is entered; when another player moves the story on while you stand in a room, yours was out of date. After the changes settle (90 frames, free roam only) the room is now entered again at the same spot (`mp_room_refresh_tick`, log `room refresh`), also at the end of a cutscene in the same room. Checked with `lightworld` / `setplot:` test tokens and the castle town scenario (`work/cut_town`). |
| 3 | Chapter 2, Queen introduction: one player left the other behind; when the battle started, the other client played the cutscene again over the battle, then started a second battle inside the battle: softlock. | **Fixed.** Reproduced with `tools/cutscenes.sh ch2_queen` (host walks into the scene while the client is in another room). The pulled client arrived at the battle's room and the room's own scene (`obj_ch2_scene9`, triggered by the player's x) started there as well; its dialogue drew over the battle and it started encounter 53 again. This is not specific to Queen: any story cutscene that leads into a battle (the user's point) can do it. So the fix is generic: `mp_kill_scenes()` removes, when joining a battle and every frame until the battle exists, every object that holds a cutscene master (`cutscene_master` variable: that is how every Chapter 2-5 cutscene object works, whatever it is called), the masters themselves, and objects named `obj_*scene*` / `obj_*event*` (Chapter 1 has no cutscene master: its story controllers are `obj_*event` objects). Verified in Chapters 2-5 with a made-up cutscene object (`fakescene` test token, started while being pulled into a battle): the new check fails without the fix (`nokill` token) and passes with it. Chapter 1 is covered by name only (not verified with a test). New check "scene": fails if a cutscene runs in a game that was pulled into a battle (`SCENE-IN-BATTLE` in the log). With the fix both players finish the fight, the story moves on (plot 51) for both, nobody is stuck. (`weak` test token: enemies have 1 HP so a battle ends quickly.) |
| 4 | Chapter 2 battle: party HP bars look broken, battle text garbled/overlapping. | **Fixed (same cause as 3).** With the scene removed the bars and text are normal; with the fix disabled (`nokill` token) the scene's dialogue is drawn over the battle. |

## Sweep status after the report-3 fixes, 2026-10-10 (`work/sweep/ch3_s1`, `ch4_s2`, `ch5_s1`)

Chapter 5 passes (only the credits-room crash, the game's own). Chapters 3-4 still list:
* The game's own crashes (see below), plus **new, unexplained**: Chapter 4 `room_lw_church_main` plot 289 (`obj_ch4_DCB03` Step, "Variable obj_ch4_DCB03.su... not set", 2 players, interact 1). Not looked at yet.
* "nobody moved" in `alphysclass` and Light World rooms (Noelle's house, church, torhouse): probably the bots cannot walk there (test setup), not confirmed.
* Ghost mismatches around doors at the top of a town room: `room_library` plot 3/12 (Ch 3 and 4), `room_diner` 45/49/50, `room_town_church` 100, `room_town_noellehouse` 89, `room_board_dungeon_3` 179. The host stands at y of about -7 (past the top edge, on a door) and the other client sees a stale position (820,180) or no ghost for 2-4 s. Could be a real stale-ghost bug when a player is moved by the mod to a door trigger; not investigated.
* `tools/mpcheck.py` ghost check now ignores samples with a text box open (a game-driven text box flickers `interact` to 0 for 2 frames and the mod hides ghosts during dialogue; this was `room_town_school` 300) and moments within 3 s of the other player changing room.

## Chapter 1 music, fixed 2026-10-11

There was no music sync in Chapter 1: the mod identifies the playing song by the `songname` that Chapter 2+'s `snd_init` records on its `obj_astream`, and Chapter 1's `snd_init` does not, so every song read as "none" and nobody followed anybody. A Chapter 1 hook now sets `songname`. Checked with the new `song:<file>` test token (host plays `field_of_hopes.ogg`, a joining client logs `music follows player 0: field_of_hopes.ogg`). The sweeps could not show this before because the title screen's drone song is still "playing" in test warps. Known small difference: a following player plays the song at full volume (Chapter 1 rooms start some songs at 0.7).

## Chapter 1 two-player crashes, fixed 2026-10-11

`room_castle_town` 30, `room_field_boxpuzzle` 49 and `room_forest_chase2` 150 crashed with two players but not solo (vanilla or mod). Causes, all in the mod: (1) the mod's warp keeps `interact` at 3 for a few frames, so `obj_mainchara` never set `runmove` (it only does so while interact is 0) and Chapter 1's Ralsei run event crashed reading it: `runmove` now gets a default at room start. (2) Chapter 1 has no cutscene master, so the mod did not see its `obj_*event` cutscenes as running and a pull restarted the room in the middle of one (box puzzle): such events (`con` between 1 and 89, interact not 0) now count as a running cutscene and the pull waits. (3) HP is shared: another player's hit could leave a hero at 0 HP here without the game's Game Over having run; the next overworld hit then looked for another hero whose instance does not exist (`charinstance` has one entry in the chase). `scr_damage` outside battles now runs the Game Over when a party hero is at 0 HP (`mp_overworld_all_down`). The crash log line now also shows party, HP and `charcantarget`. Full Chapter 1 sweep: 75 of 79 pass; the rest are test artifacts (bed rooms, prison cell, class scene party).

## Vanilla check and feature tests, 2026-10-11

* **Vanilla comparison** (`tools/buildv.sh` builds `buildv/`: only the test harness, none of the multiplayer gameplay hooks; `SWEEP_BUILD=buildv tools/sweep.py <ch> --solo ...`). These crash on vanilla too, so they are the game's own: Ch3 `snow_zone_battle` 290, enc 141; Ch4 `church_claw` 150/169/170, `churchb_library_alternate` 236/238, enc 93/174/179/180; Ch5 credits rooms (`castle_rooms_susie`, `ralsei_castle_front`) 390, `room_gameover` 279, `room_krisroom` 4, `room_town_school` 100, enc 777. Not reproduced on vanilla: Ch1 `castle_town` 30, `field_boxpuzzle` 49, `forest_chase2` 150 (they crashed in two-player runs, not solo: **still to look at**, could be the mod); Ch4 `lw_noellehouse_dess` 66 (was the test starting the Light World room in the Dark World state, gone with `lightworld`); Ch5 enc 235 (debug enemy `obj_enemy_example`, only crashes with two players: it sets `myattackpriority` only in the "enemytalk" phase, which the two-player battle flow can skip; not reachable in the story).
* **New features, tested for real:** Game Over then Continue (two players, `nododge`): both reach Game Over, the client then logs "Going to Host."; downed SOUL dimmed with a DOWN label (screenshot); barrier names on clients (a third player frozen with SIGSTOP: both others show "WAITING FOR P3..."); F8 with a real key press (xdotool) goes to the host; chapter resume (host and client, via the ini): the Chapter 2 client connected to the Chapter 2 host with no flags; duplicate character resolved (client asked for Kris, became Susie); `gotohost` token.

## Sweep result after the playability batch, 2026-10-11 (`work/sweep/ch*_f`, flow.py, regress.sh)

All five chapters swept again with the new build. Everything passes except: the game's own crashes (Ch1 `room_castle_town` 30 / `room_field_boxpuzzle` 49 / `room_forest_chase2` 150, Ch3 `snow_zone_battle`, Ch4 `church_claw` and `churchb_library_alternate`, Ch5 credits rooms, `room_gameover`, `room_krisroom` 4, `room_town_school` 100; the Ch5 ones were confirmed solo), and test artifacts: `room_krisroom` (both players start in bed, bots cannot move), `room_dw_rhythm` 132, Ch1 `room_alphysclass` 1 (the class scene sets its own party, the test's differs). Flaky ones (`town_shelter` 349, `bellhall_bookroom` 242, `town_mid` 94) pass alone. Real key-press flow (file select, new game, F9, three players, Chapter 4) passes; battle sync (`regress.sh`, 2 and 3 players) passes.

## Playability batch, 2026-10-11

* F8 / "Go to <player>" (F9 menu) takes you to the host (host: first other player), with a fade; fixes anyone stuck in a puzzle or a room that is out of step. Warps in general fade in now.
* (Removed 2026-10-14, see report 5) Two players couldn't play the same character.
* After Game Over + Continue, clients are taken to the host once they have reloaded.
* The turn barrier names who it is waiting for on every client (host sends type 35).
* Downed players' SOUL is dimmed and labelled DOWN.
* Chapter change: the session is remembered in `multiplayer.ini` (`[resume]`); the next chapter's start within 15 minutes hosts / joins again by itself (join retries for a few minutes). "Stop hosting" / "Leave" forgets it.
* ACTs: the RNG is re-seeded at the start of each hero's action (all players), not only at phase starts.
* Test tooling: `lightworld`, `setplot:<n>`, `gotohost:<n>` tokens; sweeps start Light World rooms in the Light World; `mpcheck.py` ignores text-box flicker, doorways outside the room, door-crossing delays and freshly built rooms in the ghost check.
* Crash `obj_ch4_DCB03` (Chapter 4 Light World church) was the same world-state bug and is gone.

Not done (decided): gold as deltas (battle rewards are applied by every player locally, so adding deltas would double them; two players buying at the same instant can still overwrite each other), "skip their text" at the barrier (the barrier is what keeps the battles identical), saving for the host, host migration (clients don't know each other's addresses: needs a handover message and a forwarded port on the new host).

## User test report (Chapter 4), 2026-10-08

Reported by the user after playing it themselves:

> I just tested it out myself, it's very buggy, i think more dynamic testing should be done, i started it on chapter 4, and when i got out the cutscene, i saw an NPC kris following me, despite it being kris and susie, and i had one of the clients set to susie, yet it's still controlling kris, then on the synced cutscene thing, none of it actually played. You should ensure your dynamic testing covers all this, ensure that all players are the characters they chose, and they can move independently, and there's no desync.

| Issue | Cause found | Fix |
|---|---|---|
| A client set to Susie still walked as Kris (Chapter 4). | Chapter 4 draws Kris with its own `draw_sprite_ext(..., x + tower_shake_xoffset, ...)` instead of `draw_self()`, so the sprite-swap hook never ran. That also meant your position was never sent as "visible", so nobody saw you and nothing got hidden. | Chapter 4 hook for that call (`mp_draw_mainchara(xoff)`). Swaps now also stay on while talking to people, reading signs, going through doors and during anything that only happens in your own game. Before, you briefly turned back into Kris then. |
| An NPC Kris followed the player. | The follower standing in for your own character is drawn as Kris. It was only hidden while the Kris player was visible in the same room (and with the bug above, never). | A party member any connected player plays is never drawn as an NPC follower, wherever that player is. |
| The shared cutscene didn't play. | Several separate problems: (1) the leader's first story-flag/plot changes were broadcast before the pull arrived, so the cutscene no longer triggered for the others; (2) a player still in their own cutscene dropped the pull; (3) a leader who walked from one cutscene straight into the next never sent a pull for the second; (4) cutscenes that start on entering a room didn't re-trigger for someone already in that room; (5) the pull set `plot` (possibly already advanced). | Shared-state changes are held while a possible cutscene is being classified. The pull carries the plot from before the cutscene and whether it started on room entry (re-enter the room, or `room_restart`). Pulls received during your own cutscene wait until it ends if the other cutscene is still going. Pulls from earlier in the story than you are are ignored. A leader starting another cutscene pulls again. A door handing straight over to a cutscene is detected. A cutscene that changes room early still pulls. |
| (found while testing) Spectators could get stuck, and "you can't go that way" messages pulled everyone. | Any unprompted text box counted as a cutscene. A tiny event repeated by the leader kept spectators frozen. | Pull only if a new cutscene controller appears or the plot changes within 20 frames, or if it lasts more than 4 s. Spectators are released after the leader has been walking around for 3 s. Spectators now see the leader's dialogue text. |
| (found while testing) A battle's "!" intro was taken for a cutscene, and its pull overwrote the pending battle pull. A Game Over then warped the spectator into `room_gameover` (crash). | `interact` rises before the battle objects exist. | Touching an enemy (`obj_testoverworldenemy`) is never a cutscene. A pending battle pull wins over a cutscene pull. Nobody is ever moved into Game Over or menu rooms. |
| (found while testing) Battle menu desync: one player's game ignored a press that the others' replay accepted, so the game deadlocked at the turn barrier. | The battle menu ignores presses for a few frames after the previous one. The replay can only be later, so an ignored "too early" press could be accepted remotely. | The menu owner's presses are kept at least 5 frames apart (an early press is held back, not dropped). |
| (found while testing) Battle party mismatch (Chapter 5): a pulled player fought with a different party. | Each game used its own `global.char`. | The battle pull carries the starting player's party. |
| (found while testing) Special walking sprites (`spr_kris_walk_left_church`, `spr_kris_walkd_hold`, ...) showed Kris for other characters. | The direction wasn't recognised from those names. | Direction detection understands `_walk_left`, `_walkd`, etc. for every character. |

## Testing — what now exists

* `tools/flow.py`: real game flow. N instances, real key presses (xdotool) through the file
  select, new game (name entry) or loading a save, and the F9 menu (pick a character, host,
  join), either at the file select or after starting. The bot (`mash`, `wander`) then plays.
* `tools/mpcheck.py`: checks every player's twice-a-second self-check lines (`-mptest check`).
  Each player is drawn as the character they chose in free roam. No party member played by
  someone is drawn as a follower. Every other player in the room is shown where they really
  are. The shared state hash (plot, gold, party, flags, items, HP) matches. Nobody is left
  frozen/waiting, and nobody crashed or froze. Players moved independently.
* `tools/cutscenes.sh`: scripted real story cutscenes in Chapters 2–5 (on entering a room,
  and by walking into a trigger) with the other players in a different room; checks they are
  pulled in and the cutscene plays in their game.
* `tools/regress.sh`: battle sync in every chapter (unchanged).
* Log lines are wall-clock timestamped (`run_game.sh`) so players' views can be compared.

* `tools/sweepgen.py` + `tools/sweep.py`: about 560 story scenarios (every room with story
  objects at the story points they check) and every battle encounter in Chapters 1-5, with a
  host and a joining client (`--clients 2` for three players, `--solo` to find the game's own
  crashes). All pass except the game's own crashes (listed under the crash reports).
* `tools/aiplay.py` + `tools/llm.py`: AI-driven playthrough. Each player is a vision model
  agent (model and provider from the opencode config; default `commandcode-goat`
  `deepseek/deepseek-v4.1-flash`) that looks at its screen and presses real keys; the result
  is checked by `mpcheck.py`. Includes a notes logbook, stuck/room hints and random
  unsticking. A first Chapter 4 run (new game, 2 players, 45 min) reached the church with no
  crashes or desync, but progress is slow (about 7-25 s per decision). `work/aiall.sh` plays
  every chapter in turn (not started yet). Long runs use API quota: ask before running.

* `tools/cutscenes.sh` custom scenarios (`ch2_queen`, `ch2_library`, ...) use the test tokens
  `away:<room>:<n>[:<x>:<y>]` (walk through to another room n frames after the party setup, like a player
  running ahead or being somewhere else) and `weak` (1-HP enemies). `mpcheck.py` also checks
  that players in the same room hear the same song ("music") and that no cutscene runs in a pulled battle ("scene").

Still not covered automatically: Chapter 1 new game (the vessel creation; Chapter 1 is
tested by loading a save), joining mid-cutscene, cutscenes started with Z (user report 3),
platforming sections (only "stand in the room" is tested), real play-through of whole chapters.

## User crash reports and the Chapter 3 board, 2026-10-08

| Issue | Cause | Fix |
|---|---|---|
| Crash: `obj_mainchara` Create, "Unable to find any instance for object obj_markerC" (Chapter 1). | The mod moves players between rooms with `interact = 3` (like a door) but kept the last door's entrance number, so the game looked for that door's entry marker in a room that doesn't have it. | `mp_warp` clears `global.entrance`; the mod places the player itself. |
| Crash: `obj_ch3_gameshow` Step, "Unable to find any instance for object index 0" (Chapter 3 board). | A player who only watched a cutscene was moved to where it ended (the board) before receiving the story changes from it (Susie/Ralsei joining the party), so their followers didn't exist. | The leader sends all its story changes before "cutscene ended"; spectators apply them before being moved. |
| Chapter 3 board game didn't work in multiplayer. | The board is drawn at a fixed place while the board scrolls underneath (the `BOARD_Tiles` layer moves); the mod only knew about walking characters, and treated the couch party as walking characters. | Board mode (`gml/ch3/scr_mp_board`): everyone plays their own copy of the board, like walking around. Your piece (Kris's) is drawn as your character, pieces other players play are hidden and shown as their name-tagged ghost when on the same board screen (positions sent relative to the whole board). The couch shows the real party. Board events never pull anyone; real battles still do. Joining someone on the board only changes room. |
| Crashes were hard to report. | | Unhandled errors are written to `multiplayer_crash.txt` (next to the saves, with chapter, room, plot, sync state and stack) and the log (`[MPCRASH]`, which the tests check). |
| (sweep) Crash: `obj_floorshadow` Draw, "non-existing sprite" (Chapter 4 ripple puzzle). | A pulled player was put on the cutscene's trigger spot right at Room Start; the cutscene began on frame one, before the new party followers had sprites, and copied empty sprites into its actors. | After moving to another room the mod waits 4 frames (like a door arrival) before stepping onto the spot; Chapter 4 shadows also skip a missing sprite. |
| (sweep) Crash: `obj_ch5_DW10` (Ralsei missing), Chapter 5. | A player busy in their own cutscene joined the other's afterwards without first applying the shared state that arrived meanwhile (party members). | Pulls apply queued shared state first, and carry the leader's party from just before the cutscene; a changed party re-enters the room so followers exist. |
| (sweep) Crash: end credits rooms (Chapter 5). | Each credits room counted as a new cutscene; others were pulled into credits rooms that need the credits' own objects. | No pulls or cutscene-end moves while the credits play. |
| (sweep) Story state could end up swapped between two players (plot, party). | Two players finishing cutscenes at the same time each applied the other's in-flight change. | The host's copy is the shared one: it echoes every change it applies from a client (including ones it queued while busy) to everyone. |
| (sweep) Text boxes that pop up by themselves ("you can't go that way") pulled everyone and could keep them frozen. | Any unprompted `interact` lasting 4 s counted as a cutscene. | A cutscene must do something cutscene-like (new cutscene controller, story progress, new actors, player hidden or moved by the game, party stops following). Spectators are released when the leader is walking around again. |
| (sweep) A pulled player sometimes re-watched a cutscene they had just played, or was put off-screen. | Arrived while the other's copy was still running / position taken on the frame the cutscene moved the player away. | Pulls for a room+story point you just played are ignored; the start position is taken from two frames earlier. |

| (sweep) 3rd player joining during a battle got no turns. | Only the first two players got the battle pull. | The host sends a battle pull to anyone joining while a battle runs. |
| (sweep) Joiner stood outside the doorway; no battle started. | Warp used the draw position +4. | Players send their real position; joiners are warped there. |
| (sweep) Battle menu deadlock / HP desync (Ch 4 enc 151, Ch 5 enc 222). | Presses too close together, input at the turn barrier, stray enemy-owned hits. | 5-frame press spacing, input blocked at the barrier, HP reports tracked (`mp_rhp_known`). |
| Game's own battle crashes (also solo): Ch 3 enc 141, Ch 4 enc 93/174/179/180, Ch 5 enc 235/777. | Missing enemy variables / debug encounters. | None needed. |

### Automated story sweep (tools/sweepgen.py, tools/sweep.py)

Every room with story objects is visited at each story point (`plot`) those objects check:
the host starts there, a client joins from elsewhere and is moved in by the mod, bots play,
`mpcheck.py` checks everything (crashes, characters, followers, ghosts, shared state, sync).
`--battles` does the same for every encounter (3+ turns, battle state compared per turn).
Crashes that also happen single-player (`--solo`) are the game's own / from teleporting
into unreachable rooms, not multiplayer:

* Chapter 3 `room_dw_snow_zone_battle` (plot 290), Chapter 4 `room_dw_church_claw` (its door
  leads to a room that doesn't exist), `room_dw_churchb_library_alternate`, Noelle's house
  "home alone" sequence entered mid-way, Chapter 5 credits rooms entered directly, and the
  Chapter 5 opening in Kris's room with a 3-person test party.

Known, harmless: per-player statistics stored as story flags (Chapter 5 "slashes" count)
keep the last writer's value instead of adding up.

## Priority 1 — quick wins that make things feel right

All done on 2026-11-22 (built, **not tested in game yet**):

| Issue | What was done |
|---|---|
| Waiting on slow readers at the turn barrier. | Already solved (confirmed in play). |
| Downed players' SOUL did nothing when hit. | It stays playable, darker, grazes for TP; a hit costs 2x the bullet's graze TP (see "Battles: live TP..."). |
| Players who only watched a cutscene were dropped at the leader's final position abruptly. | The screen fades out (about 1/3 s) before the move and fades back in after it (`mp_cs_end_fade_tick`). |
| Moving to the next chapter disconnects everyone. | IP sessions already resumed (`mp_resume_save/load`, within 15 minutes). Steam sessions now do too: the host opens a lobby with the same code and the others search for it again for about a minute (`drs_lobby_get` gives joiners the code). |
| Game Over: after Continue, players can end up in different rooms. | Clients already went to the host after Continue; they now wait (up to 2 minutes) until the host has reloaded too and is in a normal room, not still on the Game Over screen. (Not testable with the test harness: it has no save file to reload.) |
| Same character twice: the second player silently became a spectator. | Kept, but on purpose: the host numbers character picks; whoever picked a character first plays it, the others watch that player's SOUL in fights and take over, first come first, when they change character or leave. F9 says so when you pick a taken character. (Overworld: both still walk around as that character.) |
| Puzzles/set pieces can leave a player stuck. | Already there: F8 goes to the host (twice within 5 s also frees a stuck state), Shift+F8 brings everyone to the host; arrival fades in. |
| Random ACT outcomes could briefly differ. | Besides the seed at each hero's action, the RNG is now re-seeded identically each time one of the action's text boxes opens or closes. |

## Priority 2 — protect progress

All done on 2026-11-22. "Tested" means a targeted automated test; "not testable here" says why.

| Issue | What was done | Test |
|---|---|---|
| Shop money: "last total wins", simultaneous purchases overwrote each other. | Money goes out as changes ("-50"); the bag (items, weapons, armour) as what came in / went out. The host takes those in order (new items into the first empty slot) and sends everyone its bag back; a client puts its own untaken changes back on top (`scr_mp_inv`, messages 22-24). | **Tested** (`buy:<item>`): two players bought in the same millisecond; both ended at -100 money with the same bag. |
| Save points: a client's save left the host's file behind. | A client's save asks the host to save too (message 25), as soon as the host is free (within a minute). | **Not testable here:** the test games use the real DELTARUNE save folder, so a test save would overwrite your own save files. |
| Host leaving ended the session. | The host sends everyone each player's address (message 8). When it leaves or stops answering, the next player (lowest number) gets "Become the host" in F9; the others look for them for about a minute (Steam: same lobby code) and are told if that player's port isn't forwarded. | **Tested** over IP, 3 players (`leaveat`, `autohost`): the host left, P3 took over, P2 reconnected to P3 in ~3 s. **Not testable here:** over Steam (needs two Steam accounts) and the "can't be reached" message (needs a real network). |

## Priority 3 — special content

| Issue | Fix | Effort |
|---|---|---|
| Minigames have no multiplayer handling (only the Ch3 board and the Ch5 platformer do): the rhythm game (`obj_rhythmgame`, Ch3; its code is also in Ch4/5), the chefs/kitchen game (Ch3), the quiz/game show (Ch3), climbing (`obj_climb`, Ch4/5), the organ (Ch4). Each player plays their own copy while the others' walking ghosts are drawn over it. | First, for all of them: detect the minigame, hide the ghosts, show "P2 is playing" and let one player play while the others watch (or play their own copy, then take the host's result). Then per game: **rhythm** - each player plays their character's chart (the game already has three: Kris guitar, Susie drums, Ralsei vocals, the last two on autoplay), hits sent and the score added up; **climbing** - the others shown as ghosts on the wall, as in the platformer; **quiz/game show** - each player buzzes for their character. | Fallback **done** 2026-11-23 (detected, figures hidden, "Playing ..." shown); climbing together **done** 2026-11-23; L per game |
| Special battle styles (Spamton NEO, Berdly/Queen, Chapter 4/5 gimmick fights) likely only partly sync. | Detect special battles and fall back to "one player drives the battle, everyone else spectates and dodges". Later, hand-sync individual fights people care about. | S–M (fallback); L per fight |
| Voting on cutscene choices (future option; for now the host chooses, see report 7). | **Done** 2026-11-23: F9 setting, see "Bad network, drift check, minigames, voting". | - |
| Minigames played *together*, not each on their own screen (idea from play-testing). Example: the throw minigame - Susie throws Kris, and Kris's player presses a button mid-air for a sword swing that widens his reach for a moment. | Design per minigame: who controls what (thrower aims, the thrown one acts mid-air), sent as inputs like the battle menu so every game plays the same throw. Very complex (new mechanics on top of the game's own). Puzzles are simpler, though still work: share the puzzle's state (switches, blocks, tiles) so one player's move changes the room for everyone instead of only in their game. | L per minigame; M per puzzle type |

## Priority 4 — cosmetic

Done on 2026-11-22.

| Issue | What was done | Test |
|---|---|---|
| Party menu (C) always shows the story's party, not your character. | While the menu is open a "You: Susie" label shows in the bottom-right corner. | **Tested** (`openmenu` + screenshot). |
| Light World: characters without Light World sprites. | Susie now uses her Light World walking sprites (Chapter 2+). Ralsei has none, so his own sprites stay (as the TODO suggested). Kris never showed: that fallback only happened for sprites with no direction. | **Tested** (log of the drawn sprite: `spr_susie_walk_*_lw`). |
