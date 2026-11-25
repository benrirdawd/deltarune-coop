// DELTARUNE Multiplayer - Chapter 4's dark ripple rooms (obj_church_ripple_area_manager: the church
// rooms where the floor is dark and each of Kris's steps makes a ripple of light).
//
// The ripples have no puzzle state (nothing is solved or opened by them): they only show where
// Kris walks, in each player's own game. So a friend walking in the dark left no ripples in my
// game. Now a friend's figure in my room makes the same ripples on its steps (no sound, like the
// game's quiet rooms), while the room is dark. Simplest choice: drawn from the figure each game
// already shows, nothing new is sent.

function mp_ripple_tick()
{
    if (!mp_on() || !instance_exists(obj_church_ripple_area_manager))
        return;
    var man = instance_find(obj_church_ripple_area_manager, 0);
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
    {
        var gg = global.mp_pghost[global.mp_myid == 0 ? 1 : 0];
        show_debug_message("[MPRIPPLE] active=" + string(man.active) + " lightcon=" + string(man.lightcon) + " always=" + string(man.alwaysrip) + " ghost=" + string(instance_exists(gg)) + (instance_exists(gg) ? " vis=" + string(gg.visible) + " img=" + string(gg.image_index) + " spr=" + sprite_get_name(gg.sprite_index) + " area=" + string(collision_point(gg.x + 18, gg.y + 60, obj_church_ripple_area, false, true) != noone) + " areas=" + string(instance_number(obj_church_ripple_area)) : ""));
    }
    if (!man.active || man.lightcon == 2)
        return;
    for (var q = 0; q < 8; q++)
    {
        if (q == global.mp_myid || !global.mp_pconn[q] || global.mp_proom[q] != room)
            continue;
        var g = global.mp_pghost[q];
        if (!instance_exists(g) || !g.visible)
            continue;
        with (g)
        {
            var inarea = man.alwaysrip || collision_point(x + 18, y + 60, obj_church_ripple_area, false, true) != noone;
            var fr = floor(image_index);
            if (!variable_instance_exists(id, "mp_rip_stepped"))
                mp_rip_stepped = false;
            if (fr == 1 && !mp_rip_stepped && inarea)
            {
                mp_rip_stepped = true;
                scr_fancy_ripple(x + 18, y + 72, 60, 16159050, 220, 1, 18, 1999000, 0, 0);
                scr_fancy_ripple(x + 18, y + 72, 60, 16159050, 140, 1, 15, 1999000, 0, 0);
                if (global.mp_test != "" && mp_test_has("logpuz"))
                    show_debug_message("[MPRIPPLE] ripple for player " + string(q) + " at " + string(round(x)) + "," + string(round(y)));
            }
            else if (fr != 1)
                mp_rip_stepped = false;
        }
    }
}
