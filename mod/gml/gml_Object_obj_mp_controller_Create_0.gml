mp_init();
if (!instance_exists(obj_mp_mirror))
{
    instance_create_depth(0, 0, -9000, obj_mp_mirror);
    // (The second one draws the mirrored sprites that are behind the room's tiles.)
    var mpbk = instance_create_depth(0, 0, 1000000000, obj_mp_mirror);
    mpbk.mp_back = true;
    // (And three for the sprites between kept scenery in front of the tiles: scr_mp_mirror.)
    for (var mi = 0; mi < 3; mi++)
    {
        var mpmid = instance_create_depth(0, 0, 1000000000, obj_mp_mirror);
        mpmid.mp_mid = mi;
    }
}
