# DELTARUNE Multiplayer — what is still open

Only open work is here; everything finished (and how it was tested) is in [`DONE.md`](DONE.md).
Effort: S = small, M = medium, L = large. Help is welcome: pick anything below, open an issue or a
pull request, or ask on Discord (**b.001**).

## Feel native: co-op as if DELTARUNE were made for it (user request, 2026-11-25), first

Rule for everything below: use the game's own menus, sounds and art. No extra overlays or yellow notes
on top of the game where the game itself can show it.

1. **Battle: everyone chooses at the same time, in DELTARUNE's own menu (L).** Each player picks their
   hero's action in the normal battle menu at once (no "Your turn" / "X is choosing for..." notes, no
   pre-select line). The turn starts when all have chosen; until then the hero who is ready shows its
   chosen-action icon, as the game does. Test with chaos:10:120:60.
   Look (user's screenshot, Berdly fight): every hero that has a player gets its panel raised with
   its own FIGHT/ACT/ITEM/SPARE/DEFEND row open at the same time (Kris and Noelle both up, not only
   Kris). Each player moves the cursor in their own hero's row and sees the others' cursors and
   sub-menus (enemy, ACT, item lists) move live in their panels. A hero with no player (or the
   solo party) works as now.
   **Part 1 done (2026-11-26, DONE.md):** panels up together, each lights its own choice, no turn
   notes, a ready choice plays by itself. **Part 2 done (2026-11-26, DONE.md):** the lists of a hero chosen ahead are in the battle's own
   bottom box. **Left:** the spell list doesn't show the spell's description and TP cost on the
   right as the game's does; the others' list cursor isn't seen live (only their main-row choice).
2. **Fewer yellow notes (M).** Go through the 72 mp_notify texts and remove the ones the game can show
   by itself (battle turn notes, waiting lines); keep only real errors and connection news.
3. **Bugs reported in play (2026-11-25):**
   - C menu does not open while playing another character (as Kris it opens: menuat test token).
   - The heart in the leaving animation keeps its original color instead of my character's.
   - Solo: the party still follows me. Solo should be really solo (this also fixes Kris looking
     Light World while Ralsei leads, so that one needs no fix of its own).
   - Starting a battle plays the hurt sound with nothing hitting me.
   - The map SOUL look (a player whose fight shows on the map) is a white blurred-looking outline over
     a normal sprite. The game's own (Kris) is a pixel-drawn outline and the hero goes dark. Do the
     same for every hero: darken the sprite, 1-pixel outline in the hero's colour instead of red
     (Susie purple, Ralsei green, Noelle yellow; Kris keeps the game's red). (mp_draw_ow_heart)

## Special fights: everyone plays their own hero (user request, 2026-11-25)

Today the fights below are "special" (`mp_battle_special`): the leader plays every hero, the others
watch. Each needs its own design. Rules from the user:
* **Shooting SOUL (yellow shots):** every player shoots. Things that must be destroyed by the yellow
  shots get more HP per active player (multiplied), not the boss's HP in general.
* **Green shield SOUL (defend in four directions):** each player defends on their own screen (the
  simplest; something more interactive would be nicer, no idea yet).
* **Fights meant for one hero (e.g. Sound of Justice, Spamton NEO's weird-route version):** the
  others play too (only watching is boring), with a note that it isn't canon: their text box is drawn
  in their hero's colour instead of white, and they get an entry line, e.g. Susie showing up in the
  weird-route Spamton fight: "Look who I found needing help".
* **SOUL colours:** yellow = like Spamton NEO (everyone shoots). Green = like Hammer of Justice (each
  defends on their own screen). Orange (Flowery) = for now each player has their own clash on their
  own screen, like green; improve later. Aqua and blue = not used in the game yet (objects exist,
  nothing to do). Pink/purple = Mew Mew's fight, the SOUL plays like a normal fight; the hard part is
  her choice event, not the SOUL.
* **Queen, Berdly's plug, the Knight:** on the special list only as a precaution (an early guess that
  they "likely only partly sync"), no known problem. The Knight synced turn 1 with 3 bot players
  (2026-11-22). Test each as a normal fight with 2 players and take it off the list if it works.
* **GigaQueen:** no good idea yet for making it fun with several players. Open.
* The rest: one design per fight, simplest that keeps the original's feel.

| Ch | Fight (enemy object) | Kind | Plan |
|---|---|---|---|
| 2 | Spamton NEO (`obj_spamton_neo_enemy`) | Yellow shooting SOUL, Susie's ACT, BIG SHOT | Everyone shoots; shot targets' HP x players |
| 2 | Queen (`obj_queen_enemy`) | Menu fight with her own pieces: the plug (`obj_queen_battle_plug`, Berdly plugged in), her shield (`obj_queenshield_enemy`), wine walls | Look at which part needs one player; likely everyone in the normal menu, plug/shield parts shared |
| 2 | GigaQueen (`obj_gigaqueen_enemy`) | Robot fight (punches, shield) | to design |
| 2 | Berdly plug (`obj_berdlyplug_enemy`) | Not a fight of its own: the plugged Berdly inside the Queen fight (driven by scene 25) | Goes with the Queen fight |
| 3 | Knight (`obj_knight_enemy`) | Sword tunnel | to design |
| 3 | Shadow Mantle (`obj_shadow_mantle_enemy`) | Real-time action boss on the game board (no menu): the board party walks, Kris swings the sword, bombs, fire, clones | Each player moves their own board piece and attacks; boss HP x players (as the shooting rule) |
| 3 | Tenna board 4 (`obj_tenna_board4_enemy`) | Menu fight on the last board, with a gacha (`obj_tenna_board4_gacha`) and Shadowman / Zapper enemies | Likely normal same-time menu; gacha played by the one who uses it, result shared |
| 4 | Hammer of Justice (`obj_hammer_of_justice_enemy`) | Green shield SOUL | Each defends on their own screen |
| 4 | Sound of Justice (`obj_sound_of_justice_enemy`) | Gerson's hidden fight: darkness overlay, Susie's heal shots (`obj_susie_heal_projectile`), spear shots | Darkness per screen; Susie's heal shots by Susie's player |
| 4 | Titan (`obj_titan_enemy`) | Final boss of Chapter 4: darkness, Titan heals (`obj_titan_heal`) | Look at which hero's actions are special |
| 5 | Coloured enemies (`obj_yellow/green/orange/aqua/blue/pink/purple_enemy`, `obj_orangeheart_enemy`, `obj_flowery_enemy`) | Fights with their own SOUL rules (yellow reticle, green cooking time, orange heart, a yellow trial manager); not in the special list today, so they run as normal shared fights | Play each with 2 players and check; add to the list the ones that break |

## Later: a stand-in when the hero a mechanic needs isn't there (user request, 2026-11-25)

Some fight mechanics need two specific heroes, e.g. Susie throwing Kris at the ropes holding the
captured NPCs (cutting a rope frees one). When the needed hero is missing (solo mode, or a boss
entered without the party), the hero who is there gets a stand-in action so the mechanic can still
be done: e.g. Susie alone cuts the ropes with Rude Buster.
Rules:
* The stand-in only appears when the needed hero is missing. It covers a gap; it never replaces the
  original when the full party is there.
* A solo stand-in is worse than the team version: it costs more TP or does less (e.g. frees fewer,
  takes more turns), so playing together stays the better way.
* It looks and sounds like the game's own actions (an existing spell or ACT in the normal menu).
Go through MINIGAMES.md for every mechanic that needs two specific heroes and pick one stand-in
for each, the simplest that keeps the original's feel.

## Next features (user request, 2026-11-24), in this order

1. **Done:** tests per chapter of joining mid-cutscene and coming back after a crash, see DONE.md.
2. **Done:** CONTRIBUTING.md, see DONE.md.
3. **Done:** F9 "Save logs for a bug report" (zip on the desktop), see DONE.md.
4. **Done:** quick messages, F9 "Say", see DONE.md.
5. **Done:** map ping (F5), see DONE.md. The edge arrow for a player off screen is seen now (DONE.md).
   F5 can't be the talk key any more (DONE.md).
6. **Done:** spectator jumps between players; "(reading)" in the player list, see DONE.md.
7. **Done:** clearer version check on joining (each side's build and network version), see DONE.md.

## More co-op improvements (found 2026-11-24, from MINIGAMES.md)

1. **Done:** ACTs that open their own little game are played by the hero's owner (DONE.md). Still to
   run with the real ACTs: the test simulates one (`fakeactg`).
2. **Done:** Chapter 4 bookshelf puzzle shared; the train tracks stay local on purpose (DONE.md).
   A real piano move was tried (2026-11-25, token `pianoplay`, DONE.md): Kris goes up, plays the piano
   and the keys reach it, but the shelf doesn't slide in any direction, in a room entered with the
   `party` token (two plain wall blocks, at 1160,1200 and 800,1240, already touch the blue shelf). Most likely
   the room needs to be entered the normal way. Re-check in play.
3. **Done:** the piano puzzle solved by one player is solved for everyone; the organ stays local on purpose
   (DONE.md). Not looked at yet: the piano pieces rooms (`obj_dw_church_pianopiece_left/right`).
4. **Done:** Chapter 5 castle puzzles (terracotta, orange door) follow a friend's solve (DONE.md).
   Chapter 4's piano pieces rooms were looked at again (2026-11-24): nothing to solve together.
   They are talks with Susie and Ralsei (the couch for Ralsei's room, story flags 865/866, scenes
   shared the usual way). The remote piano that writes flags 863-866 is only in
   `room_dw_church_bookshelfpuzzle1`, which has no shelves for it and no door from the story
   (a leftover room). Left as is.
6. **Done:** Chapter 2's mice switch room (`room_dw_city_mice2`) follows a friend's solve (DONE.md).
   Left local after a look: the first mice room (`room_dw_city_mice`: its solve is plot 72, already
   shared, and the room's switch reads the plot every frame) and the shape puzzle (one player steers).
7. **Done:** Chapter 3's couch-world eye puzzle: Kris's switch pressed by anyone opens the bridge in
   every game (DONE.md). The TV keyboard tiles are the TV quizzes' A/B answers: a friend's right
   answer now finishes my TV too (DONE.md). The puzzle closets (`obj_puzzlecloset_manager`,
   `room_dw_puzzlecloset_1..3`) were looked at: they are part of the Chapter 3 board (the camera,
   photos counted in flags 1228/1245, shared), so the board's handling covers them. Left as is.
5. **Done:** Chapter 2 keyboard puzzles follow a friend's solve (DONE.md). Simplest choice: the solve
   is shared, not each key. Puzzles 2 and 3 only checked by reading the code (same path as puzzle 1).

## Next puzzles to look at (found 2026-11-24, from MINIGAMES.md), one per cycle

For each: if the solve is a story flag read only when the room is built, the same "follow" as the
other puzzles (a friend's solve shows in my room); else note why it stays local.
1. **Looked at:** Chapter 2 pushable blocks: `obj_pushable_block` is in no Chapter 2 room (a leftover).
2. **Looked at:** Noelle's puzzle is the Noelle monologue scene (plot 94, shared): nothing to share.
3. **Done:** Chapter 2 post-baseball room's switch and teacup follow a friend's solve; found on the
   way, the room's controller no longer goes when a watched scene is stopped (DONE.md). Room 2's
   tiles stay each player's own (held by the party in a chase). The rotating tiles are only in the
   mice switch room (done). The "joined during my own scene" re-entry has run
   since (DONE.md).
4. **Done:** Chapter 4 ripple rooms: nothing to solve; a friend's steps make ripples in my game (DONE.md).
5. **Looked at:** Chapter 5 flower arena puzzle: `obj_flower_arena_puzzle_manager` is in no room.
6. **Done:** Chapter 5 new glowing tiles: a friend's solve during my run ends my copy properly
   (DONE.md). `obj_pushable_block_memory` is in no room.
7. **Done:** mazes looked at (MINIGAMES.md); the only block found, Chapter 2's second virus maze
   keeping its force fields up after a friend's win, is fixed (DONE.md).

## Rooms that read a solve flag only when built (found 2026-11-25, by a code sweep)

A sweep of every chapter's room controllers for a flag that the controller sets in its step but reads
only in its Create (so a friend's solve isn't seen until the room is entered again). Found, besides
the ones already done (mice room, post-baseball room, virus maze 2):
1. **Done:** Chapter 2 mansion saucer puzzles: the locked door (flag 344) and the shortcut
   bookcase (flag 346) follow a friend's solve (DONE.md).
2. Left as is: Chapter 2 `obj_cybercity_balloon_cheese` (flag 447): the flag only adds a force field
   on coming back, after the chase scene, which is shared the usual way.
3. **Done (wider sweep, 2026-11-25):** controllers that add or remove solid blocks on a flag read
   only in Create: about 70 hits, mostly story scenes and NPCs (their flags come from scenes, which
   are shared and played or watched by everyone). Done: the mansion secret walls (flags 339/340,
   DONE.md). Puzzle-like ones still to look at, one per cycle:
   * Chapter 2: **done:** the mouse tower (flag 379, DONE.md); **done:** `obj_controller_dining3`
     (381, the dining room door, DONE.md).
   * Chapter 3: **done:** the backstage extra puzzle's door (1112) and Susie's bridge (1212)
     (DONE.md). Left as is: `obj_dw_b3bs_zapper_a` (1135/1184: a scene and a dialogue choice,
     shared the usual way), `obj_dw_teevie_shuttahmaze` (1004/1005: a chest and a laugh scene),
     the extra puzzle's block place (1109/1110: only where the block is drawn on coming back).
   * Chapter 4: **done:** the side climb's shortcut spots (1524, DONE.md). Left as is:
     `obj_dw_church_arena` (851/852: a story fight and its scenes, shared the usual way), the side
     climb's Mizzle (1526: a scene).
   The sweep's list is finished.

## Stage-changing scenes: everyone agrees first (later)

Watching a cutscene and going back to where you were is done (DONE.md, 2026-11-24): a scene that ends
in another room or world takes everyone along. Only scenes that change the setting for good count (user, 2026-11-25): e.g. leaving the Dark World, where you can't go straight back. A scene that just moves to the next room does not. Later: a list of those stage-changing scenes (from the
story sweeps: scenes that end in another room); for them the scene stops at its first text box with
"P1 wants to move the story on: Z to agree (2/3)" and goes on when everyone agreed or the host forces it.
Not started (2026-11-24): a scene is known to change the stage only when it ends, so this needs the
list first (one sweep per chapter logging the scenes that end in another room, `mp_mirror_home` = -1).
Skipped by the loop until that list exists.

## Puzzles and map objects together (user request, 2026-11-23)

Simple things on the map are still local: pushing a box, pressing a switch, stepping on tiles, moving a
block only happens in the game of the player who did it, so a friend can't help solve anything (and
the two games can end up with different rooms). Goal: solve puzzles together, each player's move
changing the room for everyone.

* **Done: Chapter 1 pushable blocks** (`obj_pushableblock`, the box puzzle), see DONE.md.
* **Done: Chapter 1 switches and floor tiles** (eye switches, the hourglass tile puzzles), see DONE.md.
* **Done: the rest of Chapter 1** (suits puzzles shared; checker paths and the forest area 5 lines
  stay each player's own), see DONE.md.
* **Done: Chapter 2 traffic lights and the alley switch**, see DONE.md. Chapter 2 still local: the
  mice rooms' switches (they release mice that move on their own), the keyboard puzzles, the shape
  puzzle (one player steers a piece).
* **Done: Chapters 3-5** (Chapter 5 blocks, Chapters 4-5 floor switches, Chapter 3 glowing tiles),
  see DONE.md. Still local, one by one if they matter in play: Chapter 4's bookshelf
  (`obj_dw_church_bookshelfpuzzle`), piano, ripple and train-track puzzles; Chapter 5's castle puzzles
  (`obj_dw_fcastle_*_puzzle`, the terracotta one); Chapter 2's mice and keyboard puzzles.
* **Done:** a switch pressed before someone joined or came into the room: the eye switches and suits
  buttons are played back for them (DONE.md). The timed ones (traffic lights, hourglass) are not:
  their timer would start again.
* Two players pushing the same block at the same moment: today each game plays both pushes in the
  order it hears them (simplest; the games could disagree if one push is blocked in one game only).
  If it shows up in play: the host's order wins, the other push is undone.
* Effort: M per puzzle type.

## Spectating and Game Over (user request, 2026-11-23)

* **Done: watching a player on the map** (F9 "Watch", left/right to switch), see DONE.md. A player
  with nothing to play in fights (same character as someone who picked it first) is told once that
  F9 > Watch follows that player (DONE.md). Simplest choice: a hint, not watching on its own, since
  walking around as your pick still works.
* **Done: anyone's Continue at the Game Over continues for everyone**, see DONE.md. The CONTINUE
  choice on the second screen (`PLACE_FAILURE`) is run too now (DONE.md).

## Left from the code review (2026-11-23)

* Host change in a session with both Steam and IP players, and the old-lobby check (done 2026-11-24,
  see DONE.md): only the IP side could be run here. Re-test with two Steam accounts.
* Re-test the Steam session fixes with two real Steam accounts.

## Left from the code review (2026-11-24)

The loop's changes since the 2026-11-23 review were read again (mod/gml, core.hook, launcher; the
patcher didn't change). Fixed: a counter sent in the middle of the flag message (DONE.md). Not changed,
to check in play:
* **Done:** a watcher's character no longer touches things (see DONE.md).

## Needs information from a player

| Issue | What is needed |
|---|---|
| A player had no sound for a while; it came back by itself (report 7). | `multiplayer_log.txt` from that session. Possibly the game muted while unfocused, or a song started late. |

## Re-check in play

These were fixed or should be fixed by other changes, but only a real play-through can confirm it.

* Purple grass scene, a pulled player's sprite "stretched" (report 7): the user says it looked like a
  sprite copying itself in a cutscene, not stretching. Probably the mirror bug fixed 2026-11-23 (parts
  of different frames drawn together: a moving sprite shown again at its old places). Re-check in play.
* Cutscenes sometimes playing twice (report 7): mostly covered by the scene lock (stale or repeated
  pulls dropped, the same scene in two games watched instead of replayed).
* The Lancer chase and Ralsei's lore at the start of Chapter 1 (report 7).
* Report 4 (Chapter 1, Lancer fight after Ralsei's scene): Susie's HP bar drawn nearly empty while her
  HP reads 96/110; HP differing between players; both players dodging. Probably all from the old
  "two battles for one encounter" bug, fixed since; not reproduced separately.
* Priority 1 batch (2026-11-22): built and partly tested only; the Game Over wait for the host can't be
  tested with the test harness (no save to reload).
* Save points (a client's save makes the host save too): not testable here without touching real saves.
* Steam: two different Steam accounts actually playing, the friends list, and the host leaving over
  Steam (one account can't connect to itself).
* Chapter 5 platformer with real players (only bots so far).

## Special content (priority 3)

Every minigame, puzzle and ACT with its own game, chapter by chapter, with what co-op does with it
today and the idea for each: [`MINIGAMES.md`](MINIGAMES.md).

The large (L) items below were passed over by the autonomous loop (2026-11-24): each needs a design
choice and real players to judge it; the platformer figure and the special-fight fallback were done.

| Issue | Plan | Effort |
|---|---|---|
| Special battle styles: the fallback is done (DONE.md, 2026-11-24). Still to do: hand-sync single fights people care about, so everyone plays their hero there too; Chapter 5 bosses aren't on the list yet (not looked at). | Per fight, from the list in `mp_battle_special`. | L per fight |
| Minigames played together (each player now plays their own copy; the others are hidden and see "Playing ..."). | Per minigame. **Rhythm game:** each player plays their character's chart (the game has three: Kris guitar, Susie drums, Ralsei vocals; the last two are on autoplay), hits sent and the score added up. **Quiz / game show:** each player buzzes for their character. **Throw minigame:** Susie throws, Kris's player presses a button mid-air for a sword swing. Inputs sent like the battle menu so every game plays the same thing. | L per minigame |
|  | User's design (2026-11-25), rhythm game: each player plays their own hero's part of the song; Susie's part gets a real pattern of its own that plays the original sound (instead of her failing every note as in the solo game). Large. | |
| Chapter 5 platformer: hits, enemies and most pickups aren't shared (remembered coins, pinata bells, leaf piles and paper grass are, DONE.md 2026-11-25) (the per-character figure is done, DONE.md 2026-11-24; the game's own follower of a character a friend plays is hidden, DONE.md). | Shared pickups. | M |
|  | User (2026-11-25): **must be 100% before calling the mod finished.** Every player controls their own figure in the platformer (needs new platformer sprites for Susie, Ralsei, Noelle). | L |
| Separate fights: players left out of a fight (hero not in the story party, taken, or a 4th+ player) only watch. | Support for up to 5 players and a proper spectator role. | L |
| A player in a fight, seen from the map, only shows a battle stance. | User (2026-11-25): no need to show choosing and dodging. Keep the hero in their battle idle pose and draw the enemy (or enemies) of that fight standing in front of them. | M |
| The host as referee, next steps: NPC talk and battle start through the host (cutscene start already is: the scene lock). | See "The server layer idea" in DONE.md (report 7). | M |
|  | User (2026-11-25): when a player talks to an NPC with other players in the room, everyone in the room hears the NPC (the text box shows for all, not only a bubble). | M |

## Not looked at yet

* More `interact` cases: save point (Chapter 4), a Chapter 5 shop and a Chapter 4 readable checked
  (DONE.md). Other NPCs can be run with the `touch:<obj>@<f>` token when one misbehaves in play.
* Tests don't cover yet: Chapter 1 new game (the vessel creation writes save files, so it isn't run here;
  Chapter 1 is tested by loading a save), more cutscenes started with Z (the arcade scene and a Chapter 1 chat that moves the story tested), a real play-through of
  whole chapters. Platforming with running and jumping is tested (DONE.md).

## Low priority / known small differences

* Snowgrave route (Chapter 2): untested. It relies on Noelle-specific battle flow and flags, so expect
  oddities if players disagree. Possible fix: route choices follow whoever plays Noelle (or the host). Not testable here: the bots
  can't play the chain of Noelle choices it needs (2026-11-24).

## Out of scope for now

* A relay server of our own: Steam play (lobby codes) already removes the need for port forwarding.
  Playing over IP still needs UDP 26510 forwarded, or a virtual network (Radmin VPN, ZeroTier, Tailscale).
