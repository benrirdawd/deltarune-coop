# DELTARUNE Multiplayer — what is still open

Only open work is here; everything finished (and how it was tested) is in [`DONE.md`](DONE.md).
Effort: S = small, M = medium, L = large. Help is welcome: pick anything below, open an issue or a
pull request, or ask on Discord (**b.001**).

## Next features (user request, 2026-11-24), in this order

1. **Done:** tests per chapter of joining mid-cutscene and coming back after a crash, see DONE.md.
2. **Done:** CONTRIBUTING.md, see DONE.md.
3. **Done:** F9 "Save logs for a bug report" (zip on the desktop), see DONE.md.
4. **Done:** quick messages, F9 "Say", see DONE.md.
5. **Done:** map ping (F5), see DONE.md. Not seen yet on screen: the arrow at the screen's edge for
   a player who is off screen (the same drawing, turned); and if someone sets the voice talk key to F5,
   pressing it also pings.
6. **Done:** spectator jumps between players; "(reading)" in the player list, see DONE.md.
7. **Done:** clearer version check on joining (each side's build and network version), see DONE.md.

## More co-op improvements (found 2026-11-24, from MINIGAMES.md)

1. **Done:** ACTs that open their own little game are played by the hero's owner (DONE.md). Still to
   run with the real ACTs: the test simulates one (`fakeactg`).
2. **Done:** Chapter 4 bookshelf puzzle shared; the train tracks stay local on purpose (DONE.md).
   Still to run: a real piano move (the test sets the shelf's flag instead).
3. **Done:** the piano puzzle solved by one player is solved for everyone; the organ stays local on purpose
   (DONE.md). Not looked at yet: the piano pieces rooms (`obj_dw_church_pianopiece_left/right`).

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
| Chapter 5 platformer: hits, enemies and pickups aren't shared (the per-character figure is done, DONE.md 2026-11-24). Small: a player who plays Susie or Ralsei is drawn next to the game's own Susie/Ralsei follower in the others' games (two of them). | Shared pickups; maybe hide the game's follower of a character another player plays. | M |
| Separate fights: players left out of a fight (hero not in the story party, taken, or a 4th+ player) only watch. | Support for up to 5 players and a proper spectator role. | L |
| A player in a fight, seen from the map, only shows a battle stance. | Show them choosing and dodging. | L |
| The host as referee, next steps: NPC talk and battle start through the host (cutscene start already is: the scene lock). | See "The server layer idea" in DONE.md (report 7). | M |

## Not looked at yet

* More `interact` cases: save point checked (Chapter 4, DONE.md); shops and NPCs in Chapters 3-5 can now be
  run with the `touch:<obj>@<f>` token when it matters.
* Tests don't cover yet: Chapter 1 new game (the vessel creation writes save files, so it isn't run here;
  Chapter 1 is tested by loading a save), more cutscenes started with Z (one tested), a real play-through of
  whole chapters. Platforming with running and jumping is tested (DONE.md).

## Low priority / known small differences

* Snowgrave route (Chapter 2): untested. It relies on Noelle-specific battle flow and flags, so expect
  oddities if players disagree. Possible fix: route choices follow whoever plays Noelle (or the host). Not testable here: the bots
  can't play the chain of Noelle choices it needs (2026-11-24).

## Out of scope for now

* A relay server of our own: Steam play (lobby codes) already removes the need for port forwarding.
  Playing over IP still needs UDP 26510 forwarded, or a virtual network (Radmin VPN, ZeroTier, Tailscale).
