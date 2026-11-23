# DELTARUNE Multiplayer — what is still open

Only open work is here; everything finished (and how it was tested) is in [`DONE.md`](DONE.md).
Effort: S = small, M = medium, L = large. Help is welcome: pick anything below, open an issue or a
pull request, or ask on Discord (**b.001**).

## Next up: the opening and joining mid-story (user idea, 2026-11-23)

Today each player goes through Chapter 1's opening (the vessel creation, `DEVICE_*` objects in
`PLACE_*` rooms) on their own; a client already in the game waits for the host, a client still in the
opening joins the host only after finishing its own. The story's position is already the host's
(flags, plot, party: host authoritative, drift check), and a joiner goes to the host and is pulled
into the host's running cutscene, but joining mid-cutscene has never been tested.

Plan:
1. The opening belongs to the host: a client in the opening while the host is past it skips straight
   to the host (file name = its player name); a client in the opening while the host is still in it
   waits on a "Host is creating the vessel..." screen instead of making its own. (Mirroring the
   vessel screens themselves isn't possible with the cutscene mirror: they are drawn text and shapes,
   not sprites.)
2. A `joinat:<frame>` test token (a client that connects late) and tests for joining in the middle of a
   cutscene, in every chapter: the joiner must land in the host's scene at the same page.
3. If a player's game crashes or disconnects mid-scene, reconnecting does the same (resume already
   reconnects within 15 minutes).

## Needs information from a player

| Issue | What is needed |
|---|---|
| Purple grass scene: a pulled player's sprite is stretched (report 7). | Which room / moment: a screenshot or `multiplayer_log.txt`. |
| A player had no sound for a while; it came back by itself (report 7). | `multiplayer_log.txt` from that session. Possibly the game muted while unfocused, or a song started late. |

## Re-check in play

These were fixed or should be fixed by other changes, but only a real play-through can confirm it.

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

| Issue | Plan | Effort |
|---|---|---|
| Special battle styles (Spamton NEO, Berdly/Queen, Chapter 4/5 gimmick fights) likely only partly sync. | Detect special battles and fall back to "one player drives the battle, everyone else spectates and dodges". Later, hand-sync individual fights people care about. | S–M fallback; L per fight |
| Minigames played together (each player now plays their own copy; the others are hidden and see "Playing ..."). | Per minigame. **Rhythm game:** each player plays their character's chart (the game has three: Kris guitar, Susie drums, Ralsei vocals; the last two are on autoplay), hits sent and the score added up. **Quiz / game show:** each player buzzes for their character. **Throw minigame:** Susie throws, Kris's player presses a button mid-air for a sword swing. Inputs sent like the battle menu so every game plays the same thing. | L per minigame |
| Puzzles shared: one player's move changes the room for everyone. | Share the puzzle's state (switches, blocks, tiles) per puzzle type, instead of each player solving their own copy. | M per puzzle type |
| Chapter 5 platformer: everyone is drawn as Kris there; hits, enemies and pickups aren't shared. | A per-character platformer figure (like climbing), then shared pickups. | M |
| Separate fights: players left out of a fight (hero not in the story party, taken, or a 4th+ player) only watch. | Support for up to 5 players and a proper spectator role. | L |
| A player in a fight, seen from the map, only shows a battle stance. | Show them choosing and dodging. | L |
| The host as referee, next steps: NPC talk and battle start through the host (cutscene start already is: the scene lock). | See "The server layer idea" in DONE.md (report 7). | M |

## Not looked at yet

* Chapter 4 `room_lw_church_main`, plot 289: `obj_ch4_DCB03` Step, "Variable obj_ch4_DCB03.su... not
  set" (2 players, sweep of 2026-10-10). May be gone since; not re-run.
* Ghost mismatches around doors at the top of town rooms (`room_library`, `room_diner`,
  `room_town_church`, `room_town_noellehouse`, `room_board_dungeon_3`): the other player sees a stale
  position for 2-4 s when someone is moved onto a door trigger (sweep of 2026-10-10).
* Changing character mid-session through F9 (picking it before joining, at the file select or in game,
  is covered by `tools/flow.py`).
* Joining while the host is in a cutscene or battle (joining from the file select is covered).
* Rooms where the game hides or repositions followers (Light World followers in Chapter 4 are covered).
* More `interact` cases in later chapters (save points, shops, the C menu are Z-triggered and local;
  unprompted text boxes only pull after 4 s).
* Tests don't cover yet: Chapter 1 new game (the vessel creation; Chapter 1 is tested by loading a
  save), joining mid-cutscene, cutscenes started with Z, platforming beyond standing in the room, a
  real play-through of whole chapters.

## Low priority / known small differences

* Snowgrave route (Chapter 2): untested. It relies on Noelle-specific battle flow and flags, so expect
  oddities if players disagree. Possible fix: route choices follow whoever plays Noelle (or the host).
* Light World Ralsei/Noelle have no Light World walk sprites; they use their Dark World ones.
* Per-player statistics stored as story flags (Chapter 5 "slashes" count) keep the last writer's value
  instead of adding up.
* Chapter 1: a following player plays a room's song at full volume (some rooms start it at 0.7).

## Out of scope for now

* A relay server of our own: Steam play (lobby codes) already removes the need for port forwarding.
  Playing over IP still needs UDP 26510 forwarded, or a virtual network (Radmin VPN, ZeroTier, Tailscale).
