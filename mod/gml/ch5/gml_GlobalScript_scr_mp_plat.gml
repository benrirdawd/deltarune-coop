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

// A friend who plays Susie or Ralsei is drawn as them in my platforming room, and the game's own
// Susie/Ralsei follower was drawn next to them: two of the same. Now, in my game, the follower of a
// character a friend in my platforming room plays is hidden (only not drawn: it still follows,
// carries and helps as the game wants). Simplest choice: hidden, not removed. Every 10 frames.
function mp_plat_followers_tick()
{
    if (!mp_on() || !instance_exists(obj_plat_follower) || (global.mp_frame mod 10) != 0)
        return;
    var plat = mp_plat_on();
    with (obj_plat_follower)
    {
        if (!variable_instance_exists(id, "character"))
            continue;
        var c = character + 1;
        var taken = false;
        for (var i = 0; i < 8 && plat; i++)
        {
            if (i != global.mp_myid && global.mp_pconn[i] && global.mp_pchar[i] == c && global.mp_proom[i] == room && global.mp_pvis[i] && (global.mp_pstate[i] & 32) != 0)
                taken = true;
        }
        if (taken && visible)
        {
            visible = false;
            mp_mp_hid = 1;
            mp_log("platformer: the game's " + (c == 2 ? "Susie" : "Ralsei") + " follower hidden (a friend plays them here)");
        }
        else if (!taken && !visible && variable_instance_exists(id, "mp_mp_hid") && mp_mp_hid)
        {
            visible = true;
            mp_mp_hid = 0;
            mp_log("platformer: the game's follower shown again");
        }
    }
}

// Coins the game remembers (pink coins and the cliffs' counted coins: a bit of a story flag, set when
// taken, so the coin isn't made again). The flag is shared, but a coin already in my room stayed: I
// could take a coin a friend took, counted twice. Now a remembered coin whose bit is set while it is
// still in my room (only a friend's take can do that: my own take removes it at once) goes, without
// counting. Prepended to obj_plat_coin's Step. Simplest choice: two takes in the same moment, before
// the flag arrives, still both count.
function mp_plat_coin_follow()
{
    if (flag <= 0 || !variable_global_exists("mp_inited") || !mp_on())
        return;
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0 && id == instance_find(obj_plat_coin, 0))
    {
        var n = 0;
        with (obj_plat_coin)
        {
            if (flag > 0)
                n++;
        }
        show_debug_message("[MPCOIN] room=" + room_get_name(room) + " remembered coins=" + string(n) + " flag" + string(flag) + "=" + string(global.flag[flag]));
    }
    if (!mp_friend_set_bit(flag, flagbit))
        return;
    if (ignore_flag_if_plot_greater > 0 && global.plot >= ignore_flag_if_plot_greater)
        return;
    mp_log("[MPCOIN] a friend took coin flag" + string(flag) + " bit " + string(flagbit) + ": gone here too");
    instance_destroy();
    exit;
}

// Pinata bells the game remembers (a bit of a story flag, set when broken: the gold bell drops its
// coins, the pink one its pink coin). Same as the coins: a friend's bell still whole in my room could
// be broken again for the coins. Now when its bit arrives, my bell does what the room does when you
// come back: the gold one is broken (no coins), the pink one goes. Prepended to both bells' Step.
// My own break sets broken / was_hit at once, so it is never taken for a friend's.
function mp_plat_bell_follow()
{
    if (flag <= 0 || !variable_global_exists("mp_inited") || !mp_on())
        return;
    if (!mp_friend_set_bit(flag, flagbit))
        return;
    if (object_index == obj_plat_pinatabell_pink)
    {
        if (was_hit == 0)
        {
            mp_log("[MPCOIN] a friend broke pink bell flag" + string(flag) + " bit " + string(flagbit) + ": gone here too");
            instance_destroy();
            exit;
        }
    }
    else if (!broken)
    {
        mp_log("[MPCOIN] a friend broke bell flag" + string(flag) + " bit " + string(flagbit) + ": broken here too");
        broken = true;
    }
}

// Leaf piles (dashed through: coins, a chest or an NPC inside) and paper grass (cut: coins) the game
// remembers the same way. When a friend's bit arrives while mine is still whole, it goes the way the
// room removes it when you come back: with nothing inside, no coins (paper grass still has hp, so
// its Destroy event makes nothing). Leaf piles: prepended to their Step; paper grass: its End Step.
function mp_remembered_follow()
{
    if (flag <= 0 || !variable_global_exists("mp_inited") || !mp_on())
        return;
    if (!mp_friend_set_bit(flag, flagbit))
        return;
    if (object_index == obj_papergrass && hp <= 0)
        return;
    mp_log("[MPCOIN] a friend broke " + object_get_name(object_index) + " flag" + string(flag) + " bit " + string(flagbit) + ": gone here too");
    instance_destroy();
    exit;
}
