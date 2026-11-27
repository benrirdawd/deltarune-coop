# DELTARUNE Multiplayer — done

What was fixed or built, newest reports first, with how each was tested. These are the notes
that used to be in TODO.md; what is still open is in [`TODO.md`](TODO.md). A row marked "open",
"re-check" or "not done" here is also listed there.

## NPC talk for the others: the typing voice (2026-11-26)

The box the others in the room see now also types with its voice: the reader's game sends its
writer's text sound (after the face, message 66), and the others' game plays it a letter at a time
as their copy types, skipping spaces and punctuation like the game's `scr_textsound` (the sound cut
and played again, at the game's own volume).
**Tested** (Chapter 1 `room_cc_throneroom`, plot 242, host Kris talks to Lancer, client Susie in the
room with `chaos:10:120:60`, 1x): the client's log shows each box with its speaker's voice and face:
Lancer's (`snd_txtlan`, face 5) and Susie's (`snd_txtsus`, face 1) in turn, as in the host's game.
`mpcheck` all PASS.

## NPC talk for the others: the speaker's portrait, and the game's letter spacing (2026-11-26)

Follow-up of the text box shown to everyone in the room: the face in the reader's box now shows in
the others' box too. The reader's game sends which face and expression its box has (global.fc /
global.fe, two bytes after the text in message 66; older builds read the text and ignore them). The
others' game draws it with the game's own `obj_face` (a hidden copy, its Draw run with the reader's
fc/fe for that moment), and the text starts after it, 58 px further, as the writer places it. The
text is now drawn letter by letter on the writer's grid (16 px a letter, 36 a line in the Dark
World; 8 and 18 in the Light World), wrapping at the box's edge; it looked narrower before.
**Tested** (Chapter 1 `room_cc_throneroom`, plot 242, host Kris talks to Lancer, client Susie in the
room with `chaos:10:120:60`, 1x, side-by-side screenshots): Susie's face with her lines, then
Lancer's face with his, in both games, the same spacing as the host's own box; the client's box is a
page behind at times on the bad network. `mpcheck` all PASS.

## Talking to an NPC: everyone in the room sees the game's own text box (2026-11-26)

User's design (2026-11-25): when a player talks to an NPC with others in the room, everyone in the
room hears it, in the text box, not only a bubble. The text a player reads on their own was already
sent (message 66, for the bubble over them). Now the others in the same room see it in the game's own
text box (`scr_dbox`, its font, top or bottom picked the way the game picks it for them), typing out,
while they keep walking; the bubble isn't shown then. Not over their own text box, menu, fight,
scene or minigame. Also fixed in that text: the writer's "||" indent of a wrapped line showed as
"ll" (now spaces). Simplest choices: no portrait and no typing voice for the others yet (TODO).
**Tested** (Chapter 1 `room_cc_throneroom`, plot 242, host Kris talks to Lancer with
`touch:obj_npc_facing@300`, client Susie in the room with `chaos:10:120:60`, 1x, screenshots): the
client's screen shows the dark world box with "* Hey, your dad was, uh, protecting the fountain"
and then "* Yeah, guess..." as Kris reads them, and stays free. The first run crashed (`scr_darkbox`
counts the box's corner gems on its caller): fixed. `mpcheck` all PASS.

## A player in a fight, seen from the map: their enemies stand in front of them (2026-11-26)

User's design (2026-11-25): no need to show choosing and dodging; the hero in their battle idle pose
(done before) with the enemy or enemies of that fight standing in front of them. Now each game in a
fight sends its enemies' battle sprites (message 87, every 2 s and when they change, an empty list
as it ends); players outside that fight draw them to the right of the fighting hero, facing them,
feet on the same line, with the same slow white pulse, animated, at most about a hero's height.
New test token: `alone` (my fights bring in nobody, as if the others were off screen).
**Tested** (Chapter 2, `room_dw_cyber_maze_queenscreen`, host Kris starts encounter 54 with `alone`,
client Susie with `chaos:10:120:60`, 1x): the client stays on the map and shows the host's Kris in
battle stance with the two Maus in front of him, plus the game's "Press Z to join" prompt
(screenshot). `mpcheck`: all PASS except "battle" (the client is not in the fight, on purpose).

## Maus' basket (an ACT's own game) is the same in every game (2026-11-26)

The ACT games (MINIGAMES.md) had only been tested with a simulated one (`fakeactg`). With a real one,
Chapter 2's Maus TrapOne (Kris drops a swinging basket on the mice), the others' copies diverged: the
basket starts its swing at a random place in each game, so the same keys dropped it elsewhere (seen:
the client caught a Maus the host missed; its mercy was corrected afterwards). Now the ACT's player
drops the basket and the moment is sent (the swing and the mice's places, message 58 kind 3); every
other copy drops from there (`mp_basket_press`, the Maus basket and the split basket). Test tokens:
`pickact:1:<n>` now works for Kris's ACT list; `throwbot` also presses C during an ACT's game.
**Tested** (Chapter 2, encounter 54 (two Maus), host Kris with `pickact:1:1` + client Susie with
`chaos:10:120:60`, 2x, 2 runs): 7 drops, each "sent" and "played" with the same swing and place, the
same result in both games (2 catches, mercy 100 in both, no correction needed); turns 0-3 the same
HP, TP and mercy in both. `mpcheck` all PASS.

## Werewire's ThrowWire: the same throw everywhere, and Susie's Improvise without Kris (2026-11-26)

Chapter 2's Werewire has Kris's ThrowWire: Susie throws Kris at the wire's weak point (aim and
power swing every frame). Two changes:
* **The throw is the same in every game:** it read the throw key in each game, so each copy threw
  at its own angle. Now Susie's player throws and the others' copies throw with the same angle and
  power when it arrives, as in the Queen fight (`mp_throw_press`).
* **Without Kris** (stand-in rules in TODO): Susie's ACT list gets Improvise ("Throw#Ralsei", 20%
  TP). She holds Ralsei (the Queen fight's own pose), throws him with the game's ThrowWire (same aim,
  weak point and mercy), and he flies curled up as in the Queen fight and runs back to his place.
  Kris's ThrowWire stays free, so playing with Kris is the better way. Kris alone, Susie alone and
  Ralsei alone are still open.
Also fixed: the Sound of Justice hook from phase 1 named a Chapter 4 enemy in plain text, so
Chapters 1, 2, 3 and 5 didn't build (the build log I read was an old one); it now matches it by pattern.
New test token: `tp:<n>` (the fight starts with n TP).
**Tested** (Chapter 2, encounter 74 (Werewire, Tasque), host Susie + client Ralsei with
`chaos:10:120:60`, `pickact:2:1`, `throwbot`, `tp:100`, 20x): Improvise in both games' lists,
three throws (angles 14, 26, 10, power 30) sent and played the same, the Werewire's mercy and HP and
the heroes' HP and TP the same in both on turns 0-5; `mpcheck` all PASS. Screenshots at 1x: Ralsei
curled up flying at the wire, Susie in her throw pose.

## Sound of Justice, phase 2: the players' heroes join Kris and Susie (2026-11-26)

Phase 2 (encounter 186) is started by the room's own story right after phase 1, and the game sets
its party to Kris + Susie (+ Ralsei) in the battle's Create. The players' heroes now join there
too (no entry lines: the game's own scene leads into it), and Gerson's HP grows by the heroes added
(3 story heroes + 1 joined = x1.33; 2 + 1 = x1.50). Two fixes in calling everyone into the second
of two chained fights: a player whose own fight is ending now keeps the call and joins once it
ends (was: "busy", dropped), and a new call ignores the "fight ending" mark for its first 3 seconds
(the mark from phase 1 was still up when phase 2's call came).
**Tested** (Chapter 4, `room_dw_churchb_nongerson`, story, Kris host + Ralsei client with
`chaos:10:120:60`, bots, 20x, 3 runs): phase 1's four turns the same in both games, then phase 2 in
both with party 120 -> 123 and "enemy 0 HP x1.50 = 2025"; turn 1 the same HP, TP (92.25) and
Gerson HP (1951) in both. `mpcheck`: all PASS except "battle": phase 2's turn 0 TP (host 79.25,
client 0; TODO).

## Sound of Justice, phase 1: a one-hero fight with everyone (2026-11-26)

Chapter 4's Sound of Justice (encounter 176, Susie alone in the dark) was a "special" fight (the
leader played every hero). It is now a one-hero fight like the Hammer of Justice: the players'
heroes join Susie, say their entry lines, Gerson's HP is times the heroes, and each player dodges in
their own game (the darkness is per screen already). One fix was needed: in phase 1 the game's
`scr_nextact` is written for Susie alone and calls itself until she acts, so another hero's ACT froze
the game (seen: the host stopped after Kris's ACT). With heroes joined (`mp_ohf_joined`) the usual
order for several heroes runs there instead.
**Tested** (Chapter 4, `room_dw_churchb_nongerson`, encounter 176, Kris host + Ralsei client with
`chaos:10:120:60`, bots, 20x): party 200 -> 213 and HP x3 in both games; the four turns of phase 1
with the same HP, TP and Gerson HP in both (3974, 3902, 3758), then the game's own intermission and
phase 2 (encounter 186) in both, its turn 1 the same in both. `mpcheck`: all PASS except "battle":
phase 2's turn 0 showed the previous fight's TP in the host's game only (TODO).

## Fights made for one hero: the enemy's HP times the heroes (2026-11-26, Hammer of Justice part 4)

The user's rule for these fights: the enemy has more HP for more players. On the battle's first
frame (`mp_ohf_entry_step`) every enemy's HP and max HP are multiplied by the number of heroes in
the fight, once, the same in every game (Gerson: 1350, x3 = 4050 with three heroes).
**Tested** (Chapter 4, encounter 160, `camx:520`, Kris host + Ralsei client with `chaos:10:120:60`,
bots, 20x): "enemy 0 HP x3 = 4050" in both games; turns 1-3 with the same Gerson HP in both
(3888, 3728, 3562) and the same hero HP and TP; then the loss scene in both. `mpcheck`: all PASS
except "ghost" (the half second after the loss, as in part 3).

## Fights made for one hero: the joining heroes' entry lines (2026-11-26, Hammer of Justice part 3)

The user's "not canon" look: before the first menu each hero who joined a one-hero fight says an
entry line in a battle balloon (`scr_heroblcon`, their own text sound) drawn in their hero's colour
instead of white (`obj_battleblcon`'s Draw: `mp_blcon_tint`). Each balloon is up a fixed two seconds,
the same in every game; meanwhile no keys reach the menu or the shared menu (`mp_ohf_holding`), so
nobody chooses ahead of the others. The lines are placeholders (TODO asks the user). Also fixed: the
joining heroes stood at the encounter's x 108, off screen with the story's camera at 520; they now
stand above and below Susie, as in the game's three-hero layout. Test token `camx:<x>` (the camera
where the story leaves it) and `ohfslow` (the lines stay up 20 s, to look at them).
Tried first and dropped: pausing `obj_battlecontroller` for the lines (its balloons were not drawn),
and Z to turn them (the battle-text sync doesn't cover them: one game moved on, the other waited).
**Tested** (Chapter 4, `room_dw_church_arena`, encounter 160, `camx:520`, Kris host + Ralsei client
with `chaos:10:120:60`): at 1x with `ohfslow`, Kris's "...!" in a light-blue balloon and Ralsei's
"We'll face this together!" in a light-green one, in both games (screenshots). At 20x with bots: both
lines 60 frames each in both games, the first menu key only after them, four turns with the same HP,
TP and Gerson HP in both games, then Susie fell in the host's game and both played the loss scene.
`mpcheck`: all PASS except "ghost": the client didn't show the host for half a second after that loss,
while it rebuilt the room (the test starts the fight on its own, without the story's scene).

## Hammer of Justice: a loss is everyone's (2026-11-26, part 2)

This fight has no Game Over: when Susie falls, `scr_damage` starts Gerson's loss scene (Susie back
to full HP, `endcon` 1, flag 36, his `event_user(14)`). Only the game where Susie's SOUL took the
hit ran it, so the others fought on and then got her reset HP. Now that game tells the fight
(message 56, `mp_hoj_lost_send`, hooked right after the game's own lines) and the others' games run
the same loss at once (`mp_hoj_lost_recv`, unless their own fight already ended).
**Tested** (Chapter 4, `room_dw_church_arena`, encounter 160, Kris host + Susie client with
`chaos:10:120:60`, bots taking every hit with `nododge`, 20x): Susie fell in the client's game;
"lost here" in the client and "lost in 1's game: playing the loss scene too" in the host 2 ms later;
both fights ended, both games with the same HP after (25/230/180). `mpcheck`: all PASS. Before the
change the same test ended the client's fight only (Susie 2 -> 230) while the host's went on.
Not checked: the story after the loss (the test starts the fight on its own, so the scene's white
fade stays on the host's screen).

## Hammer of Justice: the other players' heroes join Susie (2026-11-26, part 1)

Chapter 4's Hammer of Justice (encounter 160) is made for Susie alone: the battle's Create sets the
party to her. In a session the other players' heroes now join her right after that line
(`mp_one_hero_fight_party` in `scr_mp_group`, the story's hero first), and it is a normal fight:
it left the "special" list (each player plays their own hero, the same-time menu, each dodges with
their own green SOUL). The fight looked stuck in its first attack before: Gerson talks between his
spear throws and waits for Z, which the test bot never pressed in the attack phase; the bot now
presses Z on a waiting box there (as a player would). Not a mod bug.
**Tested** (Chapter 4, `room_dw_church_arena`, encounter 160, Kris host + Susie client with
`chaos:10:120:60`, bots, 20x): "party 200 -> 210" in both games, KRIS and SUSIE panels; five turns
with the same HP, TP and Gerson HP in both games (1350, 1258, 1175, 1090, 1000). `mpcheck`: all PASS.
Seen, open (TODO): a loss isn't shared yet (the client's heroes fell first: its Game Over, the host's
fight went on).

## Shadow Mantle: retries with 2 players (2026-11-26)

After a loss each player walks back to the console and plays again on their own: the sword intro,
`room_board_preshadowmantle_repeat`, the fight again with full HP (30), the shared hits starting over
(a friend's count that went back to 0 is read as a new try). Test token `touchrooms`: `touch` again in
every room where its object is (here the console after each Game Over).
**Tested** (Chapter 3, 2 players, client with `chaos:10:120:60`, 20x, `smhit`, no `sturdy`, touching
the console): 11 and 12 fights in a row, each starting at hp 30, both games going round sword intro,
preshadowmantle_repeat and the fight; nobody pulled. `mpcheck`: all PASS except "moved" (the test
moves both pieces).

## Shadow Mantle lost with 2 players; the TV row only at the console (2026-11-26)

A loss with 2 players (no `sturdy`, flag 1055 = 5 as in the story; 6 is past the fight and makes the
console unplayable): both games go through Game Over to `room_board_sword_intro` on their own (no
pull, no stuck scene) and are free to walk back to the console. There Kris walks in from the right:
the heroes of the TV row now stand beside him only while he holds the controller at the console
(`mp_tv_kris_draw`), not while he walks there.
**Tested** (Chapter 3, 2 players, client with `chaos:10:120:60`, 20x, `smhit`): both reach the sword
intro with `sst=0 ia=0`; screenshots show Kris walking alone; the console case still logs "tv row: 1
hero(es) beside Kris". (The two figures standing at the console in that room are the game's
party followers made by the test's `party` token; on the real sword route Kris is alone.)

## Shadow Mantle: every copy follows the first player's HP (2026-11-26)

When the players' fights start at different moments, a hit made before the other's fight began
counted whole on one side and halved on the other, and the copies' HP drifted 1-2 apart. Now each
player's count (message 86) also carries their copy's HP (a trailing field, read only when there:
v20 games still read the message), and everyone follows the copy of the first player in the fight
(lowest number): lower there, taken at once (they counted something I didn't); higher for 2 s,
taken too (my own hits reach them in less).
**Tested** (Chapter 3, 2 players, the client's fight starting 3 s after the host's, client with
`chaos:10:120:60`, 20x, `smhit`): the client followed the host's copy twice ("hp 1 -> 2",
"1.50 -> 1"); both defeated him on the same frame with the same HP (0.50), each with their own outro.

## Shadow Mantle's outro: each player's own (2026-11-26)

Everyone fights their own copy of Shadow Mantle, so each now plays their own outro: it no longer
pulls the others into the first player's scene (`mp_story_rise`, while `obj_shadow_mantle_enemy_outro`
exists). Before, the one watching the other's outro saw a gray TV and Kris, Susie and Ralsei drawn on
top of each other at the console.
**Tested** (same run as part 2, `smhit:3`, client with `chaos:10:120:60`, 20x): both log "defeated"
and "my own, not a scene for the others", nobody is pulled; the host's screenshot shows the board TV
with the outro's text and Susie standing beside Kris.

## Shadow Mantle, part 2: a friend's hit can win the fight (2026-11-26)

The game checks Shadow Mantle's rules only when my own sword hits him (`obj_shadow_mantle_enemy`
Step_2): his HP held at 4 until the last phase, his defeat below 1. A friend's shared hit lowered
my copy's HP without those checks, so it could go below 4 too early or below 0 with the fight going
on until my next hit. Now the same rules run after every shared hit (`mp_sm_tick`), and his defeat
is the game's own (`mp_sm_defeat`: the outro and the same clean-up). Test token `smhit:<n>` (n HP
per hit); with `sturdy` the board piece's health stays full.
**Tested** (Chapter 3, `room_board_preshadowmantle`, 2 players, client with `chaos:10:120:60`, 20x,
`smhit:3`): host "defeated (hp -0.50)" on its own hit, the client "defeated (hp 0)" on the host's
hit; the client's outro plays and the host watches it (P2's cutscene, same music). Without sturdy
(an earlier run) both lose and go back to `room_board_sword_intro`. Seen, still open (TODO): the
watcher sees a gray TV and the heroes stacked at the console during the outro.

## Berdly's roller coaster: no car for a missing hero (2026-11-26, user request)

Chapter 2's coaster fight with Berdly (encounter 58) always builds three cars, Kris's, Susie's and
Ralsei's. A hero who isn't in the fight now leaves no car behind: the car and its back aren't drawn
(`o_coaster_hero` / `o_coaster_hero_back` Draw, `mp_coaster_absent` in `scr_mp_standin_ch2`). The
car objects stay, so the fight's own bookkeeping is unchanged; a missing hero never rides one.
**Tested:** encounter 58, Kris (host) and Susie (client, `chaos:10:120:60`): both games log "car 2 not
drawn"; the screenshot shows only Kris's and Susie's cars facing Berdly. `mpcheck`: all PASS.

## The party at the TV on the sword route (2026-11-26, user request)

On Chapter 3's sword route (`scr_swordroom`), the game has Kris alone at the console holding the
controller. In a session every player's hero now stands there with him, close beside him as players
sharing one TV (user: "closer to Kris"): Kris (the game's own, not swapped) in the middle, Susie on
his left, Ralsei on his right, Noelle at the next free place, feet in line with his, drawn with the
same gray glow and floor reflection the game gives Kris (`obj_gameshow_swordroute` Draw,
`mp_tv_row_draw` in `scr_mp_board`). Back views (`spr_susie_walk_up_dw`, `spr_ralsei_walk_up`): the
green room's `*_racing_play` controller sprites face the camera, so they don't fit; a back pose
holding a controller is in SPRITES.md.
**Tested:** `room_board_preshadowmantle` (plot 180, flag 1055 = 6), 3 players (Kris host, Susie and
Ralsei clients, clients with `chaos:10:120:60`): every game logs "tv row: 2 hero(es) beside Kris";
screenshots show Susie, Kris and Ralsei side by side at the console. `mpcheck`: all PASS except
"moved" (nobody walks in this test).

## What a player chose ahead shows to the others (2026-11-26, user's answer)

When a player picks ahead in a fight, the others see it the game's way: an enemy target gets the
game's down arrow (`spr_morearrow`) over its head in that player's SOUL colour, gently bobbing; a
spell, ACT or item shows its name for a moment in that player's own panel box, rising and fading
(45 frames, the battle's big font, in their colour). The pick travels in the choose-ahead message
(type 54, now with the choice and whether it is ready).
Tested: encounter 58 (Berdly, Chapter 2), host + client, client picks Rude Buster on Berdly ahead:
host log "plan seen: slot 1 chose Rude Buster", screenshots show the purple arrow over Berdly and
"Rude Buster" rising over Susie's panel; the same run at 20x with chaos:10:120:60 passed mpcheck.

Also: ACTS.md (from `tools/actlist.py`) lists every team ACT per chapter, who it needs and what
co-op does without them, with columns to fill for Noelle and, later, Berdly.

## Everyone walks alone (2026-11-26, reported in play)

In a session the game's party followers (`obj_caterpillarchara`) are no longer drawn: each player walks
alone as their own character, and the others show as themselves. Before, a party member nobody played
followed the host (and was sent to the others), and the follower matching my character was drawn as
Kris, which showed Kris's Light World look while Ralsei led. Story cutscenes (swaps off) still show the
party as the story has it; the Chapter 3 board keeps its own pieces. The follower mirroring (the host's
NPC followers in message 10, the follower ghosts) is gone; the message keeps a 0 count so build 19
games still read it, and its followers from a build 19 host are read past.
**Tested:** Chapter 1 `room_field_checkers6`, 2 players walking (`wander`) with `chaos:10:120:60`:
`mpcheck.py` passes every check (char, follower, ghost, state, sync, world); screenshots show Kris
and P2's Susie alone, no Ralsei following.

## The SOUL flying out and back is my character's (2026-11-26, reported in play)

The SOUL that flies out of the hero into the box when the bullet phase starts (`obj_moveheart`) and
back at its end (`obj_returnheart`) kept the red SOUL and Kris's position. Now (`mp_soul_fly_created`,
appended to both Creates) it is recoloured like the SOUL in the box (`mp_soul_sprite`) and leaves from
/ goes back to my own hero (its burst too); Kris's player and fights without me as a hero are as before.
**Tested:** Chapter 2 encounter 53, 2 players, the client plays Susie: the log shows "SOUL out of
obj_herosusie" and "SOUL back to obj_herosusie" on each of 3 bullet phases.

## Fewer notes on screen (2026-11-26)

Notes that only repeated what the game already shows went to the log instead (`multiplayer_log.txt`):
"Joining X's fight / battle" (the battle starts on screen), "Watching X's cutscene", "Stopped
watching", my own quick message ("You: ...", the bubble shows it) and ping ("Ping!...", the arrow
shows it), a ping from someone in my room (the arrow shows it; one from another room still has its
note), "Going to X", "Bringing everyone here", "X chose CONTINUE". The yellow line no longer says
"You're down" (the hero's panel shows it) nor repeats the waiting box of a held fight.
**Tested:** Chapter 2 encounter 53, 2 players with `chaos:10:120:60` at speed 20, client `pingat`
and `chat`: 3 turns, identical state in both games; the log has "ping sent", "said: Come here!",
"P2 pings here", "joining Host's battle" and no note for them; the others' message still shows.

## Battle menu, everyone at once, part 2 (2026-11-26)

* Choosing ahead past the main row (which enemy, which ACT, spell or item, which hero) now shows the
  list in the battle's own bottom box, laid out as the game lays out that list (enemies and heroes in
  one column, ACTs, spells and items in two, six to a page), with the SOUL as cursor. The battle text
  is hidden meanwhile; whatever the current chooser has open there goes under mine (their choice
  shows in their panel). The drawn box over the battle (`mp_plan_draw`) and its key hints are gone.
* Part 3: a spell list chosen ahead shows the spell's description and TP cost on the right, and a
  spell the TP can't pay for is grey, as in the game's own list; an item list shows the item's
  description. Tested: screenshot of Susie's list (Rude Buster, "Rude Damage", 50% TP) with the
  host idle in its menu, and the enemy list without TP.
* Test tokens `planslow` (the plan bot presses every 20 frames, nothing else) and `planhold` (stays in
  the plan's list).
* **Tested:** Chapter 2 encounter 53, 2 players, host idle in its menu, client `plan:1:1:0,planhold`:
  the screenshot shows both panels up and Susie's spell list (Rude Buster) with the SOUL in the bottom
  box. With `chaos:10:120:60` at speed 20, client `plan:1:0:0` with full TP: 4 turns, identical state
  in both games, 3 plans played.

## Battle menu, everyone at once, part 1 (2026-11-26)

* While one hero chooses, every other player's next hero has its panel raised too, in the game's own
  battle menu (scr_charbox hook: `mp_box_up`), and each panel lights its own hero's main-row choice,
  so everyone sees the others' bars move live. The "Your turn" / "X is choosing for..." notes are gone.
* A choice made ahead now plays by itself when the menu reaches that hero (no second Z). A plain
  choice like DEFEND is pressed straight away.
* Simplest choice: the game still plays the heroes' choices in order underneath (that is what keeps
  every game the same); only the choosing happens at once.
* **Tested:** Chapter 2 encounter 53, 2 players, host `botslow`, client `plan:4:0:0`: screenshots show
  Kris's and Susie's panels up together with FIGHT and MAGIC lit; the client's DEFEND played by itself.
  With `chaos:10:120:60` at speed 20: 4 turns, identical state in both games, 2 auto-played choices.

## Joining during my own scene, next to the host: the room is entered again (run, 2026-11-25)

* The re-entry built with the post-baseball fix (a client that joins during its own scene, already
  next to the host, enters the room again so it's built from the shared story) has now run.
* Test, Chapter 2 `room_dw_city_postbaseball_1`, plot 120, both at the switch (`pos:250:500`), the
  client starting Noelle's scene on its own and joining at frame 400 (`connectat:400`, no Z presses,
  so its scene stays open), both with `chaos:10:120:60` (`work/fol/joinscene3`): the client logged
  "dropping what I was doing", then "warp to ... 250,500" (not "already next to the host"), its room
  controller was there afterwards and the room's scene started again, now through the scene lock.
  mpcheck: all PASS. (`joinscene2`, the host far away: the usual warp.)

## Chapter 4 side climb: a friend's climb adds my shortcut spots (2026-11-25)

* `room_dw_church_sideclimb`: finishing the climbs (flag 1524 set) adds shortcut climbing spots out
  of the room (the room's User Event 1), but the flag was read only when the room is built, so a
  friend's climb didn't add them in my game. Now, once the flag is set, my room adds them too (the
  event only adds what isn't there yet; `mp_sideclimb_follow`, `scr_mp_shelf`).
* Test, Chapter 4, plot 150, the host setting flag 1524, both with `chaos:10:120:60`
  (`work/fol/climb4`): the client logged "climbed by a friend" and its shortcut spot existed
  afterwards. mpcheck: all PASS but "moved" (nobody walks).
* The sweep of rooms that read a solve flag only when built is finished (TODO).

## Chapter 3 backstage extra puzzle and Susie's bridge follow a friend's solve (2026-11-25)

* `room_dw_b3bs_extrapuzzle` (the floor switch opens the door, flag 1112) and
  `room_dw_teevie_susiebridge` (the board switch lowers the spikes, flag 1212 = 2): both flags were
  read only when the room is built, so a friend's solve left my door or spikes up. Now, when the
  flag is set, my room takes the game's own solve step (door step 1; the switch counted as pressed),
  the same step my own solve takes (`scr_mp_teevie`).
* Test, Chapter 3, plot 50, the host setting the flag, both with `chaos:10:120:60` (`work/fol/b3x`,
  `work/fol/sbr`): the client's door went (doorcon 2, no door block) and its spikes went down (the
  solid block became the lowered marker, con 2). mpcheck: all PASS but "moved" (nobody walks).

## Chapter 2 third dining room follows a friend's solve (2026-11-25)

* `room_dw_mansion_dining3`: the dog's table flies into the wall and opens a doorway (flag 381, read
  only when the room is built), so a friend's solve left my wall shut. Same as the mouse tower: once
  the flag has arrived from someone else and I'm free, my room is entered again, built with the
  doorway open. The mouse tower's code became a shared helper (`mp_puz_reenter_follow`).
* Test, Chapter 2 `room_dw_mansion_dining3`, plot 150, the host setting flag 381, both with
  `chaos:10:120:60` (`work/fol/dining3`): the client re-entered and its room came back finished
  (con 28980, a third door: the doorway). The mouse tower test again after the change
  (`work/fol/mice3b`): same result as before. mpcheck: all PASS but "moved" (nobody walks).

## Chapter 2 mouse tower follows a friend's solve (2026-11-25)

* `room_dw_city_mice3`: the puzzle takes Noelle out of the party, closes the room (a block at the
  entrance, a force field) and ends with flag 379 and plot 78. The flag is read only when the room
  is built, and the usual "the story moved on: enter the room again" refresh waits while a room
  event is going, which this room's controller always is: a friend's solve left me shut in with the
  puzzle going. Copying the ending by hand would have to put Noelle back; simpler: once flag 379 and
  plot 78 have arrived from someone else and I'm not in a text box or scene, I enter the room again,
  built finished as when you come back later (`mp_mice3_follow`, `scr_mp_keyboard`).
* Test, Chapter 2 `room_dw_city_mice3`, plot 77, the host setting plot 78 then flag 379, both with
  `chaos:10:120:60` (`work/fol/mice3a`): the client logged "solved by a friend, entering the room
  again" and re-entered; its controller was gone afterwards (the finished room has none). mpcheck:
  all PASS but "moved" (nobody walks), no crash.

## Chapter 2 mansion secret walls follow a friend's find (2026-11-25)

* `room_dw_mansion_east_1f_e` (flag 339) and `room_dw_mansion_east_1f_secret` (flag 340): finding
  the secret hides the wall tiles and removes a solid block at the exit, but the flag was read only
  when the room is built, so a friend's find left my wall and block. Now, while the flag is set and
  my block is still there, my room takes its own "found" step (`mp_mansion_secret_follow`,
  `scr_mp_keyboard`): the same step my own find takes, so nothing is done twice.
* Found by a wider sweep (solid blocks, not only force fields): the rest is listed in TODO.
* Test, Chapter 2, plot 150, the host setting the flag, both with `chaos:10:120:60`
  (`work/fol/mans_339`, `work/fol/mans_340`): each client logged "found by a friend ... my wall
  opens" once (the block was gone the next frame, or it would log again). mpcheck: all PASS but
  "moved" (nobody walks).

## Chapter 2 mansion saucer puzzles follow a friend's solve (2026-11-25)

* Found by a sweep of the room controllers for flags set in their step but read only when the room
  is built. `room_dw_mansion_east_2f_a` (the locked door, flag 344) and
  `room_dw_mansion_east_2f_shortcut` (the bookcase, flag 346): the room's whole step runs only while
  the flag is 0, so a friend's solve froze my copy with the door locked (a solid block) or the
  bookcase in the way. Now, when the flag arrives from someone else, my room does what the game's
  last step does: explosion, door open or bookcase gone, saucers, Monty and the force field gone
  (`mp_mansion_key_follow`, `scr_mp_keyboard`). Written separately because the game's step expects
  the key's sparkles to exist (it would fail when the key never flew).
* Test, Chapter 2, plot 150, the host setting the flag, both with `chaos:10:120:60`
  (`work/fol/mans_344`, `work/fol/mans_346`): each client logged "solved by a friend ... my door
  opens" / "my bookcase goes" and went on running (about 1200 frames more, no error). mpcheck: all
  PASS but "moved" (nobody walks).

## Mazes: Chapter 2's second virus maze follows a friend's win (2026-11-24)

* All the mazes were looked at for something that blocks a friend (MINIGAMES.md). Chapter 1's forest
  maze and Chapter 4's dark maze move the story by plot (shared); the prophecy maze and falling
  tiles keep no state; Chapter 2's cheese maze and queen screen maze read their flags every frame.
* Fixed: `room_dw_cyber_viromaze2`: beating the virus sets flag 352, which turns the room's force
  fields off (and the one that closes behind you), but the flag was read only when the room is
  built: a friend's win left my fields up and could shut me in. Now, when flag 352 arrives from
  someone else, my controller runs its own solve step ("Sounded like a forcefield deactivating",
  fields gone) once I'm free to read it (`mp_viromaze2_follow`, `scr_mp_keyboard`).
* Test, Chapter 2 `room_dw_cyber_viromaze2`, plot 50, the host setting flag 352, both with
  `chaos:10:120:60` (`work/fol/viro2a`): the client logged "won by a friend", went from 2 force
  fields to 0 with the message read and control back (con 3, interact 0). mpcheck: all PASS but
  "moved" (nobody walks in this test).

## Chapter 5 new glowing tiles: a friend's solve during my run ends it properly (2026-11-24)

* `room_dw_garden_hardpressureplates`: the two timed glowing tile puzzles (`obj_glowtile_puzzle_new`)
  check their solve flag (1431/1432) every frame, so a friend's solve (shared flag) already ended my
  copy. But if my own run was going, the game jumped to "done" without its end step: the spikes it
  raised (9 solid blocks) stayed up and could shut me in, and the camera stayed held. Now my copy
  then runs its own end step and gives control back (its alarm), and for flag 1431 the held camera
  goes as when you come back later (`scr_mp_garden`). Simplest choice: the result is shared, not
  the tiles.
* Test, Chapter 5, plot 264, the client starting the puzzle (`useobj`), the host setting flag 1432
  during the client's run, both with `chaos:10:120:60` (`work/fol/glownew3`): the client went from
  state 1 with 9 solid blocks to state 2 with 0, interact 0, logged "solved by a friend ... (was
  state 1)". mpcheck: all PASS. (`glownew1`: neither had started, both followed from state 0.)
* Looked at, nothing to share: `obj_flower_arena_puzzle_manager` and `obj_pushable_block_memory`
  are in no Chapter 5 room.

## Chapter 4 dark ripple rooms: a friend's steps make ripples too (2026-11-24)

* The church's dark rooms (`obj_church_ripple_area_manager`: rippleworship, the waterfall room, the
  Gerson chase, ...) light the floor with a ripple at each of Kris's steps. They hold no puzzle
  state (nothing opens or is solved), so there was nothing to share, but a friend walking in the
  dark left no ripples in my game. Now a friend's figure in my room makes the same ripples on its
  steps (no sound) while the room is dark (`mp_ripple_tick`, `ch4/scr_mp_ripple`; a stub elsewhere).
  Simplest choice: drawn from the figure each game already shows, nothing new is sent.
* Test, Chapter 4 `room_dw_church_rippleworship`, plot 130, the host walking up-left (`bot`,
  `walkto:1450:1150`), both with `chaos:10:120:60` (`work/fol/ripple6`): the client logged a ripple
  for player 0 at each walk cycle (1656,1348 > 1640,1244 > 1640,1151). mpcheck: all PASS. (First
  try in `room_dw_church_ripplepuzzle`: that room's manager stays off until its own trigger.)

## Chapter 2 post-baseball room follows a friend's solve; a room's controller survives a watched scene (2026-11-24)

* `room_dw_city_postbaseball_1`: Kris's floor switch (flag 448) and the teacup ride (flag 449) open
  the room's force fields, but the flags were read only when the room is built, so a friend's solve
  left mine up. Now, when a flag arrives from someone else, my room goes the game's own way: the
  switch tile is held down (sound, field gone, "Noelle comes back" step), the teacup step jumps to
  "field gone" (`mp_postbb_follow` in `scr_mp_keyboard`). Not before Noelle's opening scene is over.
  Simplest choice: the result is shared, not who stands where.
* Found by the test: after watching a friend's copy of a room's opening scene, the "scene started
  again here" stop removed every object with a cutscene master, including the room's controller
  (`obj_room_*`), which here also runs the switches and force fields: the client's room stopped
  working. Now that stop keeps `obj_room_*` controllers and only ends their scene
  (`mp_kill_scenes(true)`); the opening scene's own change (the top-right field off) is done by the
  follow. And a client that joins during its own scene and is already next to the host now enters
  the room again, built from the shared story, when that scene was cut short.
* Test, Chapter 2 `room_dw_city_postbaseball_1`, plot 120, both at the switch (`pos:250:500`), the
  host setting flags 448 then 449, both with `chaos:10:120:60` (`work/fol/postbb5`): the client
  logged "a friend pressed the switch" and "rode the teacup"; both games ended with the same room
  (con 10, switch 2, teacup 2, one force field left). mpcheck: all PASS. Runs 2-4 showed the
  controller loss (client stuck at 3 or 2 force fields). The join re-entry is built but the passing
  run's timing didn't hit it.
* Looked at, nothing to share: Chapter 2's `obj_pushable_block` (in no room), Noelle's puzzle (the
  monologue scene, plot 94).

## Talk key: F5 no longer allowed (it is the map ping) (2026-11-24)

* F5 joins the keys that can't be the push-to-talk key (F6-F9, Z/X/C, arrows...): picking it says
  "That key is already used". A talk key already set to F5 in an older config keeps talking and no
  longer pings at the same time.
* Built (5 chapters, 0 FAILED) and not run: the key binding needs a real key press, which the test
  bots don't make (they set the game's input, not the keyboard).
* The ping itself still works (Chapter 2, `pingat`, `chaos:10:120:60`, `work/fol/pingf5`): "Ping!"
  for the host, "Host pings: here!" for the client; every check passes but "moved" (nobody walks in
  this test).

## Map ping: the edge arrow seen, moved out from under the player list (2026-11-24)

* First look at the arrow for a pinger who is off screen (Chapter 2 `room_dw_city_big_2`, the host
  pings from far up-left of the client, both with `chaos:10:120:60`, `work/fol/pingedge4`): the
  arrow was drawn at the screen's corner, under the player list, hard to see. Now an edge arrow that
  would fall in the list's corner sits just below the list (the list's height follows the number of
  players). Screenshot `work/fol/pingedge5/c1_24.png`: the host's blue arrow below the list, pointing
  up-left towards the host.
* New test token `pinglong` (arrows stay 30 s, for screenshots: the shots come a few seconds late).

## Chapter 4 readable with Z: stays local (2026-11-24)

* Test, Chapter 4 `room_dw_ralsei_castle_1f`, plot 289, the host reads an `obj_readable_room1`
  (`touch`, then `mash` to close the text), both with `chaos:10:120:60` (`work/fol/npc4`): the text
  box opens in the host's game only (interact 0->1, then back to 0), the client isn't pulled, every
  check passes (char, follower, ghost, state, sync, scene, world; no crash).

## Chapter 5 shop with two players checked; Chapter 3 puzzle closets looked at (2026-11-24)

* Shops are rooms of their own (entered through a door, not with Z). Test, Chapter 5
  `room_shop_ch5`, plot 291, both players in the shop, the host mashing Z, both with
  `chaos:10:120:60` (`work/fol/shop5`): the host went through the shop's menus to "Buy it for $333?"
  while the client's shop stayed on its own first page (screenshots): each player has their own shop
  menu, nobody pulled, every check passes (state, sync, scene, music, world; no crash).
* The Chapter 3 puzzle closets (`room_dw_puzzlecloset_1..3`) are part of the board (the camera and
  photos, flags 1228/1245, shared): covered by the board's handling, left as is.

## Chapter 3 TV quizzes: answered by one, done for everyone (2026-11-24)

* The TV quizzes (`obj_dw_ch3_teevie_quiz_controller`, `room_dw_teevie_large_02` and the maze):
  walking up to the TV starts a quiz scene, answered on the A/B floor tiles
  (`obj_dw_ch3_teevie_keyboard_tile`). A right answer sets the quiz's flag (1131, 1132..., shared)
  and lowers the spikes. The quiz reads its flag only when the room is built, so after a friend's
  quiz my TV still waited: walking up to it would start the same quiz again, with my spikes up.
  Now when the flag arrives while my quiz waits, my TV is done as when you come back later (no
  quiz, spikes down) (`mp_tvquiz_follow`, new `scr_mp_teevie`, Chapter 3 only).
* Simplest choice: the result is shared. The quiz itself plays as a shared scene (lock and mirror).
* Test, Chapter 3 `room_dw_teevie_large_02`, plot 100, both with `chaos:10:120:60`
  (`work/fol/tvquiz`): the client set flag 1131; its quiz A and the host's (about 7 s later) went
  from waiting (con 0) to done (con -1); quiz B (flag 1132) stayed waiting in both. No crash.

## Chapter 3 eye puzzle: Kris's switch pressed for everyone (2026-11-24)

* `room_dw_couch_overworld_02`: Susie and Ralsei walk to their switches by themselves; Kris's switch
  then opens the bridge and moves the story on (plot 21). It was pressed only in the game of whoever
  pressed it. Now it is one more switch shared with message 81 (hook on its User Event 0, as the
  Chapter 1 switches): every game in the room plays the same press and opens the bridge.
* Simplest choice: the press is shared; Susie and Ralsei's walk stays each game's own.
* Test, Chapter 3, plot 20, both with `chaos:10:120:60` (`work/fol/eye3`): the client pressed the
  switch (`useobj`); the host got "player 1 used obj_ch3_PGS01B_eyepuzzle_switch", played the
  bridge sequence and ended at plot 21 with control back (interact 0), as the client did. No crash.

## Chapter 2 mice switch room: solved by one, open for everyone (2026-11-24)

* `room_dw_city_mice2`: a mouse (or Noelle) landing on the switch turns off the force field and
  ends the room's puzzle (story flags 368 and 915, shared). The room reads them only when it's built,
  so a friend's solve left my force field up. Now when flag 368 arrives from someone else, my room
  does what it does when you come back later: switch frozen down, force field gone, the room's
  controller gone (`mp_mice2_follow`, in `scr_mp_keyboard`, Chapter 2).
* "From someone else": the flag changed between two of my controller's steps (my own solve sets it
  inside the step; `mp_mice2_after` keeps the value the step left).
* Simplest choice: the result is shared, not the mice.
* `setflag` takes several flags now (`setflag:915=5@400/368=1@402`); `logpuz` logs the room
  (`[MPMICE]`).
* Test, Chapter 2 `room_dw_city_mice2`, plot 75, both with `chaos:10:120:60` (`work/fol/mice2b`):
  the client set flags 915 and 368; its room and the host's (about 3 s later) followed. No crash.
  A first run with flag 915 alone (`mice2`) changed nothing, as expected.

## Game Over choice screen: a client was frozen there; CONTINUE now tested (2026-11-24)

* Bug: `PLACE_FAILURE` (the Game Over's CONTINUE / GIVE UP screen) starts with `PLACE_`, so a
  client there was taken for a client in Chapter 1's opening while the host wasn't "in the game"
  (the host was on its own Game Over screen). The screen was paused on a "the host is creating the
  vessel" wait and never reached the choice. With the host already back in the game it would instead
  have skipped the choice and gone to the host. Fixed: the Game Over rooms are not the opening
  (`mp_opening_tick`).
* The screen's steps are logged now ("game over: choice screen step N").
* New test tokens `failchoice` (go through the screen's text and take CONTINUE) and `failwait` (go
  through the text and wait at the choice). With either, `bot` and `mash` no longer press Z on the
  Game Over screens (they used to take the quick retry first).
* Test, Chapter 2 `room_dw_cyber_maze_virokun`, encounter 53, `bot,tough,nododge`, both with
  `chaos:10:120:60` (`work/fol/gochoice7`): both fell, both reached the choice. The host took CONTINUE
  ("I continue, for everyone"); the client, waiting at the choice, got "Host chose CONTINUE.",
  continued by itself ("continuing with the others") and both came back to the room's entrance.
  Before the fix (`gochoice6`) the client stayed paused at the screen's first step.

## Chapter 5 platformer: no second Susie or Ralsei (2026-11-24)

* A friend who plays Susie or Ralsei is drawn as them in the platforming rooms, and the game's own
  Susie/Ralsei follower was drawn next to them. Now, in my game, the follower of a character that a
  friend in my platforming room plays is hidden, and shown again when they leave, stop being drawn
  or leave the platformer (`mp_plat_followers_tick`, `gml/ch5/scr_mp_plat`).
* Simplest choice: only not drawn. The follower still follows, carries and helps as the game wants.
* Test, Chapter 5 `room_dw_garden_aquaplatforming`, plot 291, client plays Susie (`wander`), both
  with `chaos:10:120:60` (`work/fol/platfol`): the host's Susie follower was hidden 10 s in; the
  host's screenshot shows Kris, the Ralsei follower and P2 as Susie, with no second Susie. The client
  hid nothing (the host plays Kris). No crash.

## A switch pressed before you came: played back for you (2026-11-24)

* Chapter 1's eye switches (`obj_darkeyepuzzle_switch`) and suits buttons (`obj_suitspuzz_button`)
  leave a state in the room, but a press only reached those already there. Now every game keeps
  the room's presses, in order, while someone is in that room (forgotten like the blocks when nobody
  is). Whoever comes in later plays them back once on entering. The host sends them to someone who
  joins (message 81, facing + 128: keep it). `mp_puz_sw_note`, `mp_puz_sw_tick`,
  `mp_puz_sw_send_all` in `scr_mp_world`.
* Simplest choice: the presses played again, not each puzzle's state. Safe for these two: a
  solved eye puzzle removes its switches, and the suits buttons do nothing once won. The timed
  switches (traffic lights, hourglass) are left out: their timer would start again.
* Found on the way: `array_contains` doesn't exist in this game's runtime (both games hung on
  start); replaced by a loop.
* Test, Chapter 1 `room_field_secret1`, plot 30, both with `chaos:10:120:60` (`work/fol/swlate4`):
  the host pressed spade and diamond alone (suits 1200). The client connected afterwards
  (`connectat:600`), got the 2 presses and played them back: 1200 too. Then the client pressed spade:
  1212 in both games. No crash.

## Same character as another player: a hint to watch them (2026-11-24)

* Several players may pick the same character; in fights the first to pick it plays it and the others
  watch. Those others are now told once, on the map: "<name> plays your character in fights (you
  watch them). F9 > Watch follows them on the map too." Told again only if who plays it changes
  (`mp_spec_hint`, `scr_mp_spec`).
* Simplest choice: a hint, not switching to watching on its own: walking around as your own pick
  still works and some players want it.
* Test, Chapter 2, plot 60, both on Kris (`MPCHARS="1"`), both with `chaos:10:120:60`
  (`work/fol/spechint`): the client got the hint once (4 s in, after the room was ready), the host
  none. No crash.

## Chapter 2 keyboard puzzles: solved by one, solved for everyone (2026-11-24)

* `room_dw_cyber_keyboard_puzzle_1..3`: typing the right word sets a story flag (390, 333, 420;
  shared). The rooms' own controllers already watch those flags every frame, but the keyboard's
  screen reads its flag only when the room is built, and puzzle 1's force field only goes while that
  screen shows the win. So a friend's solve left my force field up. Now the screen follows the flag
  the way it starts when you come back later: the right word, the win picture, force field gone
  (`mp_kbpuzzle_follow`, `scr_mp_keyboard`, Chapter 2 only).
* Simplest choice: the solve is shared, not each key.
* New general test token `setflag:<n>=<v>@<f>` (sets a story flag at a room frame, as a friend's
  game would); `logpuz` logs the keyboard room (`[MPKEYB]`).
* Test, Chapter 2 `room_dw_cyber_keyboard_puzzle_1`, plot 60, both with `chaos:10:120:60`
  (`work/fol/keyb1`): the client set flag 390; its screen showed the win and the force field went.
  The host's flag arrived about 5 s later (chaos), and its screen and force field followed on the same
  frame. No crash. Puzzles 2 and 3 were not run (same code path; their own controllers react to the
  flag).

## Chapter 5 castle puzzles: solved by one, open for everyone (2026-11-24)

* These rooms keep "solved" as a bit of a story flag. Story flags are shared, but the rooms read the
  bit only when they are built, so a friend's solve reached my flags and not my room. Now
  (`scr_mp_castle`, Chapter 5 only):
  * `room_dw_fcastle_terracotta_puzzle` (statues on the floor switches open the shortcut; flag 1744
    bit 10): my room runs its own opening step when the bit arrives.
  * `room_dw_fcastle_right_puzzle` (the orange key opens the orange door; flag 1317 bit 0): my room
    opens the door the way it does when you come back later.
  * Simplest choice: the result is shared, not each step of the puzzle.
* `room_dw_fcastle_sidepuzzle` was looked at and left alone: a platforming room with a sign, nothing
  to solve together.
* Test token `castlesolve:<f>` (sets the room's solved bit, as a friend's solve does); `logpuz` logs
  the room (`[MPCASTLE]`).
* Tests, Chapter 5, plot 100, both with `chaos:10:120:60` (`work/fol/castle_terracotta_puzzle`,
  `castle_right_puzzle`): the client set the bit. Both rooms opened in both games, the host's about
  1.7 s later: flag 1744 = 1024 and the shortcut's 2 walls gone; flag 1317 = 1 and the door's wall
  gone.

## Launcher: its own update list comes first, so an old install finds deltarune-coop (2026-11-25)

* The installed package's `update.txt` (in `%LOCALAPPDATA%\DeltaruneOnline\app`, shared by every launcher)
  used to win over the list built into the exe. An old install (build 9 listed `traeb0n/deltarune-online`
  and the Drive folder) kept even a new `DELTARUNE-Online.exe` looking only there, so it never found v19.
* Now the exe's own list comes first (`deltarune-coop`, then `deltarune-online`, then the Drive folder),
  followed by any other source the installed list has (`Core.Feeds`).
* Test: with `DRO_ROOT` set to a temp folder whose `app/update.txt` had only the build-9 sources,
  `Feeds()` called through reflection on the built exe returned `deltarune-coop` first, then
  `deltarune-online`, the Drive folder and `traeb0n/deltarune-online`. The v19 release's exe and zip
  were replaced with this launcher (still build 19).

## Chapter 3 puzzle closets: a door a friend opened with its code opens for me too (2026-11-25)

* `room_dw_puzzlecloset_1..3`: the right code sets a story flag (1094, 1095, 1231; shared) and the door
  opens, and the room is built without the door after that. A friend's code left my door shut. Now,
  when that flag is 1 while my door waits (nothing going on, not open), it opens the game's own way
  (`myinteract` 50: the door opens and Ribbick leaves, as in the solver's game). The function is
  `mp_closetdoor_follow` (`scr_mp_teevie`), prepended to the door's Step.
* Test, Chapter 3 `room_dw_puzzlecloset_1`, plot 100, both with `chaos:10:120:60` (`work/fol/closet1`): the
  client set 1094 and the host's door opened. Nobody was held in an interaction, and all mpcheck checks
  pass except `moved` (nobody walks).

## Chapter 2 KEYGEN lock: a friend's KEYGEN unlocks mine too (2026-11-25)

* `room_dw_mansion_east_1f_secret`: using the KEYGEN sets story flag 309 to 4 (shared), and the lock fades
  away. A friend's use left my lock there, saying it can't be opened, with the KEYGEN used up. Now when
  309 reaches 4 while my lock waits (`con` 0), it goes (`mp_keygen_lock_follow`, `scr_mp_keyboard`,
  prepended to its Step). My own use sets `con` 1 in the same step as the flag, so it is never taken
  for a friend's. Simplest choice: gone at once, no fade. The fade's last step would set
  `global.interact` to 0 under me.
* Looked at: the basement door (`obj_mansion_basement_door`, flag 373) is closed by the story, not by a
  player. Left as is.
* Test, Chapter 2, plot 150, both with `chaos:10:120:60` (`work/fol/keygen1`): the client set 309 to 4 and
  the host logged its lock gone. The client's own lock also went, since the token sets the flag without
  a real use. All mpcheck checks pass except `moved` (nobody walks).

## A force field a friend's switch turned off goes from my room too (2026-11-25)

* `obj_forcefield` with a `disableflag` checks it only when built. The one place it is used is Chapter 2's
  `room_dw_cyber_musical_door`: its field goes when flag 332 is 1, set by a switch in
  `room_dw_cyber_battle_maze_2` ("Sounds like a forcefield powering down"). A friend standing at the
  musical door when the switch was pressed kept the field until they came back.
* Now, when a friend's game turned the flag on, my field goes (`mp_forcefield_follow`, `scr_mp_world`,
  prepended to its Step, Chapters 2-5). Only a friend's flag counts: my own solve is left to the room's
  code. `mp_friend_set_bit` moved to `scr_mp_world` for this.
* Looked at: Chapter 5's `disableflag` objects are floor spikes (`obj_floorspike`). They check their
  flag every frame already, so a friend's solve lowers them without help.
* Test, Chapter 2 `room_dw_cyber_musical_door`, plot 32, both with `chaos:10:120:60` (`work/fol/ff2`): the
  client set flag 332, and the host logged its field gone. All mpcheck checks pass except `moved`
  (nobody walks).

## A chest a friend opened shows open in my room too (all chapters, 2026-11-25)

* A chest's item flag is shared, so a chest a friend opened already said "(The chest is empty.)" in
  my game, and the item never came twice. But it still looked closed until I left and came back.
  Now it shows open as soon as the flag is there (`mp_chest_follow`, `scr_mp_world`, prepended to
  `obj_treasure_room`'s Begin Step). That is the look the room gives it when built. A chest that
  closes again on purpose (`noroom`: inventory full) doesn't set the flag, so it is left alone.
* Test, Chapter 1 `room_forest_dancers1`, plot 150, both with `chaos:10:120:60` (`work/fol/chest1`): the
  host set flag 107 (that room's chest), and both games logged the chest shown open. All mpcheck
  checks pass except `moved` (nobody walks).

## Test tool: screenshots and closing the games work with a relative output folder (2026-11-27)

* `mptest.sh` with a relative `MPTEST_OUT` (as in every test here) wrote the games' `.pid` files
  into the game folder: `run_game.sh` starts the game from there. So no screenshot was ever taken
  ("no window for process 0"), and a stuck test could not stop its games by id. The output folder
  is now made absolute first.
* Test (`work/fol/shot2`, `SHOTS=15`): both `.pid` files written, the screenshots at 15 s and at
  the end taken (the host's window shows Kris and P2's Susie at the top of the mansion), and both
  games closed afterwards.

## Watching a cutscene: layers the scene shows, hides or scrolls (2026-11-27)

* Follow-up of the layer mirroring. Many scenes show or hide a layer of the room
  (`layer_set_visible`: about 40 objects in Chapter 2, 125 in Chapter 4 and 130 in Chapter 5) or
  give it a scroll speed (`layer_vspeed`: the rocks in the scene at the top of Queen's mansion).
  Message 90 now also carries each layer's visibility and scroll speed. A scrolling layer scrolls
  by itself in the watchers' game, and is set to the leader's place only when it is well off, so
  it doesn't move in jumps.
* Rooms can have many layers, so each message carries the layers that changed since the last one,
  then a rotating share of the others (a late watcher gets them all), at most 25, every 5 frames.
* Test, Chapter 2 `room_dw_mansion_top`, plot 165, client with `chaos:10:120:60`
  (`work/fol/lay1`). The host started the scene and the client watched it. In the middle, the
  client's game set 4 of the room's layers as in the host's game. All mpcheck checks pass, no
  crash.

## Watching a cutscene: the road moves, and a scene that takes the party along takes me too (2026-11-27)

Found with Chapter 2's ride beside Queen's car (`room_dw_city_traffic_4`, plot 79), which one player
plays and the others watch (the shared cutscene), as planned in MINIGAMES.md.
* **The cars and the road ahead were missing for the watchers** (user report). The ride scrolls the
  road and its parked cars, which are tiles, by moving the room's tile layers (`tilemap_x`). The
  mirror only sends instances, so the watchers' road stood still and the cars further on never
  came. Now the leader's game also sends where each of the room's layers and its tiles are
  (message 90, every 10 frames, all of them, so a late watcher gets them too), and the watchers
  move their copy of the layers there. The room is built again when the scene ends.
* **A watcher was sent back 1,364 px behind the party.** A scene that ends in the room it started in
  sends the watchers back to where they were. The ride ends at the far end of the road, and the
  watcher went back to the start. User (2026-11-27): in this scene everyone must go with the one
  who started it, since there is no way back. Now, when the leader ends more than a screen width
  (640 px) from where I would go back to, I go with the leader.
* Test, 2 players, client with `chaos:10:120:60` (`work/fol/car7`). The client watched the whole
  ride (about 100 s), its 3 road tile layers moved as in the host's game, and it ended at
  2086,250 next to the host at 2040,250 (before the fix: 728,120). All mpcheck checks pass.
* Looked at, nothing to do: Chapter 5's shape puzzle is only in `room_darkbulbTest`, a developer
  test room that can't be reached in play.

## Chapter 2 shape puzzles: a friend's piece moves in my game too (2026-11-27)

* The shape puzzles (the mansion's dark bulb rooms, Shaun's room): a button steers its piece into
  the outline. It was each player's own, so a friend at the button moved the piece only in their
  game. Now the steering player's game sends the piece's place and turn when they change (message
  89, naming the button by where it stands, because a room has several), and the others' piece goes
  there too. When it fits, their outline lights up with the game's own sound. The solve's story
  scene stays the solver's (the shared cutscene), so a copy moved by a friend doesn't check the fit
  itself, and it doesn't send the fit back. My own keys win while I steer a piece myself.
  `scr_mp_shape`, prepended to the button's Step.
* New test tokens `shapebot` (the piece I steer moves right every 20 frames) and `shapesolve`
  (3 s into steering, the piece fits, and the room's scene goes on as with a real fit). The first
  `shapesolve` left both test games stuck: it marked the fit without starting the room's scene, so
  the host's game waited forever and the client watched it. Fixed before this test.
* Test, `room_dw_mansion_darkbulb_1`, plot 104, client with `chaos:10:120:60` (`work/fol/shape4`).
  The host steered for 4 s, and the client's piece followed each move and turn. The fit lit all
  three pieces in the client's game. The room's scene played in the host's game and the client saw
  its text boxes. Both reached plot 105 and could move again. No crash.

## Two players opening the same chest at the same moment: one item; NPC talk stays local (2026-11-27)

* The host-as-referee item's last step, NPC talk. Talking is each player's own: the others in the
  room only see the text (DONE.md 2026-11-26). The only place two talks at once could go wrong is a
  one-time gift, such as a chest or an NPC who gives an item: both games run it.
* New test token `touchsyncz:<obj>`: as `touch` (stand below it, face it, press Z), at the same
  10 s mark of the shared clock as the others. It logs the items every 2 s.
* Test, Chapter 1 `room_forest_dancers1`, plot 150, both with `chaos:10:120:60` (`work/fol/chz1`).
  Both opened the chest 0.01 s apart, and both games showed its text. The client briefly had the
  item twice. Within 4 s the host's inventory (host-authoritative, `mp_inv`) settled on one copy in
  both games, and it stayed so. No crash.
* Choice (simplest): no host request before talking. The shared stores (flags, items, money)
  already settle a race. Asking the host first would add a network round trip before every text box
  opens. The referee item is closed: cutscene start (scene lock), battle start (lower number wins a
  tie) and talk (stores) are all covered.

## Two players touching the same enemy at the same moment: one fight, tested (2026-11-27)

* The host-as-referee item's battle-start step. A tie-break already existed: when another player's
  touch of the same enemy arrives while my "!" is waiting, the lower player number gets it, and I
  join their fight. It had never been tested with a real race.
* New test token `touchsync:<obj>`. Both players stand next to the enemy, which is held still. At
  the same 10 s mark of the shared clock, both step onto it.
* Test, Chapter 1 `room_field1`, plot 100, both with `chaos:10:120:60` (`work/fol/tie2`). Both
  games touched the enemy 0.02 s apart, and both started a fight with both players in it. The
  client logged "the other player got this enemy" and joined the host's battle. Both games logged
  the same turns. The enemy stayed gone in both games.
* Seen in the first try (`work/fol/tie1`, players moved there in the same frame): when neither game
  has the other player on screen yet, each starts its own solo fight with that enemy, as two
  players far apart would. Only a test setup does that: a player has to be next to the enemy to
  touch it.

## Five players in one session, one fight (2026-11-27)

* Up to 8 players could already join. Tested with 5 for the first time: Chapter 1 `room_field1`
  (plot 100, fight party Kris and Susie), encounter 13. The host is Kris, the clients are Susie,
  Ralsei, Kris and Susie (two of them on a taken hero). The host has `chaos:10:120:60`, runs at
  `MP_SPEED=5`, and all the bots pick random menus (`work/fol/five2`). The three games in the fight
  (host, the first Susie, the second Kris watching his SOUL) logged the same 7 turns (HP, TP and the
  enemies' HP and mercy). The two left out (Ralsei, not in that fight's party, and the second Susie)
  stayed on the map. Nobody crashed. (At `MP_SPEED=20` two of the five games stopped logging on
  this PC: five games at 20x is too much load here.)
* What a "proper spectator role" should be is a question for the user, now in TODO.md.

## Chapter 5 platformer: a paper wall's handle a friend pulled down comes down for me too (2026-11-27)

* The paper wall's handle in `room_dw_fcastle_obscured_bullets`, once pulled all the way down, stays
  down for good by a bit of a story flag (1316 bit 0). The game checks that bit only when the room is
  built. Now, when a friend's game sets it, my wall's handle slides down the game's own way and
  stays. Only a bit a friend's game set counts. `mp_plat_fusuma_follow` is prepended to the wall's
  Step.
* Test tool: `mptest.sh` stopped at a failed final screenshot and left the games running. It now
  goes on and closes them.
* Test, both with `chaos:10:120:60` (`work/fol/fus1`): the client set 1316 to 1. The host's game
  logged its handle down and ran on without a crash.

## Chapter 5 platformer: an enemy fight a friend won ends in my game too (2026-11-27)

* The platformer's enemy fights (`obj_plat_combatstarter`: the battle background and waves of flower
  enemies) set a victory bit when won. If my fight had not started, the game's own code already
  counts it beaten when that bit arrives. If I was in the middle of it, it now ends too. Its
  remaining waves stop, and the enemies left go the way the game's own wave time limit removes them.
  Then the fight ends the game's way (`endcombat`: feather sound, the music and camera come back).
  Only a bit a friend's game set counts. `mp_plat_combat_follow` is prepended to the starter's Step.
* New test token `platfight`: the fight starts at once, wherever the figure is.
* Test, `room_dw_cliff_bonuscombat`, both with `chaos:10:120:60` (`work/fol/fight1`). The host
  started the fight. The client set 1731 to bit 18 at frame 700. Mid-fight, the host's game logged
  the fight over and ran on for another 9,000 frames with no crash.

## Chapter 5: paper lanterns and orange walls a friend broke are broken for me too (2026-11-27)

* Paper lanterns (coins, a pinata, an NPC or more lanterns inside) and orange walls are remembered
  by a bit of a story flag too. When a friend's bit arrives while mine is still whole, the lantern
  goes the way the room removes it on return (its NPC, if any, is put back as the room does). The
  wall breaks open with its own break animation and its two barriers go. Only bits a friend's game
  set count (`mp_friend_set_bit`). A wall with no bit (-1) is not remembered by the game either.
  `mp_plat_lantern_follow` is prepended to the lantern's Step, `mp_plat_wall_follow` to the wall's
  End Step.
* Test fix: the early `setflag:<n>:<v>` token parser crashed on the late form `setflag:<n>=<v>@<f>`.
  It now skips a value that has "=".
* Test, `room_dw_fcastle_gloves_tower`, both with `chaos:10:120:60` (`work/fol/lant2`): the client
  set 1320 to 768 (wall bit 8 and lantern bit 9). The host's game logged the lantern gone and the
  wall open. No crash.

## Chapter 5: leaf piles and paper grass a friend broke are gone for me too; only a friend's bits count (2026-11-25)

* Leaf piles (dashed through: coins, a chest or an NPC inside) and paper grass (cut: coins) are
  remembered the same way as the coins and bells. When a friend's bit arrives while mine is still
  whole, it goes the way the room removes it when you come back, with nothing inside and no coins
  (`mp_remembered_follow`: prepended to the leaf pile's Step and the paper grass's End Step).
* Found while testing: several things can share one bit. The three leaf piles of
  `room_dw_garden_firstdash` all use flag 1384 bit 11, and dashing through one removes only that one.
  So the follows (coins, bells, piles, grass) now act only on bits a friend's game turned on.
  `mp_var_array_write` records the bits each received flag turns on (`global.mp_rflagbits`), and
  `mp_friend_set_bit` checks them. My own take never removes more than the game would.
* Tests, both with `chaos:10:120:60`. `room_dw_garden_firstdash` (`work/fol/leaf2`): the client set
  1384 to 2048. In the host's game the 3 piles went, and the client kept its own, as in solo play.
  `room_dw_cliff_eastcliff` (`work/fol/coin2`): the host set 1859 to every bit. Only the client
  removed 16 coins, the pink bell and the paper grass; the host's game, which set them, removed
  nothing. All mpcheck checks pass except `moved` (nobody walks).

## Chapter 5 platformer: a pinata bell a friend broke is broken for me too (2026-11-25)

* Pinata bells are remembered the same way as the coins: breaking one sets a bit of a story flag.
  The gold bell drops its coins and the pink one its pink coin. A friend's bell still whole in my
  room could be broken again for the coins.
* Now, when its bit arrives, my bell does what the room does when you come back: the gold one is
  broken (no coins) and the pink one goes (`mp_plat_bell_follow`, `gml/ch5/scr_mp_plat`, prepended
  to both bells' Step). My own break sets `broken` / `was_hit` at once, so it is never taken for a
  friend's.
* Tests, both with `chaos:10:120:60`: Chapter 5 `room_dw_cliff_eastcliff` (`work/fol/bell1`), with the
  host setting flag 1859 to 1536: the pink bell (bit 10) was gone in both games. In
  `room_dw_garden_aquaplatforming` (`work/fol/bell2`), with the client setting flag 1442 to 3584: in both
  games the pink bell (bit 9) went and the two gold bells (bits 10, 11) broke. No crash, and all
  mpcheck checks pass except `moved` (nobody walks).

## Chapter 5 platformer: a remembered coin a friend took is gone for me too (2026-11-25)

* Pink coins and the cliffs' counted coins are remembered: taking one sets a bit of a story flag
  (`obj_plat_coin`'s `flag`/`flagbit`), so it isn't made again. The flag is shared, but the coin already
  in my room stayed, so I could take a coin a friend had taken, and it counted twice.
* Now a remembered coin whose bit is set while it is still in my room goes, without counting
  (`mp_plat_coin_follow`, `gml/ch5/scr_mp_plat`, prepended to the coin's Step). Only a friend's take
  can do that, because my own take removes the coin at once. The game's
  `ignore_flag_if_plot_greater` is respected. Simplest choice: ordinary coins (not remembered, made
  again on every visit) stay each player's own. Two takes at the same moment, before the flag
  arrives, still both count. `logpuz` logs the room's remembered coins (`[MPCOIN]`).
* Test, Chapter 5 `room_dw_cliff_eastcliff`, plot 100, both with `chaos:10:120:60` (`work/fol/coin1`):
  the host set flag 1859 to 2 (bit 1, as a take does). Both games went from 16 remembered coins to
  15 ("a friend took coin flag1859 bit 1"). All mpcheck checks pass except `moved` (nobody walks).

## A Z chat that moves the story stays a chat (Chapter 1 throne room, 2026-11-25)

* Chapter 1 `room_cc_throneroom`, plot 242: talking to Lancer (`obj_npc_facing`) is a long chat that
  sets plot 243. It has no cutscene controller and no actors, so the Z check keeps it local. The other
  player isn't pulled in and only gets the new plot (shared as usual, their room is built again for it).
* Test, both with `chaos:10:120:60`, the host `touch:obj_npc_facing@500` with `mash` (`work/fol/zthrone1`).
  The host's chat ran to its end. The Z check logged `master -1/-1 plot 243/242` and didn't call it a
  scene. The client got `room refresh: plot 242 -> 243` and stayed free, and all mpcheck checks pass.
  No code change.

## Test token for playing a Chapter 4 bookshelf piano for real (2026-11-25)

* `pianoplay:<i>:<dir>@<f>` (`scr_mp_shelf`): at room frame f Kris stands on the upper floor's nearest
  step (the pianos only work from there). Then he goes under the i-th piano and uses it, facing up.
  He holds direction dir with Z and at the end holds X to leave. Keys a test wants pressed are left
  in `global.mp_test_keys` and pressed by the next frame's `mp_test_tick`. Keys set from the room
  object's own Step came too late, because the pianos read input first.
* Test, Chapter 4 `room_dw_church_bookshelfpuzzle`, plot 242, both with `chaos:10:120:60`
  (`work/fol/pianoshelf5`, `pianoshelf6_*`): the piano engages (con 2), the move is tried (the
  piano's key buffers fill), but the blue shelf doesn't slide in any of the 4 directions. Two plain
  wall blocks (at 1160,1200 and 800,1240) already touch its base, in a room entered with `party`.
  So the shared shelf move is still only covered by the flag test (`shelf2`); re-check in play (TODO).

## Chapter 4 piano puzzle: solved by one, solved for everyone (2026-11-24)

* `room_dw_church_pianopuzzle`: playing the right tune on the piano opens the cage, sets story flag 892
  (shared) and starts a scene. A friend's solve already reached me as their scene (pulled in and
  watched), but my room kept its cage and would have solved again, scene and all. Now when flag 892
  arrives while my room still waits, the room jumps to the solved state it uses when you come back
  later: cage gone, piano done, no second scene (`mp_piano_puzzle_follow`, `scr_mp_shelf`).
* Simplest choice: the solve is shared, not each note. Playing the piano stays each player's own;
  the tune only counts in the game of the one who plays it.
* The organ room (`obj_dw_church_organpuzzle`) is left local on purpose: it plays songs for Susie's
  and Ralsei's reactions, with nothing to solve; a scene it starts is shared the usual way.
* Test token `pianosolve:<f>` (the piano counts as played right at that room frame); `logpuz` logs
  the room (`[MPPIANO]`).
* Test, Chapter 4 `room_dw_church_pianopuzzle`, plot 250, both with `chaos:10:120:60`, `mash`
  (`work/fol/piano2`). The client solved it, got the scene lock and played the scene. The host's room
  followed (con 99, cage gone), the host watched P2's cutscene, and its scene didn't play a second time.

## Chapter 4 bookshelf puzzle shared; the train tracks stay local (2026-11-24)

* **Bookshelf puzzle** (`room_dw_church_bookshelfpuzzle` and its reversed copy): the remote pianos
  slide the coloured shelves (`obj_bookshelf_moveable2x2`). The game already keeps each shelf's place
  in two story flags (876-881), written when a move ends, and story flags are shared. So now a shelf
  follows its flags: when they say it is somewhere else (a friend moved it in their game), it slides
  there the way a reset slides it (`mp_shelf_follow`, new file `scr_mp_shelf`, Chapter 4 only; hook
  right after the shelf writes its own flags, so my own move is never undone). Someone entering the
  room later already got the shelves from the flags (the game's own Create). Simplest choice: no new
  message. Two players moving the same shelf at once end where the last move put it, in every game.
* **Train tracks** (`obj_traintrack_switch`, `obj_train_switch`): pressed only by the heart
  (`obj_homealone_heart`) or a snowball, in the Light World section where the player walks a heart
  at home alone. That is a solo part of the story, so it is left local on purpose.
* Test tokens: `shelfflag:<i>:<dx>@<f>` (as if a friend's game had moved the i-th shelf: its place
  flag changes) and `moveshelf:<i>:<dir>@<f>` (slide it as its piano does; in the test it didn't move,
  since the room decides which walls count from the floor the player stands on). `logpuz` also logs
  the shelves (`[MPSHELF]`).
* Test, Chapter 4 `room_dw_church_bookshelfpuzzle`, plot 242, both with `chaos:10:120:60`
  (`work/fol/shelf2`): the client's shelf flag went from 1120 to 1040. Its own shelf slid there, the
  flag reached the host, and the host's shelf slid to 1040,1120 too. Not run: a move made with a
  real piano.

## ACTs with their own little game: the hero's player plays them (2026-11-24)

* Some ACTs open a little game of their own (listed in MINIGAMES.md): Maus' baskets and Tasque
  Manager's quiz (Chapter 2), Tenna's "popular boy" (Chapter 3), and Flowery's ACT menu, the scissors,
  sharing food and the pink nodes (Chapter 5). Only the battle menu was replayed, so each game played
  it with its own player's keys, and the host's result won at the turn's end (the TURN_GO message
  carries its enemies' mercy). Now, while one of those objects is running in the acting phase
  (`mp_actg_*`, end of `scr_mp_battle`):
  * The owner of the acting hero plays it. Their keys (held or pressed) are sent each time they
    change (message 58, kind 0). The other games play those keys instead of their own, one change per
    frame, so their copy looks about the same, a little later.
  * When it ends, the owner sends how much it changed each enemy's mercy and HP (kind 1). The other
    games correct their mercy by the difference from their own copy.
  * Simplest choices: a list of objects (one line per new ACT game), and mercy is corrected but HP
    only logged (an attack landing inside one game's window would otherwise count twice; the turn's
    end still brings the host's HP).
* Test token `fakeactg`: as if an ACT game ran for 90 frames at each fight's first hero action; its
  player gains 10 mercy on the first enemy, in their own game only.
* Tests, Chapter 2 `room_dw_cyber_maze_virokun`, encounter 53, bots, `chaos:10:120:60`:
  * `actg1`, 20x, host plays Kris: the client played the host's key changes and its mercy was
    corrected by +10.
  * `actg2`, 20x, client plays Kris (host `charto:2@60`): the host was told "P2 plays it" and corrected
    by +10. At 20x the 90-frame window ended before the keys arrived (0 played), and the HP difference
    (-46) showed why HP isn't corrected. mpcheck: all PASS.
  * `actg3`, at 2x, the same: 22 of the 28 key changes were played in the host's game before the
    window ended, and mercy was corrected by +10.
  * Not run: the real ACTs. The bots don't pick a given ACT.

## A watcher's character touches nothing (2026-11-24)

* From the code review: while I watch someone (F9 "Watch"), my hidden character stands where they
  are so the camera follows them, and it could still touch things in my game. An enemy wandering
  differently in my game could start a fight of mine and pull the others in, and a trigger zone
  could start a scene. Now my character gets an empty collision mask (the game's own `spr_nothing`,
  which it uses for the same thing on bullets) while it stands in for the camera. The mask is given
  back when watching stops, or when a fight, a scene or a pull takes over. Where the chapter has no
  `spr_nothing`, nothing changes.
* The check for friends standing on floor switches borrows my character to test their spot, so it
  puts the real mask back for that test. The first run showed why: while I watched, the switch my
  friend stood on stayed up in my game.
* Tests, all with `chaos:10:120:60`:
  * Chapter 5 `room_dw_fcastle_foxhunt_chaos`: the host watches P2, who stands on the switch. It was
    pressed in both games about 1 s apart, and the mask came back when P2 left (`work/fol/specmask2`).
  * Chapter 2 `room_dw_cyber_intro_1`, 3 players, at 20x: P2 watched the host, then P3 in the other
    room, and was warped there; the mask was given back for the warp and emptied again in the new
    room (`work/fol/specmask3`).
  * Not reproduced: an enemy or trigger actually set off by a watcher. There is no deterministic
    setup for that here.

## A watcher no longer holds floor switches (2026-11-24)

* From the code review: a player watching another one (F9 "Watch") has a hidden figure standing where
  the watched player is, and it still held floor switches down in the others' games. `mp_puz_ghost_here`
  now also skips players whose figure isn't drawn (`mp_pvis`). Small in play: the watched player
  usually stands there too; it mattered when they were in a fight (skipped) or moving away.
* Test, Chapter 5 `room_dw_fcastle_foxhunt_chaos`, plot 100, 3 players, all with `chaos:10:120:60`:
  P2 stands on the switch at 460,460 (`away:...:900:465:430`), P3 watches the host, then P2
  (`watch:300`, `watchnext:1300`). The switch is pressed in all three games once P2 is on it (host 11,
  P2 12, P3 12 log lines pressed): the friend's figure still holds it, the watcher's adds nothing.
  `work/fol/specswitch3`.

## Clearer version check on joining (2026-11-24)

* HELLO now also carries the mod's build number (`global.mp_build`, raised with each release; 19 now)
  after the network version. When they don't match, the joining player reads "Different versions: the
  host has build 19 (network 12), you have build 18 (network 11)" and who must update ("Update yours:
  open the DELTARUNE Online launcher..." or "The host needs to update..."); the host sees "P2 couldn't
  join: build 18, you have build 19". An older mod that sends no build is shown as "an older build"
  (`mp_version_text` in `scr_mp_net`). Simplest choice: only the network version decides who may join,
  as before; the build number is only shown.
* Long notifications now wrap at 68 characters (`mp_notify`), so the message fits on screen.
* Test token `fakever:<network>:<build>` pretends to be another version. Tests, Chapter 5, with
  `chaos:10:120:60`: `ver_old` (client `fakever:11:18`: client told to update, host note), `ver_new`
  (client newer: told the host must update), `ver_same` (joins, "P2 joined!"), `ver_old2` (screenshot:
  the wrapped note fits on screen). All in `work/fol/ver_*`.

## Spectator jumps between players; who is reading (2026-11-24)

* Watching (F9 "Watch") already switched players with left/right; now tested with three players in two
  rooms: the watcher goes to the next player's room straight away (`mp_spec_tick`'s warp). New test
  tokens `watchnext:<frame>` (as pressing right) and `<name>/<token>` (a token only for the player with
  that name: all clients get the same tokens). Test, Chapter 2 `room_dw_cyber_intro_1`, 3 players,
  `chaos:10:120:60` (`work/fol/spec3`): P3 went to `room_dw_cyber_intro_2`, P2 watched the host, then
  switched to P3 and was warped to P3's room; only P2 watched and only P3 left (the per-player tokens
  work); mpcheck passes except "moved".
* "(reading)" in the player list (`mp_player_reading`): someone talking to an NPC on their own (the talk
  bubble's text, as before), or, in the shared cutscene I'm in, someone whose copy of the current box
  hasn't finished (each game already reports its box and whether it's done, message 60; the same box
  check the page turning uses). No new message. Test token `logreading`. Test, Chapter 2 Queen boxing
  scene, client joining late and watching (`work/fol/read2`, and `read1` with `chaos:10:120:60`): the
  host shows P2 as reading on each box (0-15) and P2 shows the host as reading on each box. (The first
  version compared box numbers, which differ between the leader and the watchers: the host never saw
  P2 reading; it now checks the box key.)

## Map ping: F5 (2026-11-24)

F5 (free in every chapter and in the mod) sends a ping (new message 85: the room; at most one a
second). For 3 s, everyone in the same room sees an arrow in the pinger's colour bouncing above their
name tag (the pinger sees it over themselves too), drawn in the GUI from the position they already have;
when the pinger is off screen the arrow sits at the screen's edge pointing their way. Players in another
room get a note: "P2 pings from another room (room_name)." Simplest choice: no new position data, the
ghost's own position. Test token `pingat:<frame>`. Tests (host + client):
* Chapter 5 garden room (`work/fol/ping1`): both notes arrive, arrows over each other; the first arrows
  sat too low (on the name tag), so they were moved and made bigger.
* Chapter 2 `room_dw_cyber_intro_2`, `chaos:10:120:60` (`work/fol/ping3`): the client walked through a
  door before pinging, and each got the "from another room" note with the other's room; mpcheck passes.
* Same room, one walked away (`work/fol/ping4`, `ping5`): first the arrows were on the head (the ghost's
  collision box isn't its drawn sprite); now they use the name tag's anchor and sit just above it, for
  both players' arrows (screenshot `ping5/c1_5.png`).
Not seen on screen: the edge arrow for a player off screen (TODO).

## Quick messages: F9 "Say" (2026-11-24)

A new F9 row in a session, "Say: < Wait for me! > (Z: send)": left/right picks one of ten fixed
messages (Wait for me!, Come here!, I'm saving., Let's go!, Yes, No, Thanks!, Be right back, Help!,
Over here!), Z sends it and closes the menu. Simplest choice: a fixed list, no typing (typed letters would
also reach the game as key presses), and only its number goes out (new message 84, forwarded by the
host; an older version just ignores it, so no protocol change). Everyone gets a note ("P2: Come here!",
"You: ..." for the sender) and the text shows for 4 s in a bubble over the sender's figure (the talk
bubble). At most one a second. New test token `chat:<i>@<frame>`. Tests, Chapter 5, host + client:
`work/fol/chat1` (`chaos:10:120:60`): each side's message reached the other; mpcheck passes except
"moved" (nobody walks). `work/fol/chat2` (screenshots): the client shows "Come here!" over the host and
the host shows "I'm saving." over P2, with the notes at the bottom. README lists "Say" and "Watch".

## F9 "Save logs for a bug report" (2026-11-24)

A new F9 row zips `multiplayer_log.txt`, `multiplayer_log_prev.txt` (the session before: after a crash
and a restart, that's the one that crashed) and `multiplayer_crash.txt` from the save folder into
`DELTARUNE-Online-logs-<date>-<time>.zip` on the desktop, and says so on screen. GameMaker can't write
outside its save folder or make zips, so it's a function in the mod's DLL (`drs_report_zip` in
`steam/drm_steam.c`, declared in `mod/extensions.txt`; `tools/buildsteam.sh` now links shell32 for the
desktop folder). Simplest choice: the files are stored, not compressed (a few MB of text; no zlib).
New test token `reportzip` (frame 400, into the save folder instead of the desktop). Test, Chapter 5,
host + client, `chaos:10:120:60` (`work/fol/zip1`, `zip2`): the zip is made, Python's zipfile reads it
without errors, and its three files match the ones on disk; mpcheck passes except "moved" (nobody walks).
The desktop path was checked by calling the DLL directly: the zip appeared on the desktop, was valid, and
was deleted. README, CONTRIBUTING.md and the package's READ ME FIRST.txt point to the button.

## CONTRIBUTING.md (2026-11-24)

For helpers (the coop-anything server): what's needed, building (patcher, chapters, launcher), one
targeted test with `mptest.sh` + `mpcheck.py`, the common test tokens, the ready-made scenarios, where
each part of the code is, the hook file format, how messages are built and numbered (next free type 84,
one message at a time, raise `mp_version` when a message changes), GML notes and what a bug report needs.
Linked from the README's Contributing section. Checked against the code (function names, token formats,
hook directives, log file names); no build needed (documentation only).

## Joining mid-cutscene and coming back after a crash, every chapter (2026-11-24)

`tools/latejoin.sh` now has a crash scenario for each chapter (`ch1crash`, `ch3crash`, `ch4crash`,
`ch5crash`, like `ch2crash`: the client's game is killed 24 s in, mid-scene, and started again; always on a
bad network) and `XT=<tokens>` adds tokens to both sides of any scenario. No code change was needed.
Results (speed 20, `chaos:10:120:60` everywhere):
* Crash, Chapters 1, 3, 4, 5: the restarted client joins again, is pulled into the host's scene and
  watches it ("Watching Host's cutscene"); in 1, 4 and 5 it goes back to where it was when the scene
  ends in its own room; in 3 it follows the host's scene on to `room_torhouse_sepia`. The only mpcheck
  failure is the killed game itself ("stopped responding"), plus "nobody moved" in Chapter 1.
  (After a restart the client may get its old player number back; mpcheck then lists only the
  before-crash log for it.)
* Joining late, Chapters 1-5 on a bad network (`work/t_late_ch*_x`): pulled in and watching in each;
  Chapter 3 goes on into the story fight together; all end in the same room. Chapter 2's state check
  shows the known test artifact (the room starts at plot 53, its scene writes 33 in the host's game,
  the client refuses the stale 33, and both end at 53).

## Code review: a counter sent in the middle of the flag message (2026-11-24)

Found reviewing the code: when an ordinary flag and a counter flag changed in the same scan, the counter's
message 83 was built in the same buffer the flag message was still being written to (`mp_begin` starts the
buffer again), so the ordinary flag changes were lost and the end of the flag message went out as a second
copy of the counter (counted twice). Counters are now collected and sent after the flag message. Also
removed `mp_sync_follow` (never called). Test token `bumpflag` now also sets flag 1600 + the player's number
in the same scan slice. Test, Chapter 5, flag 1905, 40 each, `chaos:10:120:60` (`work/fol/bump5`): both games
ended with the counter at 80 and flags 1600-1601 at 40,40; mpcheck scene/music/world PASS. Release v18
(`v1.1-dev-18`) was published before this fix; it goes in the next one.







## Following someone's music: their volume and pitch too (2026-11-24)

A player who took another player's song (moved to them, or watching their cutscene) played it at full volume
and normal pitch, while some Chapter 1 scenes play theirs quieter and slower (`mus_loop_ext`, e.g. 0.7 and
0.75). The song announcement (message 34) now also carries the song's volume (the song's and the playing
copy's gain, without the player's own volume setting) and pitch, sent every 2 s so fades come along; the
follower plays it with both and keeps the volume updated while it plays their song. New test token
`songext:<volume>:<pitch>`. Test, Chapter 1, host playing `lancer.ogg` at 0.7/0.75, client brought over with
`gotohost`, `chaos:10:120:60` (`work/fol/vol5`): "music follows player 0: lancer.ogg at 0.60, pitch 0.75"
(0.60 = 0.7 x the volume setting 0.85, the same as the host's), music clock in sync (drift under 0.07 s).

## Counter flags add up between players (2026-11-24)

Story flags the game only ever counts up (kills, times talked to someone, Chapter 5's slashes...) kept the
last writer's value: the shared state is sent as absolute values, so two players counting at the same time
both sent "old + 1" and one count was lost. Now those flags go out as additions (new message 83, "flag n
+= d", forwarded by the host; protocol version 12), and an addition received is added to the copy last
synced too, so it isn't sent back. Which flags: found by scanning each chapter's code for `flag[n]++`,
`+= 1` or `scr_flag_set(n, scr_flag_get(n) + 1)` with no other writes except resetting to 0 (a list per
chapter in `mp_flag_counter`). A counter set back (to 0) still goes out as a value; joining and loading
still send the full state. New test token `bumpflag:<n>:<count>` (both games count at the same moments of
the shared clock). Test, Chapter 5, flag 1905, 40 each, `chaos:10:120:60`: with values (first try) both
ended at 12; with additions (`work/fol/bump4`) both at 80. Also: Light World walking sprites: Noelle's are
already used; Ralsei has none in any chapter's files, nothing to do. Snowgrave route: not tested (it needs
a long chain of Noelle choices in Chapter 2 fights that the bots can't play).

## A player standing still shown right away on a bad network (2026-11-24)

The position of a player who isn't moving is only sent again every 1.5 s, so on a bad network a lost first
position left them missing from the others' screens for up to 1.5 s when they arrived or someone joined.
Now it goes out every 250 ms for the first 3 s in a room and for 3 s after someone connects (both sides:
the host when a player joins, the newcomer when it's in). Test: Chapter 1 `room_field_secret1` (plot 30),
both standing still, `chaos:10:120:60`: before, the ghost check failed in all 4 runs (11-39 problems right
after "P2 joined", `stillbase1-2`, `still1-2`); now it passes in all 3 (`still3-5`). ("moved" fails there
only because nobody walks in this test.)

## Pulled into a fight, taken out by a door first (2026-11-24)

In `room_dw_garden_aqua` 291 (chaos, `aqua9`, `aqua10`) the pulled player sometimes went through a door to
`room_dw_garden_wateringcan_aqua` on the room's second frame and never reached the fight. Its game only
creates the fight's invisible enemy a few frames after the room starts (`mp_warp_delay`), and was free to
move until then, standing on the door at the leader's spot. Now a warp into a fight holds `interact` at 1
until the fight starts. Test: three runs with `chaos:10:120:60` (`aqua11`-`aqua13`): all six pulls reached
the fight, every check passes in all three.

## Called to a fight that already ended: no 7 s wait (2026-11-24)

A player pulled into a fight whose pull arrives late (slow network) waited 7 s at the "!" before "the fight I
was called to is gone", with the pre-fight text and song on. Now the player who called them is watched: seen
in the fight and then out of it again (a Game Over right away, a quick win) ends the wait at once
("encounter: the fight I was called to ended before I got there"). On cancelling, a story fight's party taken
from the pull is put back to the party I had before it, and not applied again at the next room start
(`aqua7` showed the client keeping the fight's party 100 for 7 s while the host was back to 123).
Tests, `room_dw_garden_aqua` 291 with `chaos:10:120:60`: `aqua7` hit the case (ended 0.1 s after the
caller's Game Over instead of 7 s); `aqua8` all checks pass (the host came in at turn 1, as a late joiner).
The party put back on cancel wasn't hit again in two more runs (the race is rare); built and reviewed only.

## Chapter 5 platforming with movement (2026-11-24)

`room_dw_garden_aquaplatforming` (plot 291), two players with `wander` and `mash` and `chaos:10:120:60`
(`work/fol/plat1`): the host ran, jumped, slashed and landed across x 2000-3600 (sprites `slash_ground`,
`slash_air`, `land`), the client (Susie) stood near the end; the client's view of the host passed the ghost
check 456 times, sync 482, follower 481, no crash. Not run: the Chapter 1 new game (the vessel creation
writes the game's own save files, and tests must not write saves).

## Story scenes started with Z are shared (2026-11-24)

Pressing Z on Chapter 2's arcade machine (`room_dw_cyber_queen_boxing`, plot 33) starts the whole Queen
boxing scene, but anything started with Z was taken as "only mine": the other player stayed free at the old
story point (`work/fol/zscene1`). Now a Z-started interaction is a story scene when, within 5 s, a new
cutscene controller runs it and it hides the player, moves the story or brings in actors. Save points, shops
and chats do none of that. The "before" state is the room on the last free frame: the scene's first step
runs in the same frame as the Z, before the mod's check (`zscene6`, where the arcade's controller and actors
counted as "already there"). A Z chat also no longer counts as "my own scene starting" when someone else's
pull arrives (it isn't switched off). The `touch` token now also sets `global.facing` and picks the newest
instance. Tests, both with `chaos:10:120:60`: arcade (`zscene8`): "started with Z, but a story scene", the
other player watches the host's scene; all checks pass. Chapter 4 save point (`touch4`): still local, no
pull, all pass.

## Z-started things stay local: save point checked in Chapter 4 (2026-11-24)

New test token `touch:<obj>@<f>`: f frames into the room, stand just below the first `<obj>` (collision
boxes lined up), face it and press Z. Test: Chapter 4 `room_dw_church_savepoint` (plot 289), the host
touches `obj_savepoint`, the other player stands in the room, both with `chaos:10:120:60`
(`work/fol/touch3`): the save menu opens on the Z (`z=0`), nothing is pulled, the other game stays free; all
checks pass. On the way (`touch2`): a Z put in by the test after the game's own Z check isn't seen, so the
open save menu looked like a scene after 5 s and pulled the other player; the token now records its Z like
`mash` does. A real player's Z is seen by the check, so play isn't affected. Not run: shops and the C menu
(the C menu sets interact 5, never taken for a scene), NPCs in Chapters 3-5.

## `room_town_school` plot 100 crash: the test's start, not the mod (2026-11-24)

Run with the host alone (`work/fol/school1`, and `school2` with `lightworld`): it crashes the same way with
nobody connected, on the room's first frame ("Trying to draw non-existing sprite", `obj_actor` Draw). Plot 100
is a real story point here: the room makes `obj_ch5_LW11A` (Noelle by the school), whose trigger is
`x <= 260, y >= 160`. The test's `room_goto` puts Kris at the room's default spot, already inside that
trigger, so the scene makes its actors (`scr_maincharacters_actors`, copying the followers' sprites) on the
very first frame, before the followers have a sprite. In the game you arrive through a door, away from the
trigger. The mod doesn't touch this scene or actor creation. Choice: no change; for this room, test with
another plot or arrive by walking in.

## Story fight "deadlock" on a bad network: a test artifact (2026-11-24)

The stuck `room_dw_garden_aqua` 291 fight with `chaos:10:120:60` (`work/fol/aqua5`) was the test: both games
ran `mash`, which doesn't press keys inside battles, so the leader sat in Kris's menu and the late pulled
player waited for the next turn, as designed (a player who arrives after turn 0 was released enters at the
next TURN_GO). Re-run with `bot` (`work/fol/aqua6`, chaos): turns 0 and 1 played in both fights, a Game Over
and Continue, no crash, char/follower/sync/battle checks pass. The `mash` doc now says to add `bot` for
battles. Seen: a pulled player whose pull arrives after the fight already ended keeps the pre-fight text and
song for ~7 s until "the fight I was called to is gone" (one music-check hit); noted in TODO, low priority.

## Story fight party changed back by the room (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| Chapter 5 `room_dw_garden_aqua` 291: the story fight is Kris alone (the room's script calls `scr_setparty(0)` first), but a player pulled into it fought with Kris, Susie and Ralsei: the pull took the leader's party, then the pull's warp entered the room again and the room's Create (`setparty(1, 1)`) put the whole party back. Turn 0 differed between the games. | The pull keeps the leader's party (`mp_pull_party`) and Room Start (after the room's Create events) puts it back if the room changed it; cleared when the fight starts. Logs: the party sent with a pull and taken from it. New test token `dbgchar` (logs party changes from the shared state with the call stack). | **Tested**, 2 players, 20x, twice: "room start: the fight's party 100 again (the room set 123)", turn 0 identical, every check passed. With `chaos:10:120:60` the party was put back the same way; that run then hit a separate deadlock (TODO.md). |

## Rooms that hide or move the followers (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| Rooms whose own controller hides the followers (`with (obj_caterpillarchara) visible = 0` in a room object's Create) were never checked with two players. | None needed for the followers. | The room objects that do it were listed from the decompiled code (1/4/13/25/21 per chapter, cutscenes left out). Six of them run with 2 players, bots, 20x, the client joining from another room: `room_dw_changing_room` 169 and `room_dw_console_room` 279 (Ch3), `room_lw_church_office` 219 and `room_dw_churchb_fountain` 229 (Ch4), `room_dw_garden_aqua` 291 and `room_town_school` 100 (Ch5). The follower check passed in all six. Two other problems found there are in TODO.md (a story fight's party in `room_dw_garden_aqua`, a crash in `room_town_school`). |

## Positions held back by a resend backlog (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| After a Game Over through the CONTINUE screen on a bad network, the host kept the client's old position for about 7 s (the client wasn't shown) although the client sent its new one. Cause: each frame a peer gets at most 4 datagrams; reliable messages went in first, and with a big backlog of resends (a room change sends a lot) they filled all 4 and the function returned before the positions. | `mp_flush_peer`: the newest positions (unreliable, small) go in first, the reliable messages after them. Same packet format. | **Tested**, the same scenario (Chapter 2, "Everyone" fights, the client joining mid-fight, wipe, CONTINUE, `chaos:10:120:60`): every check passed (before: 71 "not shown"). Two normal 2-player fights with chaos: one passed everything, the other had 19 "not shown" right after joining (the other, older issue in TODO.md low priority). |

## Joining while the host is in a fight (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| A player who joined the session mid-fight ("Everyone" fights: pulled in, playing from the next turn) kept their own game's full HP for the hero they took over (Susie 140 against 112 in the host's game): the turn state differed. | `mp_apply_tgo`: the first turn-go of a fight a player joined late (waiting for turn 0, the leader further on) gives their own heroes the fight's HP too. `mpcheck.py`: "players reached different turns" compares the last turn reached, not how many (a late joiner sees fewer). New test token `battlesolo` (the host starts the fight before anyone joined). | **Tested**, Chapter 2, encounter 53, `everyone`, 20x: the host fought alone, the client joined at turn 2 and was pulled in; turn 2 identical in both games, then the same Game Over. With `chaos:10:120:60` it joined at turn 4, turns 4-5 identical. Open-world fights (default): the newcomer stays on the map, by design; see TODO.md. |
| Open-world fights (default), walking up to a fight that started before you joined: never run. Running it showed that on a bad network the fight's leader could keep a player's hero HP from before their last hit (the HP report, message 43, arrived after "turn done", 44, so the turn's state was one hit behind for every turn after). | "Turn done" now carries the HP of the sender's heroes; HP reports and "turn done" are numbered per sender and an older one arriving late is ignored (`mp_hp_newer`; the numbering restarts when a player leaves). Protocol version 11 (everyone needs this version). New test token `sturdy` (heroes with 10x HP: the host alone survives long enough). | **Tested**, Chapter 2, encounter 53, host fighting alone from the start, the client connecting later, walking up (`walkup`) and pressing Z (`joinat`): joined at turn 3, every turn identical, all checks passed. With `chaos:10:120:60`: joined at turn 7, all 8 turns compared identical (before the fix: turns 7-10 differed by one hit). A normal 2-player fight with chaos: battle check passed. |

## Changing character mid-session (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| Changing character through F9 during a session was never tested. | The F9 code moved into `mp_char_change(c)` (also used by the new test token `charto:<c>@<frame>`). `mpcheck.py`: the "char" check skips the one sample taken in the frame of a change (the sprite follows a frame later). | **Tested**, Chapter 2, 2 players, 20x: the client (Susie) changed to Ralsei at frame 600; its own figure and the host's ghost of it became Ralsei, and the host's fight a little later was Kris + Ralsei with the client playing Ralsei. Every check passed. With `chaos:10:120:60` the same, except "host not shown" for about 0.5 s right after joining, before the change (the known slow first position on a bad network, TODO.md low priority). |

## Chapter 4 church, plot 289: no error any more (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| Sweep of 2026-10-10: `obj_ch4_DCB03` Step, "Variable obj_ch4_DCB03.su... not set" in `room_lw_church_main` (the game sends it on to `room_lw_church_entrance`, where `obj_ch4_DCB03` is), plot 289, 2 players. | None needed: gone since (fixed by later changes). | Re-run, 2 players, 400 s game time with the client walking around: no error, no crash, every check passed; the same with `chaos:10:120:60`. |
| The door ghost cases at the top of town rooms (left in TODO.md although rechecked on 2026-11-23). | None needed. | Again, `room_diner` plot 45, Light World, both players with bots walking through the town, `chaos:10:120:60`, 20x: every check passed (ghost 224, sync 2051). |

## Chapter 5 platformer: each player as their own character (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| In the platforming sections everyone was drawn as Kris (the game's platformer figure is always Kris). | A player who plays Susie or Ralsei sends the matching sprite of the game's own platformer follower for that character (`spr_idle`, `spr_run`, `spr_halt`, `spr_turn`, `spr_jump`, `spr_fall`, `spr_land`, `spr_climb`, picked from the name of Kris's current sprite), placed with its feet where Kris's figure stands. Kris and Noelle (no platformer sprites) stay Kris. Simplest choice: only what the others see changes; your own figure is still the game's Kris. | **Tested**, `room_dw_garden_aquaplatforming`, 2 players: a Susie player sent `spr_plat_susie_run/idle` and every check passed (ghost, sync, follower); a Ralsei player, with `chaos:10:120:60`, sent `spr_plat_ralsei_run/idle`, ghost checks passed, and the host's screenshot shows Ralsei running on the floor. |

## Fights with their own rules: one player plays them (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| Special fights (Spamton NEO, Queen, Giga Queen, Berdly's plug, Chapter 3's Knight, Shadow Mantle and Tenna's board fight, Chapter 4's Titan and Gerson's) have their own rules and only partly sync hero by hero. | `mp_battle_special()` checks the fight's enemies against that list; there the fight's leader plays every hero and everyone else watches (hidden SOUL, the way a player whose character isn't in the fight watches). Everyone is told who plays. Simplest choice: a list of enemy objects; single fights can be synced one by one later. | **Tested**, Chapter 2, Spamton NEO (encounter 61), 2 players with bots, 20x: the host played Kris and Susie, the client watched; both games went through the same turn and phase steps, then the same Game Over and Continue. The same with `chaos:10:120:60`. The other fights on the list: built, not run. |

## Host change: Steam and IP together (2026-11-24)

| Problem | Fix | Test |
|---|---|---|
| A new host who had joined by IP opened only UDP, so the Steam players looked for a lobby that never came. | The host now sends the session's Steam code with the address list (message 8, added at the end; older versions ignore it). The new host opens a Steam lobby with that code whenever Steam starts on their PC, plus UDP on the same port as before; without Steam, UDP only. IP players still reconnect by IP, Steam players by code. | IP side **tested**, 3 players, Chapter 2 (`leaveat:900`, `autohost`): the host left, the next player hosted, the third reconnected in ~3 s; the same with `chaos:10:120:60` (the goodbye was lost for one player, who noticed after 10 s and took over). **Not testable here:** the Steam side (one Steam account). |
| After a host change a Steam player could land in the old lobby (still there with the same code). | A host-change count: sent in message 8 and set on the lobby as `drm_mig`. A player looking for the new host leaves a lobby with a lower count and looks again (up to 40 times, 3 s apart). Simplest choice: a count instead of the new host's Steam id (an IP player doesn't know it). | Built; Steam side not testable here. |

## Game Over: whoever continues first continues for everyone (2026-11-24)

* Continuing from the Game Over screen (`mp_gameover_continued`, from `scr_load`, or seen on the
  choice) sends message 82; everyone else still on it continues too: the quick retry (Z four times
  while the SOUL breaks, `obj_gameover_init`) if they are still there, CONTINUE on the choice
  (`DEVICE_FAILURE` in `PLACE_FAILURE`) if they got that far. GIVE UP stays each player's own. Each
  game reloads its own save; clients still meet the host once it has reloaded.
* Design choice: anyone's continue counts (not only the host's); the first one wins.

**Tested** (Chapter 1 `room_field1`, encounter 13, both players `nododge`, only the host presses Z on
the Game Over, `chaos:10:120:60`): the host retried, the client got "Host chose CONTINUE." and retried
by itself; both back in `room_field1`. The `PLACE_FAILURE` choice path was not run (the test tokens
only press Z on the first screen).

## Watching another player on the map (2026-11-24)

* F9 **"Watch: < off / name >"** (`scr_mp_spec`): my character is hidden, takes no input and is kept
  where the watched player really stands, so the game's own camera follows them; when they go through
  a door I follow them into that room. Left/right on the map switch between the players; "Watch: off"
  (or the player leaving) stops it. The others don't see me (my character is hidden). Map hazards
  don't hurt me while watching (my hidden character stands where they are: their game takes the hit).
* Design choice (simplest that works): watching is something a player picks in F9. Battles, cutscenes
  and pulls go on as for anyone (watching only acts in free roam); a player with no hero in a fight
  already watches it (SOUL hidden). Not done: switching automatically to watching when a player has
  nothing to play.
* Test token `watch:<frame>`.

**Tested** (Chapter 2 `room_dw_cyber_intro_1`, plot 50, speed 4, with and without `chaos:10:120:60`):
the client watches the host from frame 600: it follows the host's path in the room (184 -> 364 -> 300
-> 184), then into `room_dw_cyber_intro_connector` when the host goes there, ends at the host's spot,
not drawn (`vis=0`); all checks pass.

## Puzzles together: a newcomer finds the blocks where they were left (2026-11-24)

* Someone who joins (or reconnects) gets, with the host's shared state, where the blocks of the rooms
  that players are in were left (`mp_puz_send_all`: message 80 with direction 255, "put it there").
  A player's game no longer forgets those places while it doesn't yet know where everyone is.
* Switches have no lasting state to send (pressing is the shared action), so a switch pressed before
  someone joined is still only known to those who were there; most of them reset when you leave the
  room anyway.

**Tested** (Chapter 1 `room_field_boxpuzzle`, plot 50, speed 4, `chaos:10:120:60` in both games): the
host pushed a block up twice alone, the client connected afterwards (`connectat:600`) and its block is
at 280,240 like the host's.

## Puzzles together: Chapters 3-5 (2026-11-24)

* **Chapter 5 pushable blocks** (`obj_pushable_block`, the garden): the same sharing as Chapter 1's
  blocks (message 80; someone entering the room finds them where they were left); a push played from
  another game also stores the block's place in its flag, as the game does.
* **Floor switches, Chapters 4 and 5** (`obj_floorswitch`): those the player can press
  (`maincharapressable`, e.g. `room_dw_fcastle_foxhunt_chaos`) are held down by a friend standing on
  them too (`mp_puz_ghost_here`). (The garden's switches only take blocks: shared through the blocks.)
* **Chapter 3 glowing tiles** (`room_dw_couch_overworld_03`): the hourglass is shared like Chapter 1's
  (the tiles were already pressed by the others' figures in every chapter). Not run separately.
* Left local: the Chapter 3 board's tiles and blocks (each player plays their own board), Chapter 4's
  bookshelf, piano, ripple and train-track puzzles, Chapter 5's castle puzzles (to look at one by one).
* Test token `pushblock` takes several frames (`pushblock:1:300/340/...`) and Chapter 5 blocks.

**Tested** (speed 4, both games with `chaos:10:120:60`): `room_dw_garden_mushrooms`: the host pushed
the block right: 840,720 -> 880,720 in both games (further pushes refused by the room itself, in the
host's game). `room_dw_fcastle_foxhunt_chaos`: the client stood on the switch at 460,460: pressed in
its game and, from then on, in the host's.

## Puzzles together: Chapter 2 traffic lights and the alley switch (2026-11-24)

* **Traffic light switches** (`obj_traffic_switch`, the city's traffic rooms and the mansion's): a
  press in one game presses the same switch in every game in the room (message 81). The message now
  also carries the presser's facing, used for the press in the other games (the switch refuses a
  press made facing down, so it must be the presser's).
* **The alley floor switch** (`obj_alleySwitch`, `room_dw_city_big_2`): held down in my game by
  another player standing on it too (`mp_puz_ghost_here`: my character's own collision mask tried at
  their real position, the same test their game makes), so two players can hold both switches.
* Not done: the mice rooms' switches (`obj_mouseSpawnSwitch`, `obj_mice2Switch`,
  `obj_mice3_platSwitch`: they release mice that move on their own), the shape puzzle (one player
  steers a piece: a minigame), the keyboard puzzles. No placed `obj_pushable_block` in any Chapter 2
  room, so nothing to share there.

**Tested** (speed 4, both games with `chaos:10:120:60` and without): `room_dw_city_traffic_1`, plot
75: the host (facing up) pressed the switch at 1144,176: on in both games. `room_dw_city_big_2`,
plot 75: the client stood on the switch at 480,1120: pressed in its game and in the host's.

## Puzzles together: the rest of Chapter 1 (2026-11-24)

* **Suits puzzles** (`obj_suitspuzz` with its three buttons: `room_field_secret1`, the suits scene
  room and the clover room in the forest): a button pressed in one game presses the same button in
  every game in the room (the switch message, 81), so everyone sees the same suits and the spikes
  open for all.
* Design choice, kept local on purpose (each player's own hazard, nothing to solve together):
  the checker paths (`obj_ob_checkertile`, moving tiles to dodge; the reset flash was already
  local) and the forest area 5 lines (`obj_forest_area5_puzzle`, how much the darkner sees *you*).
* New test token `useseq:<object>:<i>@<frame>/...` (use the i-th instance at given frames);
  `logpuz` also logs the suits.

**Tested** (`room_field_secret1`, plot 30, speed 4): the host pressed spade, diamond, swap, the
client then spade: both games show suits 3,4,1; same with `chaos:10:120:60` in both games.

## Watch a cutscene, then go back to where you were (2026-11-24)

* A player pulled into someone's cutscene (the mirror) remembers the room and spot they were pulled
  from (`mp_mirror_start`, `global.mp_mir_home`). When the scene ends **in the room it began in and
  in the same world** (Light/Dark), they go back there (`mp_mirror_home`, `mp_mirror_end`); its story
  changes are already shared. A scene that ends somewhere else (another room, the other world, the
  credits) takes everyone to the leader, as before.
* Design choice (simplest that works): "changes the stage of the game" is decided at the end, by where
  the scene ended, not from a list of scenes. Players who were already in the scene's room go back to
  their own spot in it.

**Tested** (new scenario `cutscenes.sh ch2_return`: both players in `room_dw_cyber_intro_2`, the host
alone walks into the Queen boxing scene): the client watched it and was back at 200,240 in
`room_dw_cyber_intro_2`; same with `CS_EXTRA=chaos:10:120:60`, and `ch2_entry`, `ch2_library`,
`ch2_schooldoor`, `ch2_card_scene`, `ch4_entry`, `ch2_queen` still pass. The "scene ended elsewhere,
follow the leader" branch is the old code path, not run separately here.

## Puzzles together: switches and floor tiles (2026-11-23)

* **Floor tiles** that react to someone standing on them (Chapter 1 `obj_glowtile`, the timed puzzles
  started by the hourglass, and `obj_blocktile`): the other players' figures in my room press them in
  my game, from where their feet are, the way the game does for my own character (the tile's User
  Event 7). No message: every game sees everyone at the same place, so a friend can stand on a tile
  for me.
* **Switches** (`obj_darkeyepuzzle_switch`, `obj_glowtilepuzz`): pressing one sends message 81 (room,
  object, its place), relayed by the host; every game in the room presses the same one.
* Design choice: no host state for switches; pressing is the shared action and each game plays it.

**Tested** (Chapter 1 `room_field_puzzle1`, plot 30, speed 4, both games with `chaos:10:120:60`): the
host presses the hourglass: both games start the puzzle and light the same tile (1170,320); the client
stands on it while the host is far away: in the host's game the client's figure wins the round, both
games then show round 1 won and the same next tiles. (The eye switches use the same message; not run
separately.) New test tokens `useobj:<object>:<frame>`, `logpuz`.

## Cutscene mirror: a sprite drawn again at its old places (2026-11-23)

Report 7's "stretched sprite" in a purple grass scene: the user describes it as a sprite repeating
itself in a cutscene they were pulled into. The cutscene mirror sends the leader's sprites in up to 6
datagrams a frame (unreliable), and a watcher drew each part from whatever frame it last got (up to 8
frames old). When a datagram was lost or late, or a scene had more than 138 sprites (parts 4-6 only
went every other frame), parts of different frames were drawn together, and a moving sprite whose
place in the depth order changed showed both where it is and where it was: a trail of copies.
Now a watcher only draws whole frames (every part of the same frame), keeping the last whole one while
the next ones are incomplete (up to 15 frames), and a busy scene sends all its parts every other frame.
**Tested:** Chapter 2 Queen scene watched by a late joiner with `chaos:10:120:60`: the client's
screenshot matches the host's; the scene plays and ends as before. (The moving-sprite trail itself
wasn't reproduced on purpose; re-check in play.)

## Puzzles together: pushable blocks (2026-11-23)

Chapter 1's pushable blocks (`obj_pushableblock`: the box puzzle in `room_field_boxpuzzle` and the
blocks Rudinn's events make) were only moved in the game of whoever pushed them. Now (scr_mp_world,
"shared puzzles"):

* A push that goes ahead sends message 80 (room, the block's starting place, where the push began, the
  direction), relayed by the host. In every other game in that room the same block slides the same
  40 px (only the block: the pushing player's pause stays theirs). The solved tiles follow by
  themselves (they react to the block touching them).
* Every game remembers where each block was left (room + starting place -> position); a block that is
  created again (someone walks into the room, the room is rebuilt) goes there.
* When nobody is in a room any more, its blocks go back to their places, as the game does when you
  leave a room.
* Design choice: no ordering by the host; each game plays the pushes in the order it hears them.

**Tested** (Chapter 1 `room_field_boxpuzzle`, plot 50, speed 4): the host pushes a block twice: both
games have it at 280,240; with `chaos:10:120:60` and the client's room built again afterwards
(`restartroom`): the block is still where it was pushed; 3 players, both clients pushing at once with a
bad network: all three games end with the block at 280,240. New test tokens `pushblock:<dir>:<frame>`,
`logblocks`, `restartroom:<frame>`.

## The C menu names my character (2026-11-23)

The request was that the party menu's status page show my character's name where it says "Kris" (the
hero in Kris's place is the one I play), not a "You: Susie" label. Now the big name on the POWER (status)
and EQUIP pages goes through `mp_menu_charname` (hook on `obj_darkcontroller` Draw, all chapters): Kris's
place shows my character's name and my character's own slot shows "Kris", the same swap the map does
(my character walks in front, my character's follower is drawn as Kris). Only while character swaps
are on (not in story cutscenes, not when I play Kris). The "You:" label is gone.
Design choice (the simplest that works): only the names; the hero's description ("LV1 Human...") and
the head icons / name plates in the boxes at the bottom (shared with battles) are unchanged.
**Tested** (Chapter 1, P2 plays Susie, `openmenu,menupage:3` + `chaos:10:120:60`): the POWER page shows
"Susie" over Kris's stats; no label. New test token `menupage:<n>`.

## Joining mid-cutscene and coming back after a crash (2026-11-23)

New test tools: the `connectat:<frame>` token (a client connects only from that frame of its game on,
i.e. late) and `CRASH_AT=<s>` in `tools/mptest.sh` (client 1's game is killed after <s> seconds and
started again). `tools/latejoin.sh` runs one scenario per chapter. Three bugs found and fixed:

* **A cutscene that started while the host was alone stayed unshared.** The newcomer went to the host's
  room and started the room's scene again in its own game, then pulled the host into that copy. Now a
  story cutscene that starts while nobody else is connected is remembered, and when someone joins while
  it is still going it becomes the shared scene (scene lock + pull), so the newcomer watches the host's.
* **Someone joining during a scene that was already shared was never pulled in;** they waited in their
  own room until it ended. The scene's leader now pulls every player who connects during it (only them).
* **Waits counted in frames gave up too early for a player who just joined:** the pull is dropped when its
  sender doesn't hold the scene lock "after 150 frames", and a spectator stopped watching when the leader
  seemed out of its scene "for 150 frames"; a newcomer hears about the lock and the leader's state a
  moment later (later on a bad network, and at test speed 150 frames is 0.25 s). Both now also need some
  real time (5 s and 3 s).

Tests (speed 20): Chapter 1 classroom scene (`setcon`), Chapter 2 Queen boxing (also with
`chaos:10:120:60`), Chapter 3 snow zone (the scene leads to a story fight: both fight it), Chapter 4
church glass, Chapter 5 garden intro: the late client is pulled in and watches the host's scene ("Watching
Host's cutscene", text box from the host's page), both end in free roam in the same room; `mpcheck` passes.
Crash (Chapter 2, bad network): the client is killed mid-scene and restarted, joins again (as "P22", the
old P2 times out a few seconds later), is pulled in and watches the host's scene to the end. (In the
Chapter 2 runs plot shows 33 against 53 for a moment at the end: the test starts that room at plot 53 and
the scene writes 33; the plot guard brings both back to 53. A test artifact.)

## The opening belongs to the host (2026-11-23)

Before, each player went through Chapter 1's opening (the vessel creation: the `DEVICE_*` objects in the
`PLACE_*` rooms) on their own, and a client still in it joined the host only after finishing its own.
Now (`mp_opening_tick`, scr_mp_world):

* A client in a `PLACE_*` room while the host is in the game skips the opening: the file is named after
  the player (upper case, at most 12 letters), and it goes straight to the host (once the host's state,
  asked for when the new file started, has arrived).
* While the host isn't in the game (in its own opening, the title or the file select), the client's
  opening is paused (its `DEVICE_*` objects and text deactivated) behind a black screen: "<host> (the
  host) is creating the vessel... You will join them when they are in the game." If the host leaves,
  the opening goes on as before.
* Design choice (the simplest that works): the vessel screens aren't mirrored (they are drawn text and
  shapes); the host's own answers (flags 900-912) reach the client with the rest of the story state.
* Test (Chapter 1, speed 10, client with `chaos:10:120:60`): host and client both start in
  `PLACE_CONTACT`; the client waits ("opening: the host isn't in the game yet"); the host leaves for
  `room_field1` (the `away` token now also works from a `PLACE_*` room); the client skips to it as "P2"
  and both end up in `room_field1` seeing each other.

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
| Party menu (C) always shows the story's party, not your character. | ~~While the menu is open a "You: Susie" label shows in the bottom-right corner.~~ A misread of the request; replaced 2026-11-23 (see "The C menu names my character"): the status page names my character in Kris's place. | **Tested** (`openmenu` + screenshot). |
| Light World: characters without Light World sprites. | Susie now uses her Light World walking sprites (Chapter 2+). Ralsei has none, so his own sprites stay (as the TODO suggested). Kris never showed: that fallback only happened for sprites with no direction. | **Tested** (log of the drawn sprite: `spr_susie_walk_*_lw`). |

## Map SOUL look in every hero's colour (2026-11-26)

A player whose fight shows on the map (map hazards) had a white, blurred-looking outline over the
normal sprite. Now it matches the game's own Kris version: the hero goes dark (85% towards black,
faded in with the game's own alpha) with a 1-pixel outline in the colour of their SOUL (Susie
purple, Ralsei green, Noelle yellow; Kris keeps the game's own red sprite). `mp_draw_ow_heart`.

**Tested** (Chapter 2, 3 players, new test token `owsoul`, clients with `chaos:10:120:60`):
screenshots show Kris (game's red), Ralsei (green), Noelle (yellow) and Susie (purple), each dark
with a crisp 1-pixel outline.

## Queen, Berdly's plug and the Knight are normal fights (2026-11-26)

They were on the "special" list (the leader plays every hero) only as a precaution. Taken off: every
player plays their own hero, choosing at the same time, as in any fight. New test token `sturdy`
(heroes have 999 HP in fights) for long test fights.

**Tested** (2 players, bots with random menu choices, client with `chaos:10:120:60`, `mpcheck` all
PASS): Chapter 2 Queen (encounter 59), 5 turns with identical turn states in both games; Chapter 3
Knight (encounter 115), 7 turns identical, both heroes' panels up together (screenshot). Berdly's
plug only shows up through the Queen fight's own scene 25, not reached here: re-check in play.

## Map SOUL: my SOUL's colour, on my character's chest (2026-11-26, user report)

The map SOUL (map hazards) was always red and sat at Kris's chest, and the dark outlined body was
drawn from the top-left instead of where my character's body is drawn. Now the heart uses my SOUL's
colour (`mp_soul_sprite`), sits at the same height on my character's body (taller heroes have it
higher), with the game's white heart outline and the hit spot moved with it; the dark outlined body
is placed like the normal one (bottom centre). Kris is unchanged. (`mp_ow_heart_place`,
`mp_ow_outline2`, `mp_draw_ow_heart`; Chapter 4's tower shake kept.)

**Tested** (Chapter 2, 3 players, `owsoul`, clients with `chaos:10:120:60`): screenshots show
Susie with a purple heart and Ralsei with a green one, each on the chest, outline matching the body.

## Team ACTs work without heroes nobody plays (2026-11-26, user request)

Chapter 3's last board fight (Tenna + Shadowguy, encounters 133/134) gives every hero only ACT, and
Kris's ACTs there need Susie and Ralsei (`actactor` 4: the game greys them out unless both are in the
fight and standing). In a session the fight has only the played heroes, so with two players Kris
could pick nothing and the fight stalled on turn 0. Looked at what each ACT does: Tenna's (ILOVETV,
Resist) are text only, Shadowguy's Check and Boogie are Kris's own (Boogie: Kris dances); only
Sharpshoot moves and dresses Susie and Ralsei (`obj_heroralsei.x` without a check, it would crash).
So, the user's rule: if a helper is only there to skip their turn, the ACT works without them.
`mp_act_blocked`: when the needed hero is not in the fight at all (a hero who is down still blocks,
as in the game), the ACTs listed in `mp_act_turn_only` stay usable; Sharpshoot and every other ACT
keep the game's rule. Tenna board 4 is off the "special" list (a normal same-time fight).

**Tested** (Chapter 3, encounter 134, client with `chaos:10:120:60`, `mpcheck` all PASS): Kris +
Noelle (no Susie, no Ralsei) and Kris + Susie both get past turn 0 (before: stuck there for 120 s),
same pace as with all three heroes (3 players, turn 1 in 120 s, Tenna's long talks); turn states
identical in both games; screenshot: "That's right." after ILOVETV.

## Chapter 5 coloured-SOUL fights checked with 2 players (2026-11-26)

Every Chapter 5 fight with its own SOUL rules was played as a normal shared fight (2 players, bots
with random menu choices, client with `chaos:10:120:60`, `sturdy`), `mpcheck` all PASS, turn states
identical in both games:

| Encounter | Enemies | Turns checked |
|---|---|---|
| 220 | aqua | 5 |
| 221 | green + orange | 4 |
| 222 | yellow + blue | 4 |
| 223 | purple | 3 |
| 224 | pink | 3 |
| 225 | Flowery (orange heart: each player has their own clash, as decided) | 3 |

None needed to go on the "special" list. Not covered by the bots: Mew Mew's choice event (the pink
fight's story part). A first run of 222 froze the host for 26 minutes right when the test took its
screenshot (frames of exactly 1 s and 3 s, then nothing until the client's game was closed); run
again without screenshots it was fine, so it is the test's screenshot step, not the mod.

## Titan is a normal fight (2026-11-26)

Chapter 4's final boss was on the "special" list. Its own parts (darkness, the TP gain cut, Titan's
heals, the light aura) are per screen or are the enemy's, and each hero's spells are played by that
hero's player, so it runs as a normal same-time fight. Taken off the list.

**Tested** (Chapter 4, encounter 175, 3 players Kris/Susie/Ralsei, bots with random choices,
clients with `chaos:10:120:60`, `mpcheck` all PASS): 6 turns with identical turn states in all
three games, each hero owned by their own player.

## A player joining during a story fight's start is pulled in (2026-11-26, found testing Titan)

A player who finished joining right after a fight began (during the encounter's "!", after the
host's pull) stayed on the map for the whole fight. Two causes: the host only pulled a new player
once the battle itself existed, and in open-world mode (the default) it never pulled a new player
at all, also not into a story fight, which calls everyone. Now, on a join, the host pulls the new
player when it is in a fight (from the "!" on) and either open-world battles are off or the fight
is a story fight. A normal open-world fight still lets newcomers walk up and join.

**Tested** (Chapter 4, Titan, 3 players, P3 with `connectat:130` / `connectat:150` so it joins
1-1.6 s after the fight started, clients with `chaos:10:120:60`): the host logs "join during my
fight 1: pulling them in", P3 plays Ralsei (`own2`), all three games identical up to turn 2,
`mpcheck` all PASS. Before: `players reached different turns: host 5, client1 5, client2 -1`.

## Team ACTs without the heroes nobody plays, in every chapter (2026-11-26)

Following the Tenna fix: a sweep of every team ACT (Kris's ACTs that need Susie, Ralsei or Noelle,
`actactor` 2-5; about 270 over the five chapters). `tools/actsolo.py` reads each enemy's ACT code
(its `acting == n` branches, with Chapter 1's texts from `lang_en.json`) and keeps the ACTs whose code
never names the helper: no object, sprite, variable or text of them. Those only take the helper's
turn: 6 in Chapter 1 (Clubs' three talks, Rabbick's BreathAll, ...), 4 in Chapter 2 (Berdly's
BumpX, ...), 8 in Chapter 3, 1 in Chapter 4, 3 in Chapter 5, written to
`scr_mp_actsolo_chN.gml`. When the helper is not in the fight they stay usable (`mp_act_turn_only`);
every other team ACT keeps the game's rule. Using one crashed the game (it marks the helper's turn at
`charpos` -1) and, for Susie + Ralsei ACTs, always took the turns of slots 1 and 2 whoever is there:
now only the turns of the helpers in the fight are taken (hooks in Chapter 1's battle Step and
`scr_actselect`). New test token `actlist` logs which of Kris's ACTs can be picked.

**Tested** (2 players Kris + Susie, no Ralsei; client with `chaos:10:120:60`):
* `actlist`: Chapter 1 Clubs (encounter 8): TalkBday / TalkBoys / TalkSports allowed; Rabbick
  (16): BreathAll allowed, Warning (its code moves Ralsei) blocked; Chapter 2 Berdly (58): BumpX
  allowed.
* Bots picking random ACTs: Clubs crashed before the turn fix (`Variable Index [-1] out of range`),
  none after; Clubs 3 turns, Rabbick 6, Berdly 4, all in sync (the only difference, turn 0's enemy
  HP, comes from the test's `tough` token on the host alone).

## Improvise: Susie throws Ralsei at Berdly's wires when Kris isn't in the fight (2026-11-26)

The Queen fight with Berdly plugged in (Chapter 2) has Kris's Throw: Susie throws Kris at the wires
holding Berdly. Without Kris (e.g. Susie and Ralsei players only) that was gone. Now Susie gets
**Improvise** in her own ACT list (MAGIC menu, description "Throw#Ralsei", 20% TP; Kris's Throw is
free): she throws Ralsei, the game's own second throw (the one Kris's ThrowX ends with: Ralsei drops
onto Susie's shoulders, same aim, same wire targets, same mercy for Berdly). Only when Kris isn't
there, Susie and Ralsei are up, and Queen's shield is down (like Kris's Throw).
"Improvise" is the name for every stand-in from now on (user idea).
Found and fixed on the way:
* **A hero other than Kris in place 0 lost their ACT** (Chapters 2-5): the game starts the heroes'
  ACTs at place 1 (place 0 is always Kris for it). `mp_first_act_place0` (from `scr_endturn`) starts it.
* **The throw is the same in every game:** the aim swings every frame, so keys can't replay it. Susie's
  player throws; the others' copies throw with the same angle and power when it arrives (type 58,
  kind 2). Covers Kris's Throw as well.
* Ralsei stayed invisible when the last wire was cut while he flew (the game's own ThrowX path).
* Susie's and Ralsei's own Loosen are set up when Berdly is plugged in after the fight was built.
Test tokens: `pickact:<char>:<n>` (that hero picks entry n of their MAGIC/ACT list, with keys),
`throwbot` (presses C during a throw), `setflag:<n>:<v>` (a story flag, e.g. 34:0 "Susie and Ralsei
can ACT").
**Tested** (Chapter 2, encounter 59 at plot 100, host Susie + client Ralsei with `chaos:10:120:60`,
20x, `mpcheck` all PASS): Improvise picked, "ACT of place 0 started", the same throw in both games
(e.g. angle 24 power 30), both end with 1 wire cut and Berdly at 13 mercy, turns 0-4 identical;
with the shield up Improvise leaves the list. 5 runs of 6 clean; the sixth: see TODO (menu replay).

## Spamton NEO: everyone plays their own hero and shoots (2026-11-26)

Spamton NEO (Chapter 2) is no longer a "special" fight where the leader played every hero: it is a
normal fight. Everyone picks their own hero's action in the same-time menu, and in his attacks
every player has the yellow SOUL and shoots on their own screen (as everyone dodges on their own
screen in every fight).
"An ally who does well helps": the mercy a player's own attack phase earns (BIG SHOT hits, cut
strings: the game's `mercyaccumulated`, added when the attack ends) is sent with their "turn done";
the leader adds everyone's to the fight's mercy (TP was already added up the same way).
Choice (simplest): the user's rule "shot targets get HP x players" was for one shared screen; here
every player shoots their own copies of the targets, so each already has to destroy their own and
the targets keep their HP. Spamton's own HP is unchanged.
Test tokens: `botshoot` (the bot shoots and charges BIG SHOTs), `dodgemercy` (my attack phase earns
1 mercy once per turn).
**Tested** (Chapter 2, encounter 61, host Kris + client Susie with `chaos:10:120:60`, 20x, `mpcheck`
all PASS): 7 turns with identical states in both games, both SOULs shooting (screenshots, the
client charging a BIG SHOT). With `dodgemercy` on the client only: each turn the host logs "the
others' dodging gave enemy 0 1 mercy" and both games go 1, 2, 3, 4 mercy.

## Shadow Mantle: everyone fights, the boss has HP x players (2026-11-26, part 1)

Chapter 3's Shadow Mantle (real-time, on the board) was on the "special" list. Like the rest of
the board, everyone fights their own copy; now the boss's HP counts for all: each sword hit anyone
lands takes 1/N of its damage from every copy (mine at once, the others' when their running count
arrives, message 86). N = players in the room whose count came in within 3 s (players fighting him,
not just standing there). The game's own HP rules stay (held at 4 until the last phase, phases at
22/13/4, defeat below 1). Test tokens `smfight` (start the fight from its room), `smhit` (a 1-HP hit
every 4 s).
**Tested** (Chapter 3, `room_board_preshadowmantle`, 2 players, client with `chaos:10:120:60`, 20x):
both fights start at 30 HP; each player's hits count half in both games ("my hit 1 / 2", "Host's hit
1 / 2"); both reach the same HP (25). Only the very first hit, before the other's count arrived,
counted whole. `mpcheck`: all PASS except "moved" (both pieces put on the same trigger by the test).
Not seen yet: the end of the fight with 2 players.

## Rhythm game together, part 1: everyone plays the band song, Ralsei's player sings (2026-11-26)

Chapter 3's band song (`room_dw_rhythm`). Before, a client watched the leader's intro, and then:
with a leader who kept playing, the client kept watching the leader's scene (the song never started
in the client's game); with a leader who failed, the client went back to the room, the mod stopped
the room's scene as "started again" and destroyed the song's music event manager with it, and the
client crashed (`obj_rhythmgame` Step, "Unable to find any instance"; also seen with the client as
Susie, so it was there before).
Now:
* The band song (not the sound check) is not a shared scene (`mp_rhythm_song_on`): the leader's
  scene ends when the song starts, the others go back to the room, and the room's own scene starts
  the song in their game the way a retry does (its curtain wipe), which the mod keeps. The band
  stands where a retry puts it.
* Ralsei's player sings the vocal chart (Left/Z, Down or Up, Right/X; held notes held), scored
  by the chart's own rules; Ralsei sings on each hit as on autoplay. In that copy Kris's guitar
  plays itself, as the vocals do in the solo game. Kris's player plays as before.
Choice (simplest): each copy keeps its own score and ending for now (parts 2-5 in the TODO).
Test token `rhythmbot` (the vocals hit on time; Kris's player's guitar plays itself).
**Tested** (Chapter 3, `room_dw_rhythm` plot 130, host Kris + client Ralsei, client with
`chaos:10:120:60`, 5x): the intro is watched together, then both play the song in their own game
(both shown `[rhythm game]`); the client sang 141 vocal notes, score 48,760, band on the stage
(screenshots); no crash.

## Rhythm game together, part 2: Susie's player drums (2026-11-27)

The user's design: Susie's part gets a real pattern that plays the original sound, instead of her
failing every note as in the solo game. The game already has a full drum chart for the band song
(two pads and a bass bar); in the story it is shown failing (scripted wrong hits, the chart crossed
out in red). Now, when someone plays Susie, in the band song (not the sound check):
* in Susie's player's game the drum chart is theirs: Left/Z and Right/X for the pads, Down or Up
  for the bass bar, scored by the chart's own rules; each hit makes Susie strike that drum and
  sounds with the game's own snare; Kris's guitar plays itself there;
* in everyone else's game Susie drums her part properly on her own (the chart lit, no red cross).
Without a Susie player the story's drummer is unchanged.
**Tested** (Chapter 3, `room_dw_rhythm` plot 130, host Kris + client Susie with `chaos:10:120:60`,
5x, `rhythmbot`): both play the song in their own game; the client drummed 569 notes, score
81,470; both screenshots show Susie's chart live with its combo counting; no crash.

## Rhythm game together, part 3: one band, one score (2026-11-27)

The SCORE the game shows (its `points`, in the solo game Kris's guitar only) is now the band's: the
guitar's points from Kris's player plus the drum and vocal chart scores from Susie's and Ralsei's
players (a part nobody plays adds nothing, as in the solo game). Each player's game counts its own
player's part and sends it (message 88, every 15 frames); a part played by someone else adds
nothing by itself (its autoplay gains are taken back) and its player's count is added instead.
The fame meter, which decides the win at the end, is the guitar's: in the others' games it follows
Kris's player's (and their losing/quitting, which fades the song out the game's own way).
Choice (simplest): the sum, as the TODO's design says; the question of what Tenna's evaluation
should get is in the TODO.
**Tested** (Chapter 3, `room_dw_rhythm` plot 130, three games: host Kris, clients Susie and Ralsei
with `chaos:10:120:60`, 5x, `rhythmbot`): every game shows the band's score, e.g. host 25,550 +
23,780 + 27,770 = 77,100 while the clients showed 77,280 and 77,440 at about the same moment
(screenshot: SCORE 075606 in Susie's game); no crash. Not seen in this test: a lost song (the
bots don't miss) and the song's end.

## Rhythm game together: the song's end checked, a log flood fixed (2026-11-27)

Played the band song through to its end with two games (host Kris, client Ralsei with
`chaos:10:120:60`, `rhythmbot`): the client's song ended first; its ending scene (victory, the
evaluation in the game show room, then the green room) became the shared scene, the host was
pulled into it, and both games went on together in `room_dw_green_room` at plot 160; no crash.
Fixed on the way: while the song played, the host's log got an "interact 1->0" line every frame
(18,662 in one song), because the song counts as free time for the sync but the previous value
was taken from the game's own `interact`. **Tested** again (same setup, 450 s): 1 such line on
the host, 0 on the client; 112 vocal hits, band score 40,070 in the host's game.

## Tenna's fight: every player's minigame score counts (2026-11-27)

Chapter 3's Tenna fight (encounter 121): his minigame turns (the music game, Susiezilla, cooking,
the shooting gallery...) are his attacks, so every player plays one in their own copy of the
fight, but only the score in each player's own game counted there, and the games' fight scores
(the one that unlocks his ultimate and wins at 1000) drifted apart. Now each player's minigame
score is sent with their "turn done" (message 44); the fight's leader adds the others' to the
fight's score the game's own way (`addscore`, counted up on screen), and the leader's "turn go"
(message 45) brings the fight's score to every game (a player's own minigame score still
counting up stays part of it).
Choice (simplest, like Spamton NEO's mercy): the sum of everyone's scores.
Test tokens `halfhp` (enemies start at 45% HP, so his minigame turns begin) and `tennascore`
(each of my minigames scores 10 more).
**Tested** (Chapter 3, encounter 121, host Kris + client Susie with `chaos:10:120:60`, 5x): turn 1
both minigames scored 58, the leader logged "the others' minigames scored 58 (fight score now
116)" and the client took "fight score 116 from the leader"; turn 2 the same with 16 + 16 = 148
in both games; the third minigame (the shooting gallery) was running in both when the test ended;
no crash.

## Watched cutscenes: backdrops drawn by an object show for the watchers (2026-11-27)

Comparing host and client screenshots of the same moment (`SHOTS`) during Chapter 2's scene at
the top of the mansion (`room_dw_mansion_top`): the watcher saw a plain dark sky where the leader
saw the city. The city is `obj_ch2_scene26_cityscape`, an object that draws the backdrop itself
(tiled sprites, masks, blend modes), which the mirror's sprite list can't carry, and the watcher's
room is switched off. Now such objects are "kept scenery" (`mp_mirror_keep_init`, a list by name):
they stay on in the watcher's game and draw there; their Step (which makes the scene's other
objects) runs only in the leader's game; their own sounds come from the leader's game (`snd_play`
returns at once for them while watching); and the leader sends their changed number variables
every 3 frames (message 91, unreliable) with a few unchanged ones twice a second for lost datagrams
(not the ids of objects it made). The laser beams between the leader's screens are drawn only
where those screens exist.
**Tested** (Chapter 2, `room_dw_mansion_top`, plot 165, host Kris + client Susie,
`chaos:10:120:60`): at 30 s and 60 s the client's screen shows the same city skyline as the host's
(before: none); "values of the scene's backdrop set as in the leader's game" logged; traffic about
5 KB/s as before (a first version sending more rotating values doubled it to 14 KB/s, cut down);
no crash through the 150 s run. Part 2 (what the scene creates: the GigaQueen background, the
floor) is in TODO.md.

## Watched cutscenes: the floor, the giant Queen's head and the falling walls (2026-11-27)

Part 2 of the backdrops in Chapter 2's scene at the top of the mansion, found the same way
(host/client screenshots at the same moments):
- The watcher's floor was black: the leader's scene puts a black cover behind the floor (a
  sprite at depth 1000350), and the watcher drew every mirrored sprite in one place, over the room.
  Now the leader sends each sprite's depth (4 more bytes; 40 sprites a datagram instead of 46, so
  it stays near 1 KB) and a second drawer draws the ones behind the room's nearest tile layer at the
  depth of the deepest of them: the floor (tiles) and the kept backdrops show over them.
- The giant Queen's head (`obj_ch2_scene26_gigaqueen`, masks and blend modes) and the walls rushing
  past as the party falls (`obj_looping_tiled_area`, which only draws) are kept scenery too.
**Tested** (Chapter 2, `room_dw_mansion_top`, plot 165, host Kris + client Susie,
`chaos:10:120:60`, 150 s): at 100 s the client shows the floor and the giant Queen's head as the host
does (before: black, no head); at 120 s the walls of the fall behind the party (before: black); no
crash. Left (TODO.md, part 3): the anime power-up part, made only in the leader's game.

## Watched cutscenes: the anime power-up of the top of the mansion (2026-11-27)

Part 3 of the backdrops in Chapter 2's scene 26: the anime background (`obj_anime_bg_controller`,
which draws its sprite twice, so the watcher saw only the upper copy and the walls below) and the
power-up figure (`obj_ch2_scene26_powers_combined`, which the scene makes only in the leader's game)
are kept scenery too. Kept objects now also carry their place and look (x, y, depth, sprite,
frame, alpha, colour, scale, angle, visible, as "@" names in message 91) and leave the leader's
sprite list (the watcher draws its own). For an object the leader's scene makes, the leader sends
how many there are ("#n") and the watcher makes or removes its own copies (without their Destroy
event). The sparkles and streaks these objects make while drawing, and the background's drone,
are made only in the leader's game (they reach the watcher in its sprite list). An id of an
object the leader's game made is sent as "none".
**Tested** (Chapter 2, `room_dw_mansion_top`, plot 165, host Kris + client Susie,
`chaos:10:120:60`, 170 s, through to the GigaQueen fight): "made a copy of the leader's
obj_ch2_scene26_powers_combined" logged; at 150 s the client shows the anime background over the
whole screen and the power-up figure as the host does (before: walls under half the background);
the scene ended and the fight began in both games; no crash. Left (TODO.md, part 4): the coaster
ride, which draws its riders itself.
README: watched scenes show the backdrops a scene draws itself.

## Watched cutscenes: the coaster ride with everyone on it (2026-11-27)

Part 4 of Chapter 2's scene 26: the coaster ride (`obj_berdlycoaster_event`, made only in the
leader's game) draws the coaster cars and everyone riding them by hand, from arrays, so the
watcher saw only the walls. Its Draw now calls `mp_mir_dse` in place of `draw_sprite_ext`: it
draws as before, and in the leader's game each of those sprites also goes in the mirror's sprite
list at the object's depth (the watchers draw them like any other). A general tool for any object
found drawing its sprites by hand.
**Tested** (Chapter 2, `room_dw_mansion_top`, plot 165, host Kris + client Susie,
`chaos:10:120:60`): at 138-142 s the client shows the cars with Kris, Susie, Ralsei, Berdly and the
recruits riding them, as the host does (before: walls only); the host's traffic peaked at 17 KB/s
during the ride (many sprites); no crash.

## Watched cutscenes: the dark fountain at every chapter's end (2026-11-27)

Compared host/client screenshots in Chapter 1's fountain room (`room_cc_fountain`): the watcher saw
the fountain in other colours and drawn differently, no Susie, and none of the sealing's light.
- The fountain (`obj_darkfountain`, which draws itself and sets the room's colour) and Kris and
  Susie walking up to it (`obj_fountainkris`) are kept scenery in every chapter; that scene's Step
  and alarm run only in the leader's game.
- The sealing (`obj_darkfountain_event`, made only in the leader's game) draws its light, flash and
  fades by hand: its `draw_sprite_ext` and `draw_rectangle` now go through `mp_mir_dse` /
  `mp_mir_drect` (a filled rectangle is sent as a stretched white pixel in the draw colour and
  alpha), and its sounds (`audio_play_sound`, not `snd_play`) through `mp_mir_aps`, so the
  watchers hear them.
**Tested** (Chapter 1, `room_cc_fountain`, host Kris + client Susie, `chaos:10:120:60`): at 45 s the
client's fountain, Kris and Susie match the host's; the scene played through to the Light World,
both games entering `room_school_unusedroom` 0.3 s apart; no crash. (On the way, a stray
`#chapters all` line put inside the hook that makes the multiplayer controller by a failed edit
kept the mod from starting in Chapter 1; found by building Chapter 1 from each commit, removed
before committing.)

## Watched cutscenes: every cutscene object that draws by hand (2026-11-27)

Instead of finding scene by scene the objects that draw their sprites by hand (which the mirror
didn't send), `tools/gen_handdrawn.py` reads the decompiled code and writes
`mod/hooks/handdrawn.hook`: in every chapter, the Draw event of each cutscene object (name with
event, scene, cutscene or intro) that draws sprites or rectangles by hand gets those calls through
the mirror's wrappers (`mp_mir_dse`, `mp_mir_ds`, `mp_mir_drect`, and `mp_mir_dself` for its own
sprite then): 73 edits over the 5 chapters, among them King's and the car's scenes (Chapter 1),
Queen's transformation, laser and rocks (Chapter 2), the board's events and Tenna's (Chapter 3),
the church intro and purification (Chapter 4). What they draw reaches the watchers only from a
shared cutscene's leader, not for a persistent object or kept scenery (they draw in the watchers'
games themselves), not when drawn into a surface of its own, and at most 200 sprites a frame; the
list is cleared whenever the leader isn't mirroring. Objects already handled in core.hook are left
out. Run the script again after decompiling a new game version.
**Tested:** all 5 chapters build; Chapter 2's scene 26 again (host Kris + client Susie,
`chaos:10:120:60`, 170 s): the watcher's screen as before (floor, head, city, coaster), the white
power-up screen at 155 s, the scene ends in the GigaQueen fight; no crash. Chapter 1's castle
front with plot 160 (its scene didn't start by entering the room): no crash, same screens.

## Chapter 1's closet: the whole way down, for everyone (2026-11-27)
Checked live the first scene with the new hand-drawn hooks. Two gaps found and fixed:
- The closet is one scene in parts (Susie walks ahead, waits, talks, walks on). The part at the end,
  where the floor gives way, reached the others as a pull they dropped as "just had that cutscene
  here" (same room, same story progress, under a minute). Now that rule only holds for a scene that
  starts on entering the room or near where my last one started (within 80 px); a part further on
  in the room is shared, and everyone falls into the Dark World with the one who walked there.
- The closet wall is made of old-style tiles that the scene hides one by one (`tile_layer_hide`),
  which the layer mirror didn't carry: the watchers kept seeing the wall as everything went black.
  The layer state now also says whether a layer's old-style tiles are all hidden or some shown.
**Tested:** all 5 chapters build; Chapter 1 `room_insidecloset`, plot 5 (host Kris teleported to the
end of the closet, client Susie at the start, `chaos:10:120:60`, 64 s): the client watches the first
part, then the end part; the wall goes at the same time as in the host's game, the hand-drawn
sprite of Kris and Susie falling shows on the client, and the scene takes the client to
`room_dark1` with the host (plot 11); no errors in either log.

## Chapter 3's show intro: Tenna's TV, podiums and audience for the watchers (2026-11-27)
Compared the show's opening (`obj_ch3_GSA02`, `room_ch3_gameshowroom`, plot 70) host vs client.
The watcher saw a black TV in the back, blank podiums and no audience. Those objects draw
themselves (the TV with the CRT shader, the names as text, the crowd by hand), so they are now kept
scenery: `obj_dw_gameshow_screen`, `obj_quiz_podium`, `obj_ch3_audience` (Steps paused while
watching), and `obj_ch3_GSA02_spotlight`. The kept variables now also carry text (as "$" names:
the screen's `screen_state`, the podium's `mystring`) and small arrays element by element.
**Tested:** all 5 chapters build; Chapter 3 `room_ch3_gameshowroom`, plot 70 (host Kris + client
Susie, `chaos:10:120:60`, 82 s): on the client the TV shows "TV TIME" and then the pyramid as on
the host, the podiums show "???" and then the names, the audience rises at the front; no errors.
**Still open:** Tenna's spotlight at the start stays dark for the watcher: the mirror draws all the
leader's sprites at one depth in front, so the scene's black cover is drawn over the kept spotlight
(TODO item 8).

## Kept scenery between the leader's sprites: Tenna's spotlight (2026-11-27)
The mirror drew all the leader's sprites at one depth in front of the room (and the ones behind the
tiles at another), so kept scenery in front of the tiles was always under them: Tenna's spotlight
(kept, drawn with its own blend tricks) was covered by the scene's black cover. Now three more
drawers sit each just behind a visible kept object in front of the tiles (the 3 nearest), and the
leader's sprites are drawn in parts between them (`mp_mirror_splits`, `mp_mirror_draw(kind)`):
the black cover, then the spotlight, then Tenna, as in the leader's game.
**Tested:** all 5 chapters build. Chapter 3 `room_ch3_gameshowroom`, plot 70 (host Kris + client
Susie, `chaos:10:120:60`, 52 s): the client shows the spotlight's cone and the lit floor ellipse
with Tenna in front, as the host. Chapter 2's scene 26 again (`pos:1080:240,walkto:1200:240,bot`,
165 s): city, Queen's head, the fall, the coaster, the power-up and the GigaQueen fight as before.
Seen there, already in the earlier run: a caught error at the end of the GigaQueen fight
(`obj_thrash_intro`, noted under GigaQueen in the TODO). (Test note: `walkto` only acts with `bot`.)

## Chapter 3's show: the stage floor's shade and the fun-o-meter for the watchers (2026-11-27)
The floor in front of the stage was lit for the watcher and dark in the leader's game: the shade is
`obj_dw_gameshow_stage_overlay`, which draws rectangles (nothing the mirror can send). It is now
kept scenery, and so is `obj_dw_tv_funometer` (its Draw picks the meter's sprites by its own state;
the mirror's guess sent its plain sprite). Kept objects that the leader's game draws over another
at the same depth get a step nearer in the watcher's game (`global.mp_mir_front`: the overlay over
the TV screen, both at 990000; equal depths draw in an order of the engine's own).
New test tokens: `mirdump` (the leader logs, every 10 s, the visible objects that draw on their own
and send nothing) and `mirdumpall` (every visible object with its kind, depth and sprite, and the
room's layers; on the watcher too).
**Tested:** all 5 chapters build; Chapter 3 `room_ch3_gameshowroom`, plot 70 (host Kris + client
Susie, `chaos:10:120:60`, 78 s): the floor's dark gradient shows on the client as on the host, the
scene plays to the desert board screen; no errors. Still open: the TV's star dots through the
gradient (TODO item 8).

## Chapter 4's church lighting for the watchers (2026-11-27)
Compared the church's arrival scene (`room_dw_church_intro1`, plot 105) host vs client: the watcher
had no darkness and no light beams through the windows. The church's light is drawn by objects of
its own with surfaces (`obj_darkness_overlay`, `obj_lightbeamfx`, `obj_light_area_mask`,
`obj_light_following`); the mirror only sent their plain sprite. They are now kept scenery (Steps
paused while watching; the darkness in Chapter 5 too). Kept objects' variables that hold a resource
of the game's own (names with surf, _list, _map, grid, buffer, part_, shader) are never sent: the
leader's surface id means nothing (or something else) in the watcher's game.
**Tested:** all 5 chapters build; Chapter 4 `room_dw_church_intro1`, plot 105 (host Kris + client
Susie, `chaos:10:120:60`, 32 s, shots during Susie's "What's with this place?"): the client shows the
same darkness and light beams as the host; no errors.

## Chapter 5's castle top compared; test token trig (2026-11-27)
Compared the scene at the top of the flower castle (`obj_ch5_DW22`, `room_dw_fcastle_top_intro`, plot
435: Asgore's story with its flashback) host vs client: the client watches it all and its screens
match the host's (text boxes, flashback room, the friends at the top); nothing to fix there.
To start it, a new test token: `trig:<extflag>` puts the player (and the climbing Kris, when
climbing) on the room's `obj_trigger` with that extflag 5 s into the test's room, for scenes that
start when the player walks into a spot the room's layout makes hard to reach with `walkto`.
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_top_intro`, plot 435,
`climb:200,trig:enter_trigger` (host Kris + client Susie, `chaos:10:120:60`, 80 s): the scene starts,
the client watches it to the end; no errors.

## Chapter 3's show: no stray yellow dots over the audience for the watchers (2026-11-27)
The yellow dots over the audience in the watcher's game were not the TV's star background: they
were the "TV TIME" lights (`obj_tenna_tv_time`, `spr_dw_tv_time_lights`). That object waits switched
off (`if (!is_active) exit;` at the top of its Draw) and draws nothing in the leader's game, but the
mirror's generated guess for it (MirrorInfo.cs, kind 3) only read the drawing call and sent the
lights every frame. The patcher now also reads the early ways out before the call
(`if (cond) exit;` at the top level, when the condition only uses the instance's own variables,
assets and look-only functions such as `i_ex`) and puts them in the generated function, which then
sends nothing while the object is off (18 objects in Chapter 3; also objects that only `draw_self`
after such a check get one).
**Tested:** all 5 chapters build; Chapter 3 `room_ch3_gameshowroom`, plot 70 (host Kris with `mash`
+ client Susie, `chaos:10:120:60`, 60 s, shots at 48/51/54/57 s): at the audience moment the
client shows the stage, the floor's gradient and the audience as the host, 0 yellow pixels in the
lower third (841 in the earlier run); no errors.

## Chapter 5's town colours in a watched scene (2026-11-27)
Compared the castle entrance scene (`obj_ch5_DW19`, `room_dw_fcastle_entrance`, plot 385), which
goes to a memory of the town (`room_town_north`, `obj_ch5_DW19A`). In the town the leader's game
has the warm evening colours, the watcher's had the plain ones: the colour grading
(`obj_lutshader`, made by the room's own controller through `scr_manage_sunstate`) was switched
off with the rest of the watcher's room. It and the palette swap (`obj_bg_palette_swap`) are now
kept scenery (the grading's texture made again in the watcher's game from the slot the leader's
sent). The grading draws at half size in the Light World, and the watcher was still in the Dark
World from the castle: a watcher now takes the leader's Light/Dark World while watching (its own
comes back with its room when the scene is over, as before).
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_entrance`, plot 385, `trig:dw19`
(host Kris with `mash` + client Susie, `chaos:10:120:60`, 120 s, shots from 70 to 110 s): the
scene plays, moves to the town, and the client shows the town in the same evening colours and size
as the host; no errors.

## The Dark World's exit pillar as the leader sees it (2026-11-27)
In the castle entrance scene the light at the room's right side was a flat bright white for the
watcher and a faint glow for the leader: it is the Dark World's exit (`obj_dw_leave_flowercastle`),
which draws its sprite three times, narrower and see-through each time, and the mirror sent its
plain sprite at full strength. Its drawing calls now go through `mp_mir_dse` (what it draws reaches
the watchers), for every exit of the kind: `obj_dw_leave` (Chapters 2-5), `obj_dw_leave_ch4`,
`obj_dw_leave_flowercastle` and `obj_dw_leave_flowery` (core.hook).
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_entrance`, plot 385, `trig:dw19`
(host Kris with `mash` + client Susie, `chaos:10:120:60`, 65 s, shots at 40/50/60 s): the pillar
looks the same in both games (565 near-white pixels in the right quarter on both, every shot); no
errors.

## Chapter 5's party jail, a scene in two parts, for everyone (2026-11-27)
Compared the party jail (`obj_ch5_DW19B`, `room_dw_fcastle_partyjail`, plot 395): its first part
locks Kris and Susie in a cell and gives control back inside it; talking to the moss starts the
second part, which ends in `room_dw_fcastle_post_party_jail` (plot 398). The watcher came back from
the first part to a room with no cell (its own copy of the scene, starting again, was stopped) and
could walk off. Two changes:
- A watcher whose own copy of a scene starts again where a friend's part just ended can take it up
  as that part left it (`mp_mirror_resuming`, `mp_mirror_resume_at`). The jail does so (core.hook):
  the bars and the switch as the first part leaves them, the moss to talk to, and the player where
  the friend stood, in the cell.
- The second part starts where the first did, so a friend's pull for it was dropped as "just had
  that cutscene here". A pull now carries the scene's number in its room (scenes played or watched
  there, `mp_cs_part_next`); one with a higher number than the last I had is the scene's next part
  and is shared. (A friend's own copy of a scene I already had still has the same number and is
  dropped as before.)
Also: the patcher's check for assets missing from a chapter now reads only the hook blocks for
that chapter (`#chapters 5` blocks may name Chapter 5's assets).
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_partyjail`, plot 395 (host Kris with
`mash` + client Susie, `chaos:10:120:60`): the client watches the first part, takes the scene up
locked in the cell like the host (shots at 50/60/70 s); the client then talks to the moss
(`useobj:obj_interactable`), the host is pulled into the second part (part 2 > 1), and the scene
takes both to `room_dw_fcastle_post_party_jail`, plot 398 (260 s run); no errors.

## Chapter 5's castle light shafts for the watchers (2026-11-27)
Compared the top staircase scene (`obj_ch5_DW25`, `room_dw_fcastle_top_staircase_1`, plot 450,
trigger `enter_trigger`). The scene itself matched (Susie's yell, made by `obj_anim_custom` on her
actor, shows on the watcher a moment later, as the network allows), but the light shafts falling
across the room (`obj_fcastle_light`, drawn added onto the room, which the mirror can't send) were
missing for the watcher. They and the castle's falling petals (`obj_leafpetals`, drawn from
surfaces of their own) are now kept scenery, the petals' Step paused while watching.
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_top_staircase_1`, plot 450,
`trig:enter_trigger` (host Kris with `mash` + client Susie, `chaos:10:120:60`, 62 s, shots at
35/45/55 s, and every 2 s from 44 to 58 s before the change): the client shows the light shafts on
the left as the host; no errors.

## Hit words and coloured afterimages in watched scenes (2026-11-27)
Compared the second top staircase (`obj_ch5_DW27`, `room_dw_fcastle_top_staircase_2`, plot 460,
trigger `enter_trigger`), where Ralsei strikes at Flowery twice. The watcher saw neither the "MISS"
nor Flowery's coloured trail:
- The hit words (MISS, UP, DOWN...) are sprites `obj_dmgwriter` draws by hand: its message-sprite
  calls now go through `mp_mir_dse` (Chapters 2-5; in battle nothing changes, the mirror only works
  in shared scenes).
- Flowery's trail is one-colour silhouettes (`obj_marker_fog`: the sprite drawn with the GPU's fog
  in one colour), which the mirror sent as his plain sprite, or not at all once faded. A sprite in
  the mirror's list can now be a silhouette: the colour goes as its colour, with 10000 added to its
  angle as the mark, and the watcher draws it with the fog in that colour.
New test token `mirfog`: the watcher logs the silhouettes and hit words it gets.
**Tested:** all 5 chapters build; Chapter 5 `room_dw_fcastle_top_staircase_2`, plot 460,
`trig:enter_trigger` (host Kris with `mash` + client Susie, `chaos:10:120:60`): the client logs the
silhouettes (`spr_flowery_kiss`, `spr_flowery_float`...) and `spr_battlemsg` at both strikes, and its
shots show the "MISS", the slash and the red and orange trail as the host's (shots every second
from 26 to 36 s); no errors.

## After the Flowery fight (DW30), part 1: the sunset sky, the flashback's colours and red threads (2026-11-27)
Compared the scene after the Flowery fight (`obj_ch5_DW30`, `room_dw_post_flowery_battle`, plot
490, starts on entering). The watcher had:
- a black sky: the sunset backdrop (`obj_parallax_cliffs` and its layers, drawn with a palette
  shader) is now kept scenery. Kept objects' references to another kept object (the layers' `daddy`)
  are no longer sent, since the watcher has its own.
- white silhouettes in Asgore's flashback: `obj_marker_fogblend` is sent as a one-colour silhouette
  like `obj_marker_fog`.
- no red threads from the papers: `obj_ch5_DW30_line` draws them with `d_line_width_color`, now
  through the new `mp_mir_dline`, which sends a white pixel stretched along the line. The mirror's
  stretched pixel now divides by the sprite's size (Chapter 5's `spr_pixel_white` is 2x2).
Still open (TODO): the flashback's narration (a writer made without a text box) and the scene's blur.
**Tested:** all 5 chapters build; Chapter 5 `room_dw_post_flowery_battle`, plot 490 (host Kris
with `mash` + client Susie, `chaos:10:120:60`, 100-112 s, shots from 20 to 108 s): the client shows
the sunset, the coloured silhouettes (yellow, aqua, green, lilac, then red Asgore) and the threads
as in the host's game; no errors.

## Text a scene writes without a text box reaches the watchers (2026-11-27, DW30 part 2)
Asgore's flashback after the Flowery fight (`obj_ch5_DW30_flashback`) tells its story in white
letters on black: an `obj_writer` the scene makes by itself, with no text box. The mirror only sent
a text box's writer, so the watcher saw the silhouettes with no words. Now the leader's game also
sends a writer that is the only one on screen and has no box (`mp_mirror_lone_writers`), with its
place on the screen and its colour (message 78 gets a "lone" part); the watcher's game makes the
same writer there, and its pages turn with the leader's like a text box's. Left out: writers that
other things make while they're around (a platform-style box, shops, the legend, the fountain's
kept Kris, enemy speech bubbles) and several writers at once (`scr_simultext`).
**Tested:** all 5 chapters build; Chapter 5 `room_dw_post_flowery_battle`, plot 490 (host Kris
with `mash` + client Susie, `chaos:10:120:60`, 108 s, shots from 66 to 102 s): the host logs 11
lone writers sent (pages 26-39), the client shows "* Kris.", "* Was to prove it wasn't my fault."
(dark letters on the red flash), "* I thought if I could just prove..." at the host's place and
colour, its page count following the host's; the scene's text box after it is still sent as a box;
no errors.

## After the Flowery fight (DW30), part 3: the blur over the screen (2026-11-27)
`obj_ch5_DW30` blurs the whole screen while its `bluramt` is up (the flashback): it copies the
screen and draws it again through the game's blur shader, wobbling. It is now kept scenery while a
friend watches (its Step and alarm paused there, the leader sending `bluramt` and the rest), so the
watcher's game draws the same blur over what it shows, between the mirrored sprites at its depth.
README updated (5 commits): scene backdrops and effects in Chapter 5.
**Tested:** all 5 chapters build; Chapter 5 `room_dw_post_flowery_battle`, plot 490 (host Kris
with `mash` + client Susie, `chaos:10:120:60`, 140 s, shots from 30 to 110 s): the client's flashback
is blurred like the host's (silhouettes, papers and red threads soft and doubled); the sunset and the
text boxes as before; no errors.

## Release check: every chapter patches with the launcher's paths (2026-11-27)
Packing v21, the packaged patcher (called by the launcher with Windows paths) refused Chapters 1
and 2: the rhythm game's script named Chapter 3's `obj_rhythmgame`, `obj_rhythmgame_chart` and
`snd_play_x`, and the test script `obj_trigger`. `tools/build.sh` never saw it: with Git Bash's
"/" paths the patcher's asset check compared two spellings of the same folder and skipped every
top-level script. Fixed both: those names are now looked up by name (`asset_get_index`), and the
patcher compares full paths, so build.sh checks what the launcher checks.
**Tested:** all 5 chapters build with build.sh, and the self-contained patcher patches all 5 with
Windows paths; Chapter 3 rhythm game (`room_dw_rhythm` plot 130, host Kris with `mash` + client
Susie with `chaos:10:120:60`, `rhythmbot`, 210 s): the client drums (320 hits, score 55,800), the
host's band score adds the client's part (40,560: mine 14,080 + others 26,480); text boxes within
about 1 s of each other; no errors.
