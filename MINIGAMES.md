# Minigames, puzzles and special ACTs: what co-op does with each

Every minigame, puzzle and ACT with its own game in the five chapters, what the mod does with it
today, and the idea for doing it together. Taken from each chapter's code (`work/chN/AllCode`, object
names) and from the mod (`mod/gml`, `mod/hooks/core.hook`) on 2026-11-24. Open work for these is
also in [`TODO.md`](TODO.md); how the finished parts were tested is in [`DONE.md`](DONE.md).

Status:

* **Shared**: one player's move changes it in every game in the room.
* **Own copy**: each player plays it in their own game. The others' figures are hidden over it, and
  they see "Playing ..." over the player and next to their name (`mp_minigame_name`, `scr_mp_sync`).
* **Local**: nothing special. It plays in the game of whoever does it; the others don't see the change.
* **Local on purpose**: a decision, with the reason given.
* **One plays**: special fights. The fight's leader plays every hero and the others watch
  (`mp_battle_special`, `scr_mp_battle`).

Where it says "idea", nothing is built yet.

## Battle ACTs and SOUL modes with their own game

How battles work: the menu is played by the owner of the hero whose turn it is, and their presses are
replayed in every game. Attack timing is pressed by each player for their own hero. Bullets are dodged
by everyone with their own SOUL. **ACTs that open their own little game** (the objects in
`mp_actg_objs`, `scr_mp_battle`, 2026-11-24) are played by the acting hero's owner: their keys are
replayed in the other games, and the mercy it gave is corrected everywhere to the owner's result.
"Replayed" in the table below means it is on that list (tested with a simulated ACT, not yet with
each real one).

| Ch | ACT / mode | Objects | Today | Idea |
|---|---|---|---|---|
| 2 | Tasque Manager's quiz | `obj_tm_quizzler` (from her fight) | Replayed (owner plays) | The ACT's owner answers and their presses are replayed, like the menu. Or each player answers and the majority wins. |
| 2 | Maus / Mauswheel baskets (Susie's version too) | `obj_maus_basket`, `obj_maus_basket_susie`, `obj_maus_split_basket` | Replayed (owner plays) | Replay the owner's keys. Susie's basket could be played by Susie's player. |
| 2 | Spamton NEO: Susie's ACT, BIG SHOT | `obj_sneo_susie_act`, `obj_sneo_bigshot` | One plays (special fight) | Hand-sync this fight: Susie's player does her ACT, Kris's player does BIG SHOT. |
| 2 | Giga Queen (boxing) | `obj_gigaqueen_enemy`, `obj_rocketpunch_*` | One plays | Idea: one player per punch hand, or take turns. L. |
| 2 | Queen, Berdly's plug | `obj_queen_enemy`, `obj_berdlyplug_enemy` | One plays | One at a time, if people want it. |
| 3 | Tenna's fight: the "popular boy" ACT | `obj_popularboy_act` (from `obj_tenna_enemy`) | Replayed (owner plays) | Replay the owner's keys. |
| 3 | Shadowguys' tommy gun (shooting SOUL) | `obj_shadowman_tommygun` (enemy turn) | Each player plays with their own SOUL, like dodging | Check that damage dealt to the enemies is shared. |
| 3 | The Knight's sword tunnel | `obj_sword_tunnel_*` (enemy turn) | One plays (the Knight is a special fight) | — |
| 3 | Shadow Mantle, Tenna's board fight | `obj_shadow_mantle_enemy`, `obj_tenna_board4_enemy` | One plays | — |
| 4 | Holy water ACT line | `obj_holywater_act_line` (enemy turn) | Each player with their own SOUL | Check that the result is shared. |
| 4 | Organ enemy | `obj_organ_enemy` | Normal fight sync | Check in play. |
| 4 | Titan, Gerson (Hammer and Sound of Justice) | `obj_titan_enemy`, `obj_hammer_of_justice_enemy`, `obj_sound_of_justice_enemy` | One plays | — |
| 5 | Flowery's ACT menu (a SOUL picks the ACT) | `obj_flowery_act_menu_*` | Replayed (owner plays) | Replay the owner's SOUL movement and presses, as the menu is replayed. |
| 5 | Scissors ACT (cutting a line) | `obj_scissors_act_*` | Replayed (owner plays) | The same: the owner plays, everyone sees it. |
| 5 | Sharing food (pink enemy) | `obj_sharefood_act` | Replayed (owner plays) | The same. Or each player gives food to their own hero. |
| 5 | Pink nodes (heart ACT) | `obj_pinknodeact`, `obj_dokiheart` | Replayed (owner plays) | The same. |
| 5 | Shooting SOUL modes | `obj_kawkaw_shooter`, `obj_flowery_shooter` | Each player with their own SOUL | Check that damage is shared. |
| 5 | Bosses | — | Not looked at yet | Add any that have their own rules to the special list. |

## Minigames outside battles

| Ch | Minigame | Objects | Today | Idea |
|---|---|---|---|---|
| 2 | Dog car | `obj_dogcar_controller` (touching the dog car) | Local | Idea: one drives and the others ride along (mirror). |
| 2 | Car adventure | `obj_caradventure_*` | Local | One drives and the others watch. |
| 2 | Berdly's coaster | `obj_berdlycoaster_event`, `obj_coaster` | Cutscene: one game plays it and the others mirror it | — |
| 3 | The board game | `obj_board_*`, `gml/ch3/scr_mp_board` | Own copy, with board pieces drawn as each player's character and other players' pieces shown on the same board screen | Shared board: one board, each player moves their own piece, with shared items and points. L. |
| 3 | Rhythm game | `obj_rhythmgame` (also in Chapters 4-5) | Own copy | Each player plays their character's chart (the game has three: Kris guitar, Susie drums, Ralsei vocals). Hits are sent and the score is added up. L. |
| 3 | Cooking game (chefs) | `obj_chefs_game`, `obj_chefs_kris/susie/ralsei` | Own copy | Each player is their character in the kitchen, with orders shared. L. |
| 3 | Quiz / game show (with its shooter) | `obj_quizsequence`, `obj_dw_ch3_teevie_quiz_controller`, `obj_dw_ch3_teevie_shooter` | Own copy | Each player buzzes in for their character, and the first one right scores. |
| 3 | Green room race | `obj_ch3_green_room_racing_game` | Own copy | Idea: a real race, with the others drawn as racers. |
| 3 | Susiezilla | `obj_susiezilla_gamecontroller` | Own copy | Susie's player plays and the others watch. Or a 2-player mode, if there is room for it. |
| 3 | TV mazes and puzzle closets | `obj_dw_teevie_maze`, `obj_dw_teevie_lightmaze`, `obj_dw_teevie_shuttahmaze`, `obj_puzzlecloset_*` | Local | Look at them one by one (see the puzzles below). |
| 4 | Mike's game | `obj_mike_minigame_controller` | Own copy | Idea: each player controls a cat or a paw. L. |
| 4 | Gerson's shell pinball | `obj_gerson_shell_pinball` | Own copy | One plays and the others watch. Or two flippers, one per player. |
| 4 | Treat catcher (Light World, at home) | `obj_homealone_treat_catcher` | Local | Low priority: a solo part of the story. |
| 4 | Dog car (Chapter 4) | `obj_dogcar_ch4` | Local | As in Chapter 2. |
| 4-5 | Climbing | `obj_climb*` | Shared: each player climbs as their own character and sees the others on the wall | — |
| 5 | Platforming sections | `obj_plat_game`, `gml/ch5/scr_mp_plat` | Each player plays as their own character and sees the others; a remembered coin (pink, counted), pinata bell, leaf pile or paper grass a friend took is gone for everyone | Hits, enemies and the other pickups are not shared yet (TODO). M. |
| 5 | Rhythm game (Jackenstein's song) | `obj_rhythmgame_jackenstein_events` | Own copy | Same idea as the Chapter 3 rhythm game. |
| 5 | Mike's TV rooms | `obj_room_castle_tv_mike*` | Own copy (Mike's game) | — |
| 5 | Castle front race | `obj_room_castle_front_race` | Own copy | Same idea as the Chapter 3 race. |
| 5 | Slash-push minigame | `obj_slashpush_minigame` | Own copy | Idea: one slashes and the other pushes. |
| 5 | Sourdough | `obj_sourdough_minigame` | Own copy | — |
| 5 | Fishing | `obj_fishingboat`, `obj_dw_garden_fishingspot` | Local | Each fishes in their own game, which is fine. Shared catches if items matter. |
| 5 | Ralsei's basketball | `obj_dw_ralsei_castle_basketball` | Local | Idea: pass the ball between players. |
| 5 | Peach catcher (climbing) | `obj_climb_peachcatcher` | Local (inside climbing) | Check in play. |
| 5 | Dance floor | `obj_dancefloorzone` | Local | Check in play. |

## Puzzles

| Ch | Puzzle | Objects | Today |
|---|---|---|---|
| 1 | Pushable blocks (the box puzzle) | `obj_pushableblock` | **Shared**. A newcomer finds the blocks where they were left. |
| 1 | Eye switches, hourglass floor tiles | `obj_darkeyepuzzle`, `obj_glowtilepuzz`, `obj_glowtile` | **Shared**. Floor tiles are pressed by friends' figures in every chapter. |
| 1 | Suits puzzles (spade, diamond, swap) | `obj_suitspuzz`, `obj_suitspuzz_button` | **Shared** |
| 1 | Checker paths | `obj_ob_checkertile` | Local on purpose: each player's own hazard to dodge. |
| 1 | Forest area 5 lines | `obj_forest_area5_puzzle` | Local on purpose: how much the darkner sees *you*. |
| 1 | Forest maze | `obj_forestmaze_controller` | Looked at: each player's own path; it moves the story by plot (90-120, shared). Nothing blocks a friend. |
| 2 | Traffic lights (city, mansion) | `obj_traffic_switch` | **Shared** |
| 2 | Mansion saucer puzzles (locked door, shortcut bookcase) | `obj_ch2_room_mansion_east_2f_a`, `obj_ch2_room_mansion_2f_shortcut`, `obj_saucer` | **Follows a friend's solve** (flags 344/346, `scr_mp_keyboard`). |
| 3 | Backstage extra puzzle door, Susie's bridge spikes | `obj_dw_b3bs_extrapuzzle`, `obj_dw_teevie_susiebridge` | **Follow a friend's solve** (flags 1112, 1212; `scr_mp_teevie`). |
| 2 | Mansion secret walls | `obj_ch2_room_mansion_east_1f_e`, `obj_ch2_room_mansion_east_1f_secret` | **Follows a friend's find** (flags 339/340). |
| 2 | Alley floor switch | `obj_alleySwitch` | **Shared**: a friend standing on it holds it down. |
| 2 | Mice rooms' switches | `obj_mouseSpawnSwitch`, `obj_mice2Switch`, `obj_mice3_platSwitch` | Local: they release mice that move on their own. |
| 2 | Mice switch room | `room_dw_city_mice2`, `obj_controller_city_mice2`, `obj_mice2Switch` | Shared result: a friend's solve (flags 368, 915) opens my force field (`mp_mice2_follow`). The mice stay local. |
| 2 | Keyboard puzzles | `obj_controller_keyboard_puzzle_1..3`, `obj_ch2_keyboardpuzzle_*` | Shared result: a friend's solve (flags 390, 333, 420) shows on my keyboard and opens puzzle 1's force field (`scr_mp_keyboard`). Keys stay local. |
| 2 | Shape puzzle | `obj_shapepuzzle` | Local: one player steers a piece. Idea: send the moves. |
| 2 | Noelle's puzzle (keys, force field) | `obj_ch2_noellepuzzle_*` | Looked at: it is the Noelle monologue scene (`room_dw_city_monologue`, Noelle steps on the keys as an actor; plot 94, shared). Nothing to share. |
| 2 | Cyber mazes, the cheese maze, the virus maze | `obj_controller_dw_cyber_maze_*`, `obj_controller_city_cheesemaze`, `obj_controller_dw_cyber_viromaze2` | Cheese maze and the queen screen maze read their flags every frame (a friend's progress shows). Virus maze 2: a friend's win (flag 352) now **turns my force fields off too** (`scr_mp_keyboard`). The virokun maze's flag only ends its chase. |
| 2 | Rotating tiles, push tiles | `obj_rotationController_track`, `obj_rotationtile_tower`, `obj_pushtile_room` | Rotating tiles: only in the mice switch room (follows a friend's solve). Push tiles (post-baseball rooms): room 1's switch and teacup ride **follow a friend's solve** (flags 448/449, `scr_mp_keyboard`); room 2's tiles are held by the party during a chase and stay each player's own. |
| 2 | Chapter 2 pushable blocks | `obj_pushable_block` | Looked at: the object is in no Chapter 2 room (a leftover); nothing to share. |
| 3 | Glowing tiles' hourglass | `obj_glowtilepuzz` | **Shared** (as in Chapter 1; not run separately). |
| 3 | Board puzzles (ice, bridges, switches, blocks, the maze escape) | `obj_board_icepuzzle_*`, `obj_b2bridgepuzzle*`, `obj_board_*switch*`, `obj_b2d_mazeescape` | Own copy (each player plays their own board). |
| 3 | Eye puzzle | `obj_ch3_PGS01B_eyepuzzle_switch` | Shared: Kris's switch pressed by anyone opens the bridge in every game (message 81). |
| 3 | TV quizzes (A/B floor tiles) | `obj_dw_ch3_teevie_quiz_controller`, `obj_dw_ch3_teevie_keyboard_tile` | Shared result: a friend's right answer finishes my TV (`scr_mp_teevie`); the quiz plays as a shared scene. |
| 3 | Puzzle closets | `obj_puzzlecloset_manager` | Part of the board (camera and photos, flags 1228/1245 shared); handled with the board. |
| 4 | Floor switches | `obj_floorswitch` | **Shared**: friends hold them down (a watcher doesn't). |
| 4 | Bookshelf puzzle (remote pianos slide the shelves) | `obj_dw_church_bookshelfpuzzle`, `obj_bookshelf_moveable2x2`, `obj_dw_church_remote_piano` | **Shared**: each shelf follows its place flags (`scr_mp_shelf`). (`obj_dw_church_pushableshelf*` are only in test rooms.) |
| 4 | Piano puzzle (the cage) | `obj_dw_church_pianopuzzle`, `obj_church_piano_playable` | **Shared**: solved by one player, solved in every game (flag 892). Each player plays their own piano. |
| 4 | Piano pieces rooms, sliding piano | `obj_dw_church_pianopiece_*`, `obj_dw_church_remotepianomove` | Looked at: talks with Susie and Ralsei (story flags, scenes shared); nothing to share. |
| 4 | Organ room | `obj_dw_church_organpuzzle` | Local on purpose: songs for the party's reactions, nothing to solve. |
| 4 | Ripple puzzles | `obj_church_ripple*`, `obj_dw_churchb_ripple1` | Looked at: no puzzle state, the ripples only show where Kris steps in the dark. A friend's figure now **makes ripples in my game too** (`ch4/scr_mp_ripple`). |
| 4 | Train tracks | `obj_traintrack_*`, `obj_train_switch` | Local on purpose: pressed by the heart in the Light World section at home (a solo part). |
| 4 | Dark maze, prophecy maze, falling tiles | `obj_dw_church_darkmaze`, `obj_dw_churchb_prophecymaze`, `obj_dw_churchc_fallingtiles` | Looked at: the dark maze moves the story by plot (150-160, its scenes shared the usual way); the prophecy maze and falling tiles keep no state. Each player's own path; nothing blocks a friend. |
| 5 | Pushable blocks (garden) | `obj_pushable_block` | **Shared** |
| 5 | Floor switches | `obj_floorswitch` | **Shared** |
| 5 | Castle puzzles: terracotta statues, the orange door | `obj_dw_fcastle_terracotta_puzzle`, `obj_dw_fcastle_right_puzzle` | **Shared**: a friend's solve opens my room too (`scr_mp_castle`). |
| 5 | Castle side room | `obj_dw_fcastle_sidepuzzle` | Local: platforming and a sign, nothing to solve together. |
| 5 | Flower arena puzzle | `obj_flower_arena_puzzle_manager` | Looked at: in no Chapter 5 room (a leftover); nothing to share. |
| 5 | New glowing tiles, blocks that remember | `obj_glowtile_puzzle_new`, `obj_pushable_block_memory` | Glowing tiles (hard pressure plates room): the solve flag (1431/1432) is checked every frame, so a friend's solve **ends my copy too**; a run of mine going at that moment now ends properly (spikes down, control back; `scr_mp_garden`). `obj_pushable_block_memory` is in no room (a leftover). |
| 5 | Shape puzzle | `obj_shapepuzzle` | Local (as in Chapter 2). |

Known limits of the shared puzzles:

* A switch pressed before a player connected isn't known to them.
* Two players pushing the same block at the same moment are played in the order each game hears
  them.

## Suggested order

1. **Done 2026-11-24:** ACTs with their own game are played by the hero's owner and the mercy is corrected (DONE.md). Next: run each real ACT.
2. **Done 2026-11-24:** Chapter 4 bookshelf shared; train tracks local on purpose.
3. **Done 2026-11-24:** the piano puzzle's solve is shared; the organ is local on purpose.
4. Rhythm game per character, then quiz buzzers: the most fun together. L each.
5. Chapter 3 shared board: the biggest. L.
