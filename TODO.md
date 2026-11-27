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
   notes, a ready choice plays by itself. **Parts 2 and 3 done (2026-11-26, DONE.md):** the lists of a hero chosen ahead are in the battle's
   own bottom box, spells with their description and TP cost like the game's.
   **Done (2026-11-26, DONE.md):** what a player chose ahead shows to the others (arrow over the
   enemy, the spell/ACT/item name rising in their panel).
   **Done (2026-11-26, DONE.md):** Chapter 3's sword route, the players' heroes stand at the TV
   beside Kris (back views; a "holding the controller" back pose is in SPRITES.md).
   **Next (user, 2026-11-26):** a hero who isn't in a fight leaves no prop behind: remove what belongs
   to them instead of a stand-in sprite. Berdly's coaster: done (DONE.md). **Question:** "the ball
   in the Tenna fight": which ball is it (which Tenna fight, which turn or ACT, whose ball)? Not found
   in the code by name. ACTs changed for co-op are listed in ACTS.md (to give versions with Noelle,
   later Berdly).
2. **Done (2026-11-26):** fewer notes, see DONE.md. Kept on purpose: connection and error news,
   waiting lines (who a fight waits for), the spectator line in a fight you only watch, scene
   choices, quick messages from others, the one-time "Story cutscenes show the party" hint.
3. **Bugs reported in play (2026-11-25):** done or moved to "Needs information" (hurt sound), see DONE.md.

## Special fights: everyone plays their own hero (user request, 2026-11-25)

Spamton NEO: done 2026-11-26 (DONE.md), a normal fight where everyone shoots on their own screen.
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
  How it plays (user, corrected 2026-11-26): a normal fight together (same-time menu, shared
  enemy, the enemy with more HP for more players). Dodging on separate screens is only for the green
  and orange SOULs (Hammer of Justice style shields, Flowery's clash), not for these fights.
* **SOUL colours:** yellow = like Spamton NEO (everyone shoots). Green = like Hammer of Justice (each
  defends on their own screen). Orange (Flowery) = for now each player has their own clash on their
  own screen, like green; improve later. Aqua and blue = not used in the game yet (objects exist,
  nothing to do). Pink/purple = Mew Mew's fight, the SOUL plays like a normal fight; the hard part is
  her choice event, not the SOUL.
* **Queen, Berdly's plug, the Knight:** done 2026-11-26, now normal fights (DONE.md). Berdly's plug
  (scene 25 inside the Queen fight) is still to see in play.
* **GigaQueen:** no good idea yet for making it fun with several players. Open.
* The rest: one design per fight, simplest that keeps the original's feel.

| Ch | Fight (enemy object) | Kind | Plan |
|---|---|---|---|
| 2 | GigaQueen (`obj_gigaqueen_enemy`) | Robot fight (punches, shield) | to design |
| 3 | Shadow Mantle (`obj_shadow_mantle_enemy`) | Real-time action boss on the game board | **Parts 1-2 done 2026-11-26 (DONE.md):** everyone fights their own copy, boss HP x players (hits shared), a friend's hit can win the fight; a loss sends both back to the sword intro. Done: each plays their own outro, the copies' HP follow the first player's (DONE.md). A loss with 2 players: both back at the sword intro, free to walk to the console (DONE.md). Retries done (DONE.md) |
| 4 | Hammer of Justice (`obj_hammer_of_justice_enemy`) | Green shield SOUL; made for Susie alone (the game sets the party to her) | **Part 1 done 2026-11-26 (DONE.md):** the players' heroes join Susie, a normal fight (each plays their hero, same-time menu); turns go on together. Done: a loss is shared (Susie falling plays Gerson's loss scene in every game, DONE.md). Not checked in the harness: the story after the loss (the test starts the fight by itself, so the host's screen stays on the scene's white fade); `sturdy` doesn't hold this fight's damage. Done: the "not canon" look (each joining hero's entry line in a balloon in their colour, DONE.md); the joining heroes now stand beside Susie (they were off screen). **Question for the user:** the entry lines are placeholders I chose (Kris "...!", Susie "Look who showed up to help!", Ralsei "We'll face this together!", Noelle "I-I'm here too! ...Let's do this!"), same for every one-hero fight; other words, or one set per fight? Done: Gerson's HP times the heroes (DONE.md). Seen, open: this fight ends by its own "progress" (each hero's hit on Gerson adds to it, as do the turns), not by HP, so with more heroes it reaches its end sooner; to look at in play before changing it. Also open: right after a loss in the test, the client doesn't show the host for half a second while it rebuilds the room (the test starts the fight without the story's scene) |
| 4 | Sound of Justice (`obj_sound_of_justice_enemy`) | Gerson's hidden fight: darkness overlay, Susie's heal shots (`obj_susie_heal_projectile`), spear shots | **Phases 1 and 2 done 2026-11-26 (DONE.md):** a one-hero fight like the Hammer of Justice (players' heroes join, entry lines in phase 1, HP times the extra heroes; each has their own darkness and SOUL). Open: phase 2's turn 0 shows phase 1's TP in the host's game only (the game keeps it in the room's `savetension`; the client's game rebuilds the room and has 0; the same from turn 1 on); Susie's heal shots by Susie's player not checked in play |

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
* Every combination gets one (user, 2026-11-26): each solo hero (Kris alone, Susie alone, Ralsei
  alone, Noelle alone) and each duo without the needed hero. Cost ladder: the original (full team)
  is cheapest; a duo stand-in costs more; a solo stand-in costs the most. Example, Queen's Throw:
  Kris + Susie (+ anyone) = Kris's Throw, free; Susie + Ralsei = Susie throws Ralsei, 20% TP (done);
  Kris + Ralsei, Susie alone, Kris alone, Ralsei alone: to do, 40% TP for solos (poses needed:
  SPRITES.md).
* Minigames: the best result is always a shared one (everyone in the same game); separate copies
  only where sharing turns out impossible.
Done (2026-11-26, DONE.md): team ACTs that only need the others' turns work without them, in every
chapter (`tools/actsolo.py`: 22 found, plus the last board's). Open: the ~190 team ACTs whose code
uses the helper (e.g. Sharpshoot, Rabbick's Warning): each needs its own stand-in, per the rules above.
**Question for the user (2026-11-26):** today the game itself greys these ACTs out when their helper
is missing (its own rule, nothing breaks). For the ~184, a stand-in each by hand is a lot of new
text and poses. Simplest general idea: "Improvise" in place of the greyed ACT, the same mercy as the
original, the duo/solo TP cost, and one line like "* Kris improvised a Compliment!". OK as the
general rule (then a few special ones by hand), or one written stand-in per ACT?
Name (user idea, 2026-11-26): every stand-in ACT is called **Improvise** in the hero's own ACT list;
its menu description says what it does (e.g. "Throw#Ralsei"). One word players learn: "this is the
stand-in because someone is missing".
Done (2026-11-26, DONE.md): Queen with Berdly plugged in, no Kris: Susie's Improvise throws Ralsei at
the wires (20% TP). The throw is sent as angle + power (Susie's player throws), Kris's Throw too.
Open: once in 6 test runs the client's game refused the host's replayed Z on Susie's MAGIC list at
turn 1 (stuck on that list; host went on): looks like the menu replay, not the throw; cause not found.
Done (2026-11-26, DONE.md): Werewire's ThrowWire without Kris: Susie's Improvise throws Ralsei
(20% TP); the throw is now the same in every game. Open for it: Kris alone, Susie alone, Ralsei alone.
Where a stand-in needs a pose the game doesn't have, it goes in SPRITES.md (situation, why, how it
would look) for the user to look for.
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

1. **Done:** ACTs that open their own little game are played by the hero's owner (DONE.md). Run with
   a real one (Maus' TrapOne, 2026-11-26, DONE.md): the basket now drops at the same place in every
   game. Looked at the others (2026-11-26, MINIGAMES.md): Tasque Manager's quiz is an attack (each dodges
   their own), Tenna's "popular boy" has no input; Chapter 5's scissors are steered with held keys
   (replayed, a little later; mercy corrected), not run. Seen in the test, open: when two games start the same fight on their own in the same frame
   as one pulls the other in, the pulled game rebuilt the fight after turn 0 and stayed waiting (the
   test gave both games `battle:54`; with only the host starting it, no stall in 2 runs).
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
| C menu didn't open while playing Ralsei (Chapter 1, `room_field_checkers6`, hosting on Steam alone, 2026-11-25). Not reproduced: the same room, plot and character with the `menuat` token opens the menu (interact 5, screenshot of the ITEM page), and the key config has C. | F9 "Save logs for a bug report" right after it happens again, and whether a gamepad was used. |
| Hurt sound at the start of a battle with nothing hitting (2026-11-25). Not reproduced: 2-player fights in Chapters 1 and 2 (`battle:13`, `battle:53`, client with `chaos:10:120:60`) play no hurt or damage sound before the attacks and bullets. Every `snd_hurt1`/`snd_damage` now goes into `multiplayer_log.txt` as "sound <name> by <object>". | `multiplayer_log.txt` (F9 "Save logs for a bug report") from a session where it happens, and which chapter/enemy. |
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
| Special battle styles: the fallback is done (DONE.md, 2026-11-24). Hand-synced since: Spamton NEO, Shadow Mantle, Queen, Berdly, the Knight, Titan, Hammer and Sound of Justice; Chapter 5's bosses (aqua ... Flowery) checked as normal fights (DONE.md, 2026-11-26). Only Giga Queen is left on the list (no design idea yet). | Per fight, from the list in `mp_battle_special`. | waits for Giga Queen's design |
| Minigames played together (each player now plays their own copy; the others are hidden and see "Playing ..."). | Per minigame. **Rhythm game:** each player plays their character's chart (the game has three: Kris guitar, Susie drums, Ralsei vocals; the last two are on autoplay), hits sent and the score added up. **Quiz / game show:** each player buzzes for their character. **Throw minigame:** Susie throws, Kris's player presses a button mid-air for a sword swing. Inputs sent like the battle menu so every game plays the same thing. | L per minigame |
|  | User's design (2026-11-25), rhythm game: each player plays their own hero's part of the song; Susie's part gets a real pattern of its own that plays the original sound (instead of her failing every note as in the solo game). Large. | |
| Chapter 5 platformer: hits, enemies and most pickups aren't shared (remembered coins, pinata bells, leaf piles and paper grass are, DONE.md 2026-11-25) (the per-character figure is done, DONE.md 2026-11-24; the game's own follower of a character a friend plays is hidden, DONE.md). | Shared pickups. | M |
|  | User (2026-11-25): **must be 100% before calling the mod finished.** Every player controls their own figure in the platformer (needs new platformer sprites for Susie, Ralsei, Noelle). | L |
| Separate fights: players left out of a fight (hero not in the story party, taken, or a 4th+ player) only watch. | Support for up to 5 players and a proper spectator role. | L |
| **Done (2026-11-26, DONE.md):** a player in a fight, seen from the map: their hero's battle stance with the fight's enemies standing in front of them. | User (2026-11-25): no need to show choosing and dodging. | done |
| The host as referee, next steps: NPC talk and battle start through the host (cutscene start already is: the scene lock). | See "The server layer idea" in DONE.md (report 7). | M |
|  | **Done (2026-11-26, DONE.md):** a player talking to an NPC: everyone in the room sees the text in the game's own text box. The portrait and the typing voice too (DONE.md). | done |

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
