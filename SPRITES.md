# Poses the co-op needs that the game doesn't have

Stand-ins (TODO.md, "Improvise") use the game's own art. Some combinations need a pose the game
never drew. Each entry gives the situation, why it is needed, how it would look, and what the game
already has that comes close (a good place to start looking, or to edit from).

Format: **Pose** — situation / why / how it would look / closest existing sprite.

## Chapter 2: Queen fight with Berdly plugged in (Throw at the wires)

The original: Kris's ACT "Throw", Susie throws Kris at the wire targets (`spr_susieb_throwralseiready*`
is the game's Susie-holds-Ralsei pose, used after Kris in ThrowX; `obj_queen_kristhrown` flies with
Kris's battle sprites).

* **Kris throws Ralsei** — Kris + Ralsei, no Susie (duo stand-in, 20-30% TP). Kris doesn't have
  Susie's strength, so he tosses Ralsei overhead, two-handed, in an arc. Needs: Kris (battle, dark
  world, `spr_krisb_*` style) holding Ralsei above his head, ready and released frames. Closest:
  `spr_krisb_throwplate` (Chapter 3, Kris throwing a plate), `spr_ralsei_lift` (Chapter 4).
* **Susie throws her axe** — Susie alone (solo stand-in, 40% TP). Nobody to throw, so she throws
  her axe at the wire and it spins back. Needs: Susie (battle) winding up and throwing the axe, the
  axe spinning in the air. Closest: `spr_susie_climb_throw` / `spr_susie_beach_throw_stone`
  (Chapter 4, overworld), Rude Buster's own frames (`spr_susieb_attack`).
* **Kris throws his sword** — Kris alone (solo, 40% TP). Same idea with the sword, which comes back
  like a boomerang. Needs: Kris (battle) throwing the sword, sword spinning. Closest:
  `spr_roaringknight_throw_sword` (Chapter 3, the Knight's throw, as a reference for the motion).
* **Ralsei jumps at the wire** — Ralsei alone (solo, 40% TP). He can't throw anyone; he hops up with
  his scarf and snips. Needs: Ralsei (battle) jumping and swiping. Closest: `spr_ralsei_lift`,
  his battle attack frames.
* **Noelle** — not in this fight in the story; she only needs a pose if a player plays her there
  (weird route save): **Noelle freezes the wire** (an ice spell at it, no new pose: her spell cast
  frames are enough).

## Chapters 2-4: Werewire's ThrowWire

Kris's ACT with Susie: Susie throws Kris onto the wire to knock the Werewire off (`spr_werewire_throwarrow`
for the aim). Same combinations as Queen's Throw: the poses above would serve both fights.

## Notes

* All poses are battle sprites at the game's battle scale, facing right, with the same palette as
  the hero's own battle sprites (dark world).
* Overworld poses are not needed for these.
