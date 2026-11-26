if (pid < 0 || !sprite_exists(sprite_index))
    exit;
if (fade <= 0)
    exit;
// I'm playing a minigame: nobody else's figure over it.
if (global.mp_mg != "")
    exit;
// In a fight (separate fights): their character's battle stance, feet where they stood.
var fighting = mp_ghost_fighting(pid);
var dspr = sprite_index;
var dimg = image_index;
var dx = x;
var dy = y;
if (fighting)
{
    var bs = mp_battle_idle_sprite(global.mp_pchar[pid]);
    if (bs >= 0)
    {
        var fx = x + (((sprite_get_width(sprite_index) / 2) - sprite_get_xoffset(sprite_index)) * image_xscale);
        var fy = y + ((sprite_get_height(sprite_index) - sprite_get_yoffset(sprite_index)) * image_yscale);
        dspr = bs;
        dimg = current_time / 160;
        dx = fx - (((sprite_get_width(bs) / 2) - sprite_get_xoffset(bs)) * abs(image_xscale));
        dy = fy - ((sprite_get_height(bs) - sprite_get_yoffset(bs)) * image_yscale);
    }
}
draw_sprite_ext(dspr, dimg, dx, dy, (fighting && dspr != sprite_index) ? abs(image_xscale) : image_xscale, image_yscale, 0, c_white, fade);
// In a fight: a slow white pulse, so it reads as "busy" rather than a figure standing around.
if (fighting)
{
    gpu_set_fog(true, c_white, 0, 1);
    draw_sprite_ext(dspr, dimg, dx, dy, (dspr != sprite_index) ? abs(image_xscale) : image_xscale, image_yscale, 0, c_white, fade * (0.25 + (0.2 * sin(current_time / 250))));
    gpu_set_fog(false, c_white, 0, 1);
}
// Name tag above the sprite's centre (sprite origins differ: walking sprites have it at the top
// left, the Chapter 5 platformer's sprites don't).
var tcx = x + (((sprite_get_width(sprite_index) / 2) - sprite_get_xoffset(sprite_index)) * image_xscale);
var tty = y - (sprite_get_yoffset(sprite_index) * image_yscale);
if (fade >= 1)
{
    mp_draw_nametag(pid, tcx, tty - 4);
    mp_draw_talk_bubble(pid, tcx, tty - 16);
}
if (fighting && global.mp_join_target == pid)
    mp_draw_join_prompt(tcx, tty - 22);
