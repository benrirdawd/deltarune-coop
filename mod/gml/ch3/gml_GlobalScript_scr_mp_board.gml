// DELTARUNE Multiplayer - Chapter 3 board game.
//
// The board works like walking around: everyone plays their own copy of the board, and the
// other players' pieces are shown on it. The board is always shown at the same place in the
// room (x 128-512, y 64-320); moving to another board screen shifts the BOARD_Tiles layer,
// so a position on the whole board is the piece's x/y minus that layer's offset.

function mp_board_on()
{
    return instance_exists(obj_mainchara_board) && layer_get_id("BOARD_Tiles") != -1;
}

// The piece I steer, or noone.
function mp_board_lead()
{
    var k = noone;
    with (obj_mainchara_board)
    {
        if (controlled && name == "kris")
            k = id;
    }
    if (k == noone)
    {
        with (obj_mainchara_board)
        {
            if (controlled)
                k = id;
        }
    }
    return k;
}

function mp_board_char(nm)
{
    if (nm == "kris")
        return 1;
    if (nm == "susie")
        return 2;
    if (nm == "ralsei")
        return 3;
    return 0;
}

// Board sprite of another character (spr_board_kris_walk_down -> spr_board_susie_walk_down).
function mp_board_swap(spr, fromc, toc)
{
    if (fromc == toc || fromc == 0 || toc == 0 || !sprite_exists(spr))
        return spr;
    var key = "b" + string(spr) + "_" + string(toc);
    if (ds_map_exists(global.mp_swapcache, key))
        return ds_map_find_value(global.mp_swapcache, key);
    var n = sprite_get_name(spr);
    var fp = "spr_board_" + mp_char_prefix(fromc);
    var res = spr;
    if (string_pos(fp, n) == 1)
    {
        var s = mp_try_sprite("spr_board_" + mp_char_prefix(toc) + string_delete(n, 1, string_length(fp)));
        if (s < 0)
        {
            // Fall back to walking in the same direction.
            var d = "down";
            if (string_pos("_left", n) > 0)
                d = "left";
            if (string_pos("_right", n) > 0)
                d = "right";
            if (string_pos("_up", n) > 0)
                d = "up";
            s = mp_try_sprite("spr_board_" + mp_char_prefix(toc) + "_walk_" + d);
        }
        if (s >= 0)
            res = s;
    }
    ds_map_set(global.mp_swapcache, key, res);
    return res;
}

// Replaces the board pieces' own drawing (obj_mainchara_board Draw).
function mp_board_draw_piece(xx, yy)
{
    var spr = sprite_index;
    if (variable_global_exists("mp_inited") && mp_on())
    {
        var c = mp_board_char(name);
        if (c != 0)
        {
            var shown = c;
            if (c == 1)
                shown = global.mp_cfg_char;
            else if (c == global.mp_cfg_char)
                shown = 1;
            // Pieces other players are playing are shown where they are (their ghost).
            if (mp_char_player_other(shown) >= 0)
                return;
            spr = mp_board_swap(sprite_index, c, shown);
            if (c != 1)
                global.mp_fol_mask |= 1 << shown;
            if (c == 1)
            {
                global.mp_board_spr = spr;
                global.mp_board_img = image_index;
                global.mp_board_drawn = global.mp_frame;
            }
        }
    }
    draw_sprite_ext(spr, image_index, xx, yy, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

// What to send as my position while on the board: [x, y, sprite, frame, xs, ys, visible]
// with x/y relative to the whole board.
function mp_board_send_info()
{
    if (!mp_board_on())
        return -1;
    var k = mp_board_lead();
    if (k == noone)
        return -1;
    var tl = layer_get_id("BOARD_Tiles");
    var spr = k.sprite_index;
    var img = k.image_index;
    if (variable_global_exists("mp_board_drawn") && (global.mp_frame - global.mp_board_drawn) < 3)
    {
        spr = global.mp_board_spr;
        img = global.mp_board_img;
    }
    var vis = k.visible;
    if (variable_instance_exists(k, "myhealth") && k.myhealth <= 0)
        vis = false;
    return [k.x - layer_get_x(tl), k.y - layer_get_y(tl), spr, img, k.image_xscale, k.image_yscale, vis];
}

// Where another player's piece is on my screen, or -1 if it isn't on the board screen I see.
function mp_board_ghost_xy(pid)
{
    if (!mp_board_on())
        return -1;
    var tl = layer_get_id("BOARD_Tiles");
    var gx = global.mp_px[pid] + layer_get_x(tl);
    var gy = global.mp_py[pid] + layer_get_y(tl);
    if (gx < 128 || gy < 64 || gx > (512 - 16) || gy > (320 - 16))
        return -1;
    return [gx, gy];
}

function mp_board_ghost_depth()
{
    var k = mp_board_lead();
    if (k != noone)
        return k.depth + 1;
    return 0;
}

// ---------------------------------------------------------------- Shadow Mantle
// Everyone fights their own copy (as everyone plays their own board), and the boss has HP x the
// players fighting him: each hit anyone lands takes 1/N of its damage from every copy (mine at
// once, the others' when their count arrives). The game's own rules on top stay as they are (the
// HP held at 4 until the last phase, the phases at 22/13/4, his defeat below 1).
function mp_sm_init()
{
    if (!variable_global_exists("mp_sm_rtot"))
    {
        global.mp_sm_on = 0;
        global.mp_sm_rtot = array_create(8, 0);
        global.mp_sm_seen = array_create(8, 0);
        global.mp_sm_rf = array_create(8, -99999);
        global.mp_sm_rhp = array_create(8, -1);
        global.mp_sm_hif = -1;
    }
}

function mp_sm_tick()
{
    mp_sm_init();
    var e = noone;
    with (obj_shadow_mantle_enemy)
        e = id;
    if (e == noone || !mp_on())
    {
        global.mp_sm_on = 0;
        return;
    }
    if (!global.mp_sm_on)
    {
        global.mp_sm_on = 1;
        global.mp_sm_last = e.hp;
        global.mp_sm_mine = 0;
        global.mp_sm_sent = -1;
        global.mp_sm_sentf = -9999;
        for (var i0 = 0; i0 < 8; i0++)
            global.mp_sm_seen[i0] = global.mp_sm_rtot[i0];
        mp_log("Shadow Mantle: fight starts, hp " + string(e.hp));
    }
    // Who fights him with me: in my room, and their count came in within 3 s (sent while they fight).
    var n = 1;
    for (var i = 0; i < 8; i++)
    {
        if (i != global.mp_myid && global.mp_pconn[i] && global.mp_proom[i] == room && (current_time - global.mp_sm_rf[i]) < 3000)
            n += 1;
    }
    var d = global.mp_sm_last - e.hp;
    if (d > 0.0001)
    {
        global.mp_sm_mine += d;
        e.hp = global.mp_sm_last - (d / n);
        mp_log("Shadow Mantle: my hit " + string(d) + " / " + string(n) + " -> hp " + string(e.hp));
    }
    for (var j = 0; j < 8; j++)
    {
        if (j == global.mp_myid)
            continue;
        if (global.mp_sm_rtot[j] < global.mp_sm_seen[j])
            global.mp_sm_seen[j] = 0;     // they started over (a new try)
        var r = global.mp_sm_rtot[j] - global.mp_sm_seen[j];
        if (r > 0.0001)
        {
            global.mp_sm_seen[j] = global.mp_sm_rtot[j];
            if (global.mp_pconn[j] && global.mp_proom[j] == room)
            {
                e.hp -= r / n;
                mp_log("Shadow Mantle: " + global.mp_pname[j] + "'s hit " + string(r) + " / " + string(n) + " -> hp " + string(e.hp));
            }
        }
    }
    // The game's own rules run only on my sword's hit (obj_shadow_mantle_enemy Step_2): a friend's hit
    // goes through the same ones here (held at 4 until the last phase, defeated below 1).
    if ((e.phase != 4 || e.phasetransitioncon == 1) && e.hp < 4)
        e.hp = 4;
    if (e.hp < 1 || (e.hp < 2 && global.shadow_mantle_losses >= 7))
    {
        mp_log("Shadow Mantle: defeated (hp " + string(e.hp) + ")");
        mp_sm_defeat(e);
        global.mp_sm_on = 0;
        return;
    }
    // Copies drift apart when the players' fights start at different moments (a hit before the
    // other's fight began counts whole on one side, halved on the other): everyone follows the copy
    // of the first player in the fight (lowest number). Lower there: they counted something I didn't,
    // take it at once. Higher for 2 s: I counted something they didn't (my hits reach them in less).
    var lead = global.mp_myid;
    for (var k = 0; k < 8; k++)
    {
        if (k < lead && global.mp_pconn[k] && global.mp_proom[k] == room && (current_time - global.mp_sm_rf[k]) < 3000)
            lead = k;
    }
    if (lead != global.mp_myid && global.mp_sm_rhp[lead] >= 0)
    {
        var lh = global.mp_sm_rhp[lead];
        if (lh < e.hp - 0.01)
        {
            mp_log("Shadow Mantle: following " + global.mp_pname[lead] + "'s copy, hp " + string(e.hp) + " -> " + string(lh));
            e.hp = lh;
            global.mp_sm_hif = -1;
        }
        else if (lh > e.hp + 0.01)
        {
            if (global.mp_sm_hif < 0)
                global.mp_sm_hif = current_time;
            else if ((current_time - global.mp_sm_hif) > 2000)
            {
                mp_log("Shadow Mantle: following " + global.mp_pname[lead] + "'s copy, hp " + string(e.hp) + " -> " + string(lh));
                e.hp = lh;
                global.mp_sm_hif = -1;
            }
        }
        else
            global.mp_sm_hif = -1;
    }
    global.mp_sm_last = e.hp;
    if ((global.mp_sm_sent != global.mp_sm_mine || (global.mp_frame - global.mp_sm_sentf) > 30) && (global.mp_frame - global.mp_sm_sentf) >= 3)
    {
        mp_begin(86);
        mp_wf64(global.mp_sm_mine);
        mp_wf64(e.hp);   // (since build 21: my copy's HP, for the others to follow the first player's)
        mp_send();
        global.mp_sm_sent = global.mp_sm_mine;
        global.mp_sm_sentf = global.mp_frame;
    }
}

// His defeat, as the game does it when a sword hit takes him below 1 (Step_2).
function mp_sm_defeat(e)
{
    with (e)
    {
        snd_free(global.currentsong[0]);
        instance_create(x, y, obj_shadow_mantle_enemy_outro);
        instance_destroy();
    }
    with (obj_shadow_mantle_clone)
        instance_destroy();
    with (obj_shadow_mantle_cloud_bullet)
        instance_destroy();
    with (obj_shadow_mantle_bomb)
        instance_destroy();
    with (obj_shadow_mantle_cloud)
        instance_destroy();
    with (obj_shadow_mantle_enemy_spawn)
        instance_destroy();
    with (obj_shadow_mantle_fire_controller)
        instance_destroy();
    with (obj_shadow_mantle_fire)
        instance_destroy();
    with (obj_spawn_pos)
        instance_destroy();
    with (obj_shadow_mantle_fire3)
        instance_destroy();
    with (obj_shadow_mantle_groundfire)
        instance_destroy();
    with (obj___)
        instance_destroy();
}

function mp_sm_recv(from, b, endpos = -1)
{
    mp_sm_init();
    var t = buffer_read(b, buffer_f64);
    if (from < 0 || from > 7)
        return;
    global.mp_sm_rtot[from] = t;
    global.mp_sm_rf[from] = current_time;
    if (endpos >= 0 && buffer_tell(b) + 8 <= endpos)
        global.mp_sm_rhp[from] = buffer_read(b, buffer_f64);
}

// ---------------------------------------------------------------- the TV row (sword route)
// On the route where Kris plays the board alone (scr_swordroom: Kris stands at the console holding
// the controller), every player's hero stands at the TV with him: Kris (the game's own, never
// swapped) in the middle, the others side by side, as the normal board's party stands (Susie on the
// left, Ralsei on the right, at the same distances; Noelle takes the next free place).
function mp_tv_row_on()
{
    return variable_global_exists("mp_inited") && mp_on();
}

// From obj_gameshow_swordroute's Draw, inside with (kris), in place of the game's three draws of Kris.
// The others stand beside him only while he holds the controller at the console (not while he
// walks there after a loss). (Outside the TV the board rooms show the game's own party: no swaps.)
function mp_tv_kris_draw(sh)
{
    var spr = sprite_index;
    var atconsole = string_pos("holdcontroller", sprite_get_name(spr)) > 0;
    var h = sprite_get_height(spr) * image_yscale;
    draw_sprite_ext(spr, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
    draw_sprite_ext(spr, image_index, x, y + 2, image_xscale, image_yscale, image_angle, c_gray, 1 * sh);
    draw_sprite_ext(spr, image_index, x, (y + (h * 2)) - 4, image_xscale, -image_yscale, image_angle, c_black, 0.8 * sh);
    if (atconsole)
        mp_tv_row_draw(sh);
}

// From mp_tv_kris_draw (Kris at the console) right after Kris is drawn: the same three
// passes (the figure, its gray glow, the reflection on the floor) for each hero.
function mp_tv_row_draw(sh)
{
    var has = [0, 0, 0, 0, 0];
    var me = global.mp_cfg_char;
    if (me >= 2 && me <= 4)
        has[me] = 1;
    for (var i = 0; i < 8; i++)
    {
        if (i != global.mp_myid && global.mp_pconn[i] && global.mp_proom[i] == room)
        {
            var c = global.mp_pchar[i];
            if (c >= 2 && c <= 4)
                has[c] = 1;
        }
    }
    // Places: left, right, far left, far right (offsets from Kris, as the board's party stands).
    var used = [0, 0, 0, 0];
    // Their backs to us, facing the TV like Kris (the game has no back view of them holding a
    // controller: SPRITES.md).
    var sprs = ["", "", "spr_susie_walk_up_dw", "spr_ralsei_walk_up", "spr_noelle_walk_up_dw"];
    var alts = ["", "", "spr_susie_walk_up_dw", "spr_ralsei_walk_up", "spr_noelle_walk_up_dw"];
    var pref = [0, 0, 0, 1, 1];
    var n = 0;
    for (var c = 2; c <= 4; c++)
    {
        if (!has[c])
            continue;
        var spr = mp_try_sprite(sprs[c]);
        if (spr < 0)
            spr = mp_try_sprite(alts[c]);
        if (spr < 0)
            continue;
        var p = pref[c];
        if (used[p])
            p = 1 - p;
        if (used[p])
            p += 2;
        if (used[p])
            p = (p == 2) ? 3 : 2;
        used[p] = 1;
        // Close beside him, as players sharing one TV.
        var hw = sprite_get_width(spr) * image_xscale;
        var hx = x - hw + 4;
        if (p == 1)
            hx = x + sprite_width - 4;
        if (p == 2)
            hx = x - (2 * hw) + 8;
        if (p == 3)
            hx = x + sprite_width + hw - 8;
        var hy = y + sprite_height - (sprite_get_height(spr) * image_yscale); // feet in line with Kris's
        draw_sprite_ext(spr, 0, hx, hy, image_xscale, image_yscale, 0, image_blend, image_alpha);
        draw_sprite_ext(spr, 0, hx, hy + 2, image_xscale, image_yscale, 0, c_gray, sh);
        draw_sprite_ext(spr, 0, hx, (hy + (sprite_get_height(spr) * image_yscale * 2)) - 4, image_xscale, -image_yscale, 0, c_black, 0.8 * sh);
        n++;
    }
    if (!variable_global_exists("mp_tv_row_n") || n != global.mp_tv_row_n)
    {
        global.mp_tv_row_n = n;
        mp_log("tv row: " + string(n) + " hero(es) beside Kris (susie " + string(has[2]) + " ralsei " + string(has[3]) + " noelle " + string(has[4]) + ")");
    }
}
