// DELTARUNE Multiplayer - watching another player (spectating on the map).
//
// F9 "Watch: < off / name >": my own character is hidden and stays still, and is kept where the
// watched player stands, so the game's own camera follows them; I follow them into other rooms
// too. Left/right switch between the players; F9 "Watch: off" (or the player leaving) stops it.
// The others don't see me (my character is hidden, so my position goes out as not drawn).
// Battles, cutscenes and pulls work as for anyone else: while one is on, it takes over.

function mp_spec_init()
{
    global.mp_spec = -1;          // the player I watch, or -1
    global.mp_spec_was = 0;       // my character was hidden for it (to show it again)
}

function mp_spec_on()
{
    return variable_global_exists("mp_spec") && global.mp_spec >= 0;
}

// The next connected player after `from` in direction d (1 or -1), or -1 (none / off).
function mp_spec_next(from, d)
{
    var p = from;
    for (var n = 0; n < 9; n++)
    {
        p += d;
        if (p > 7)
            p = -1;
        if (p < -1)
            p = 7;
        if (p == -1)
            return -1;
        if (p != global.mp_myid && global.mp_pconn[p])
            return p;
    }
    return -1;
}

function mp_spec_set(p)
{
    if (p == global.mp_spec)
        return;
    global.mp_spec = p;
    if (p < 0)
    {
        mp_spec_show_me();
        mp_notify("Stopped watching.");
        mp_log("spectate: off");
    }
    else
    {
        mp_notify("Watching " + global.mp_pname[p] + "  (left/right: someone else; F9 > Watch: off to stop)");
        mp_log("spectate: watching " + string(p));
    }
}

function mp_spec_show_me()
{
    if (!global.mp_spec_was)
        return;
    global.mp_spec_was = 0;
    with (obj_mainchara)
        visible = 1;
    with (obj_caterpillarchara)
        visible = 1;
}

// Free roam only: a battle, a cutscene, a room change or a pull is never held up by watching.
function mp_spec_free()
{
    return global.mp_sstate == 0 && !mp_in_battle_scene() && !global.mp_warp_pending && global.mp_warp_delay <= 0 && !is_array(global.mp_pull) && instance_exists(obj_mainchara) && !mp_credits_running();
}

// mp_sync_input: while watching on the map, left/right pick who, and nothing else moves me.
function mp_spec_input()
{
    if (!mp_spec_on() || global.mp_ui_open || !mp_spec_free())
        return;
    if (global.input_pressed[1])
        mp_spec_set(mp_spec_next(global.mp_spec, 1) < 0 ? mp_spec_next(-1, 1) : mp_spec_next(global.mp_spec, 1));
    else if (global.input_pressed[3])
        mp_spec_set(mp_spec_next(global.mp_spec, -1) < 0 ? mp_spec_next(8, -1) : mp_spec_next(global.mp_spec, -1));
    for (var i = 0; i < 10; i++)
    {
        global.input_pressed[i] = 0;
        global.input_held[i] = 0;
    }
}

// Every frame (mp_sync_tick).
function mp_spec_tick()
{
    if (!mp_spec_on())
        return;
    var p = global.mp_spec;
    if (!mp_on() || !global.mp_pconn[p])
    {
        mp_spec_set(-1);
        return;
    }
    if (!mp_spec_free())
        return;
    if (global.mp_proom[p] < 0 || !mp_room_ok(global.mp_proom[p]))
        return;
    if (global.mp_proom[p] != room)
    {
        // (They went through a door: after them, the way F8 goes.)
        global.mp_warp_reenter = mp_dz_take((global.mp_pstate[p] & 64) != 0 ? 1 : 0);
        global.mp_warp_mus = p;
        mp_warp(global.mp_proom[p], global.mp_pix[p], global.mp_piy[p], 0);
        return;
    }
    global.mp_spec_was = 1;
    var tx = global.mp_pix[p];
    var ty = global.mp_piy[p];
    with (obj_mainchara)
    {
        x = tx;
        y = ty;
        visible = 0;
    }
    with (obj_caterpillarchara)
    {
        x = tx;
        y = ty;
        visible = 0;
    }
}
