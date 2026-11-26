if (pid < 0)
{
    instance_destroy();
    exit;
}
// Leaving: stays where it was last seen and fades out.
if (leaving)
{
    fade -= 0.12;
    if (fade <= 0)
    {
        if (global.mp_pghost[pid] == id)
            global.mp_pghost[pid] = -4;
        instance_destroy();
    }
    exit;
}
// Coming in: their first positions in a new room can still be the old room's or where the room
// put them before the door did (a jump a frame later): hidden for a moment, then it fades in.
var since = current_time - max(born, global.mp_proom_t[pid]);
if (since < 150)
{
    fade = 0;
    snap = 1;
}
else
    fade = min(1, fade + 0.1);
var tx = global.mp_px[pid];
var ty = global.mp_py[pid];
var board = (global.mp_pstate[pid] & 16) != 0;
if (board)
{
    // Chapter 3 board piece: board position -> my screen (the board scrolls under the view).
    var bxy = mp_board_ghost_xy(pid);
    if (!is_array(bxy))
        exit;
    tx = bxy[0];
    ty = bxy[1];
}
if (snap || point_distance(x, y, tx, ty) > 120)
{
    x = tx;
    y = ty;
    snap = 0;
}
else
{
    // Positions arrive ~10 times a second; ease towards them for smooth motion at any latency.
    x = lerp(x, tx, 0.4);
    y = lerp(y, ty, 0.4);
    if (abs(x - tx) < 0.5)
        x = tx;
    if (abs(y - ty) < 0.5)
        y = ty;
}
sprite_index = global.mp_pspr[pid];
image_index = global.mp_pimg[pid];
image_xscale = global.mp_pxs[pid];
image_yscale = global.mp_pys[pid];
if (board)
    depth = mp_board_ghost_depth();
else if ((global.mp_pstate[pid] & 32) != 0)
    depth = mp_climb_on() ? mp_climb_ghost_depth() : mp_plat_ghost_depth();
else
    depth = 100000 - ((y * 10) + (sprite_get_height(sprite_index) * image_yscale * 10));
