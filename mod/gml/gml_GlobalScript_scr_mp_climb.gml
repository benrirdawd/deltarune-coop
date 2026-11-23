// DELTARUNE Multiplayer - climbing (Chapters 4 and 5).
//
// Climbing walls is its own mode: the game hides the walking Kris far outside the room and the
// player moves obj_climb_kris on the wall. Everyone climbs in their own game; like the Chapter 5
// platformer, my climbing figure is what the others see as my ghost (state bit 32, same room
// coordinates), and walking figures aren't shown on the wall. (Not on the rotating towers.) Each player climbs as the character
// they play: Susie and Ralsei have climbing sprites of their own, the others stay Kris.

function mp_climb_obj()
{
    if (!variable_global_exists("mp_climb_o"))
    {
        global.mp_climb_o = asset_get_index("obj_climb_kris");
        global.mp_climb_spr = [-1, -1, asset_get_index("spr_susie_climb"), asset_get_index("spr_ralsei_climb"), -1];
    }
    return global.mp_climb_o;
}

function mp_climb_on()
{
    var o = mp_climb_obj();
    return o >= 0 && instance_exists(o);
}

// The sprite my character climbs with, for one of Kris's climbing sprites.
function mp_climb_sprite(spr)
{
    if (!variable_global_exists("mp_inited") || !mp_on() || !mp_swaps_enabled())
        return spr;
    mp_climb_obj();
    var ch = global.mp_cfg_char;
    if (ch < 2 || ch > 3 || global.mp_climb_spr[ch] < 0 || !sprite_exists(spr))
        return spr;
    if (string_pos("spr_kris_climb", sprite_get_name(spr)) != 1)
        return spr;
    return global.mp_climb_spr[ch];
}

// [x, y, sprite, image, xscale, yscale, visible] of my climbing figure, where it is drawn, or -1.
function mp_climb_send_info()
{
    if (!mp_climb_on())
        return -1;
    var r = -1;
    with (instance_find(mp_climb_obj(), 0))
    {
        var dx = variable_instance_exists(id, "drawx") ? drawx : 0;
        var dy = (variable_instance_exists(id, "drawy") ? drawy : 0) + (variable_instance_exists(id, "drawoffsety") ? drawoffsety : 0);
        // (On a rotating tower the tower draws the climber, projected around it: not shown to the
        // others there.)
        var tw = asset_get_index("obj_rotating_tower_controller_new");
        var shown = visible && !(tw >= 0 && instance_exists(tw));
        r = [round(x + dx), round(y + dy), mp_climb_sprite(sprite_index), image_index, image_xscale, image_yscale, shown ? 1 : 0];
    }
    return r;
}

// Ghosts on the wall are drawn just in front of the climber.
function mp_climb_ghost_depth()
{
    if (mp_climb_on())
        return instance_find(mp_climb_obj(), 0).depth - 1;
    return 0;
}
