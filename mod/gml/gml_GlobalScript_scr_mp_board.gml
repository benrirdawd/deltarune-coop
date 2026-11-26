// @chapters 1,2,4,5
// DELTARUNE Multiplayer - Chapter 3 board game support (stubs; see gml/ch3 for the real one).

function mp_board_on()
{
    return false;
}

function mp_board_send_info()
{
    return -1;
}

function mp_board_ghost_xy(pid)
{
    return -1;
}

function mp_board_ghost_depth()
{
    return 0;
}

function mp_board_draw_piece(xx, yy)
{
    draw_sprite_ext(sprite_index, image_index, xx, yy, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

function mp_sm_tick()
{
}

function mp_sm_recv(from, b, endpos = -1)
{
    buffer_read(b, buffer_f64);
}

function mp_tv_row_on()
{
    return false;
}

function mp_tv_row_draw(sh)
{
}
