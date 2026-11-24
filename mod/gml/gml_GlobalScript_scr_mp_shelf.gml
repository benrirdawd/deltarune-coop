// @chapters 4
// DELTARUNE Multiplayer - Chapter 4's bookshelf puzzle (room_dw_church_bookshelfpuzzle and its
// reversed copy): the remote pianos slide the coloured shelves (obj_bookshelf_moveable2x2).
//
// The game already keeps each shelf's place in two story flags (xflag/yflag, 876-881) and writes
// them when a move ends; story flags are shared with everyone. So a shelf only has to follow its
// flags: when they say it is somewhere else (a friend moved it with a piano in their game), it
// slides there the way a reset slides it. Simplest choice: no message of its own; two players moving
// the same shelf at once end where the last move put it, in every game.

// Appended to the shelf's Step, right after it writes its own flags.
function mp_shelf_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (con != 0 || xflag == -4)
        return;
    var fx = global.flag[xflag];
    var fy = global.flag[yflag];
    if (fx == 0 || fy == 0 || (fx == x && fy == y))
        return;
    var dist = round(point_distance(x, y, fx, fy) / 16) + 1;
    mp_log("shelf " + string(xstart) + "," + string(ystart) + ": moved by a friend, " + string(x) + "," + string(y) + " -> " + string(fx) + "," + string(fy));
    if (x != fx)
        scr_lerpvar("x", x, fx, dist);
    if (y != fy)
        scr_lerpvar("y", y, fy, dist);
    con = -1;
    scr_delay_var("con", 0, dist + 1);
    snd_play_delay(snd_wing, dist, 0.7, 0.8);
}

// Test token moveshelf:<i>:<dir>@<frame>: at that room frame, slide the room's i-th shelf in
// direction dir (0 down, 1 right, 2 up, 3 left), as its piano does (it only moves when the room lets
// it: the floor the player stands on decides which walls count). logpuz logs the shelves.
function mp_shelf_test()
{
    if (!variable_global_exists("mp_inited") || global.mp_test == "" || !variable_global_exists("mp_test_timer"))
        return;
    if (mp_test_has("moveshelf"))
    {
        var a = mp_test_arg("moveshelf");
        var at = string_pos("@", a);
        var c = string_pos(":", a);
        if (at > 0 && c > 0 && global.mp_test_timer == real(string_delete(a, 1, at)))
        {
            var i = real(string_copy(a, 1, c - 1));
            var d = real(string_copy(a, c + 1, at - c - 1));
            if (i < instance_number(obj_bookshelf_moveable2x2))
            {
                with (instance_find(obj_bookshelf_moveable2x2, i))
                {
                    if (con == 0)
                    {
                        dir = d;
                        con = 1;
                        timer = 0;
                        mp_log("[test] moveshelf " + string(xstart) + "," + string(ystart) + " dir " + string(d));
                    }
                }
            }
        }
    }
    // shelfflag:<i>:<dx>@<frame>: as if a friend's game had moved the i-th shelf dx pixels sideways
    // (what its move leaves behind: the shelf's place flag, shared like every story flag).
    if (mp_test_has("shelfflag"))
    {
        var a2 = mp_test_arg("shelfflag");
        var at2 = string_pos("@", a2);
        var c2 = string_pos(":", a2);
        if (at2 > 0 && c2 > 0 && global.mp_test_timer == real(string_delete(a2, 1, at2)))
        {
            var i2 = real(string_copy(a2, 1, c2 - 1));
            var dx = real(string_copy(a2, c2 + 1, at2 - c2 - 1));
            if (i2 < instance_number(obj_bookshelf_moveable2x2))
            {
                with (instance_find(obj_bookshelf_moveable2x2, i2))
                {
                    if (xflag != -4)
                    {
                        global.flag[xflag] = x + dx;
                        mp_log("[test] shelfflag " + string(xstart) + "," + string(ystart) + " flag x -> " + string(x + dx));
                    }
                }
            }
        }
    }
    if (mp_test_has("logpuz") && (global.mp_frame mod 150) == 0 && instance_exists(obj_bookshelf_moveable2x2))
    {
        var s = "";
        with (obj_bookshelf_moveable2x2)
            s += " " + string(xstart) + "," + string(ystart) + "->" + string(x) + "," + string(y) + "(flag " + string(xflag >= 0 ? global.flag[xflag] : -1) + "," + string(yflag >= 0 ? global.flag[yflag] : -1) + ")";
        show_debug_message("[MPSHELF] room=" + room_get_name(room) + s);
    }
}
