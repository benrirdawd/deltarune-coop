// DELTARUNE Multiplayer - Chapter 5 platforming (side-scrolling) sections.
//
// In these rooms the game swaps the walking party for its own platformer: obj_plat_player
// (always Kris's platformer sprites), with the rest of the party as obj_plat_follower. Everyone
// plays their own copy of the room, like the Chapter 3 board: your platformer figure is what
// the others see as your ghost (same room coordinates, the platformer scrolls the normal view).

function mp_plat_on()
{
    return instance_exists(obj_plat_player);
}

// [x, y, sprite, image, xscale, yscale, visible] of my platformer figure, where it is drawn
// (obj_plat_player draws itself shifted by its sprite offset), or -1.
function mp_plat_send_info()
{
    if (!instance_exists(obj_plat_player))
        return -1;
    var p = instance_find(obj_plat_player, 0);
    var r = -1;
    with (p)
    {
        r = [round(x - (sprite_offset_x * image_xscale)), round(y - (sprite_offset_y * image_yscale)), sprite_index, image_index, image_xscale, image_yscale, player_visible ? 1 : 0];
    }
    // Playing Susie or Ralsei: shown as them, with the sprites of their platformer follower, feet
    // where Kris's figure stands.
    var sub = mp_plat_char_sprite(p.sprite_index);
    if (sub >= 0)
    {
        var fx = (p.bbox_left + p.bbox_right) / 2;
        var fy = p.bbox_bottom + 1;
        var xs = sign(p.image_xscale) == 0 ? 1 : sign(p.image_xscale);
        r[0] = round(fx - ((sprite_get_width(sub) / 2) - sprite_get_xoffset(sub)) * xs);
        r[1] = round(fy - (sprite_get_height(sub) - sprite_get_yoffset(sub)));
        r[2] = sub;
        r[3] = floor(p.image_index) mod max(1, sprite_get_number(sub));
        r[4] = xs;
        r[5] = 1;
    }
    return r;
}

// The sprite of my own character (Susie, Ralsei) for what Kris's platformer figure is doing, or -1
// (playing Kris or Noelle, or that follower isn't in the room: shown as Kris).
function mp_plat_char_sprite(spr)
{
    var c = global.mp_pchar[global.mp_myid] - 1;
    if (c != 1 && c != 2)
        return -1;
    var f = noone;
    with (obj_plat_follower)
    {
        if (variable_instance_exists(id, "character") && character == c && variable_instance_exists(id, "spr_idle"))
            f = id;
    }
    if (f == noone)
        return -1;
    var n = sprite_get_name(spr);
    var out = variable_instance_get(f, "spr_idle");
    if (string_pos("runstop", n) > 0)
        out = variable_instance_get(f, "spr_halt");
    else if (string_pos("_run", n) > 0)
        out = variable_instance_get(f, "spr_run");
    else if (string_pos("_turn", n) > 0)
        out = variable_instance_get(f, "spr_turn");
    else if (string_pos("_land", n) > 0)
        out = variable_instance_get(f, "spr_land");
    else if (string_pos("_climb", n) > 0)
        out = variable_instance_get(f, "spr_climb");
    else if (string_pos("_jump", n) > 0)
        out = variable_instance_get(f, "spr_jump");
    else if (string_pos("_fall", n) > 0 || string_pos("_air", n) > 0 || string_pos("ball", n) > 0)
        out = variable_instance_get(f, "spr_fall");
    return sprite_exists(out) ? out : -1;
}

// Ghosts are drawn with the platformer's own figure, just in front of it.
function mp_plat_ghost_depth()
{
    if (instance_exists(obj_plat_player))
        return instance_find(obj_plat_player, 0).depth - 1;
    return 0;
}
