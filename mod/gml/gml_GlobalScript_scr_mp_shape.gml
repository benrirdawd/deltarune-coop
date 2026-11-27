// Chapter 2's shape puzzles (the dark bulb rooms of the mansion, and Shaun's room): a button
// steers a piece into the outline. It was each player's own: a friend at the button moved the
// piece only in their game. Now the steering player's game sends the piece's place and turn when
// they change (message 89) and the others' piece goes there too. When it fits, their outline
// lights up as it does for the solver. The solve's story scene is the solver's (the shared
// cutscene), so a copy moved by a friend doesn't check the fit itself. A room can have several
// buttons, each with its own piece: the message names the button by where it stands.

// obj_shapepuzzlebutton Step (prepended): runs as the button.
function mp_shape_step()
{
    if (!variable_global_exists("mp_inited") || !mp_on() || !instance_exists(myPiece))
        return;
    var sx = myPiece.x, sy = myPiece.y, sa = myPiece.image_angle;
    var gh = 0;
    with (asset_get_index("obj_shapepuzzle"))
        gh = goalHit;
    if (!variable_instance_exists(id, "mp_sh_last"))
        mp_sh_last = [sx, sy, sa, gh];
    // (Test token shapebot: the piece moves a step right every 20 frames while I steer.)
    if (active && mp_test_has("shapebot") && (global.mp_frame mod 20) == 0)
    {
        myPiece.x += moveAmount;
        sx = myPiece.x;
    }
    // (Test token shapesolve: 3 s into my steering, the piece counts as fitting.)
    if (active && mp_test_has("shapesolve"))
    {
        if (!variable_instance_exists(id, "mp_sh_t"))
            mp_sh_t = 0;
        if (++mp_sh_t == 180)
        {
            // (As the puzzle's own fit check does it: the glow, and the room's scene goes on.)
            with (asset_get_index("obj_shapepuzzle"))
            {
                goalHit = true;
                goalCheck = false;
            }
            with (asset_get_index("obj_shapepuzzlepiece"))
                slowOff = true;
            var rn = room_get_name(room);
            var scn = asset_get_index(rn == "room_dw_mansion_darkbulb_1" ? "obj_ch2_scene19a" : (rn == "room_dw_mansion_darkbulb_2" ? "obj_ch2_scene19b" : "obj_ch2_scene19c"));
            if (scn >= 0)
            {
                with (scn)
                    con = 20;
            }
            gh = 1;
            mp_log("[test] shapesolve: the piece fits");
        }
    }
    if (!active && !(gh && !mp_sh_last[3]))
        return;
    if (sx == mp_sh_last[0] && sy == mp_sh_last[1] && sa == mp_sh_last[2] && gh == mp_sh_last[3])
        return;
    mp_sh_last = [sx, sy, sa, gh];
    mp_begin(89);
    mp_wu16(room);
    mp_ws16(xstart);
    mp_ws16(ystart);
    mp_wf64(sx);
    mp_wf64(sy);
    mp_wf64(sa);
    mp_wu8(gh);
    mp_send();
    mp_log("shape puzzle: my piece at " + string(sx) + "," + string(sy) + " turned " + string(sa) + (gh ? " (fits)" : ""));
}

function mp_shape_recv(from, b)
{
    var rm = buffer_read(b, buffer_u16);
    var bx = buffer_read(b, buffer_s16);
    var by = buffer_read(b, buffer_s16);
    var sx = buffer_read(b, buffer_f64);
    var sy = buffer_read(b, buffer_f64);
    var sa = buffer_read(b, buffer_f64);
    var gh = buffer_read(b, buffer_u8);
    if (rm != room)
        return;
    var bt = asset_get_index("obj_shapepuzzlebutton");
    if (bt < 0 || !instance_exists(bt))
        return;
    with (bt)
    {
        // (Each button steers its own piece; not while I steer it myself: my keys win in my game.)
        if (xstart != bx || ystart != by || active || !instance_exists(myPiece))
            continue;
        myPiece.x = sx;
        myPiece.y = sy;
        myPiece.image_angle = sa;
        mp_sh_last = [sx, sy, sa, gh];
    }
    mp_log("shape puzzle: " + string(from) + "'s piece at " + string(sx) + "," + string(sy) + " turned " + string(sa) + (gh ? " (fits)" : ""));
    if (gh)
    {
        with (asset_get_index("obj_shapepuzzle"))
        {
            if (!goalHit)
            {
                var sn = asset_get_index("snd_shadowpendant");
                if (sn >= 0)
                    snd_play(sn);
                goalHit = true;
                goalCheck = false;
                with (asset_get_index("obj_shapepuzzlepiece"))
                    slowOff = true;
            }
        }
        // (The fit came from a friend: my buttons don't send it back.)
        with (bt)
        {
            if (instance_exists(myPiece))
                mp_sh_last = [myPiece.x, myPiece.y, myPiece.image_angle, 1];
        }
    }
}
