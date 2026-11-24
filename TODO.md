# DELTARUNE Multiplayer — what is still open

Only open work is here; everything finished (and how it was tested) is in [`DONE.md`](DONE.md).
Effort: S = small, M = medium, L = large. Help is welcome: pick anything below, open an issue or a
pull request, or ask on Discord (**b.001**).

## Stage-changing scenes: everyone agrees first (later)

Watching a cutscene and going back to where you were is done (DONE.md, 2026-11-24): a scene that ends
in another room or world takes everyone along. Later: a list of those stage-changing scenes (from the
story sweeps: scenes that end in another room); for them the scene stops at its first text box with
"P1 wants to move the story on: Z to agree (2/3)" and goes on when everyone agreed or the host forces it.

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
* A switch pressed before another player connected isn't known to them (switches have no lasting
  state to send; blocks are sent to newcomers since 2026-11-24).
* Two players pushing the same block at the same moment: today each game plays both pushes in the
  order it hears them (simplest; the games could disagree if one push is blocked in one game only).
  If it shows up in play: the host's order wins, the other push is undone.
* Effort: M per puzzle type.

## Spectating and Game Over (user request, 2026-11-23)

* **Done: watching a player on the map** (F9 "Watch", left/right to switch), see DONE.md. Still to do:
  switching to watching automatically for a player who has nothing to play (same character as another
  player, a 4th+ player).
* **Done: anyone's Continue at the Game Over continues for everyone**, see DONE.md. Not run: the
  CONTINUE choice on the second screen (`PLACE_FAILURE`), only the quick retry.

## Left from the code review (2026-11-23)

* Host change in a session with both Steam and IP players, and the old-lobby check (done 2026-11-24,
  see DONE.md): only the IP side could be run here. Re-test with two Steam accounts.
* Re-test the Steam session fixes with two real Steam accounts.

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

The large (L) items below were passed over by the autonomous loop (2026-11-24): each needs a design
choice and real players to judge it; the platformer figure and the special-fight fallback were done.

| Issue | Plan | Effort |
|---|---|---|
| Special battle styles: the fallback is done (DONE.md, 2026-11-24). Still to do: hand-sync single fights people care about, so everyone plays their hero there too; Chapter 5 bosses aren't on the list yet (not looked at). | Per fight, from the list in `mp_battle_special`. | L per fight |
| Minigames played together (each player now plays their own copy; the others are hidden and see "Playing ..."). | Per minigame. **Rhythm game:** each player plays their character's chart (the game has three: Kris guitar, Susie drums, Ralsei vocals; the last two are on autoplay), hits sent and the score added up. **Quiz / game show:** each player buzzes for their character. **Throw minigame:** Susie throws, Kris's player presses a button mid-air for a sword swing. Inputs sent like the battle menu so every game plays the same thing. | L per minigame |
| Chapter 5 platformer: hits, enemies and pickups aren't shared (the per-character figure is done, DONE.md 2026-11-24). Small: a player who plays Susie or Ralsei is drawn next to the game's own Susie/Ralsei follower in the others' games (two of them). | Shared pickups; maybe hide the game's follower of a character another player plays. | M |
| Separate fights: players left out of a fight (hero not in the story party, taken, or a 4th+ player) only watch. | Support for up to 5 players and a proper spectator role. | L |
| A player in a fight, seen from the map, only shows a battle stance. | Show them choosing and dodging. | L |
| The host as referee, next steps: NPC talk and battle start through the host (cutscene start already is: the scene lock). | See "The server layer idea" in DONE.md (report 7). | M |

## Not looked at yet

* Story fight in `room_dw_garden_aqua` 291 (chaos, `work/fol/aqua9`, `aqua10`): the pulled player lands at the
  leader's spot (302,258) and on the next frame its game goes through a door to
  `room_dw_garden_wateringcan_aqua` (`interact 0->3` at room frame 2), so it never reaches the fight; the
  leader fights alone. Seen in 2 of 4 runs; not in `aqua7`/`aqua8`. Maybe the room's own scene starting in
  the pulled game, or a door trigger at that spot.
* More `interact` cases: save point checked (Chapter 4, DONE.md); shops and NPCs in Chapters 3-5 can now be
  run with the `touch:<obj>@<f>` token when it matters.
* Tests don't cover yet: Chapter 1 new game (the vessel creation writes save files, so it isn't run here;
  Chapter 1 is tested by loading a save), more cutscenes started with Z (one tested), a real play-through of
  whole chapters. Platforming with running and jumping is tested (DONE.md).

## Low priority / known small differences

* On a bad network a player standing still can be missing from the others' screens for up to 1.5 s
  when they arrive (their first position lost; positions of someone not moving are only resent every
  1.5 s). Seen in the suits puzzle test with `chaos:10:120:60`.

* Snowgrave route (Chapter 2): untested. It relies on Noelle-specific battle flow and flags, so expect
  oddities if players disagree. Possible fix: route choices follow whoever plays Noelle (or the host).
* Light World Ralsei/Noelle have no Light World walk sprites; they use their Dark World ones.
* Per-player statistics stored as story flags (Chapter 5 "slashes" count) keep the last writer's value
  instead of adding up.
* Chapter 1: a following player plays a room's song at full volume (some rooms start it at 0.7).

## Out of scope for now

* A relay server of our own: Steam play (lobby codes) already removes the need for port forwarding.
  Playing over IP still needs UDP 26510 forwarded, or a virtual network (Radmin VPN, ZeroTier, Tailscale).
