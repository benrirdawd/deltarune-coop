mp_init();
if (!instance_exists(obj_mp_mirror))
{
    instance_create_depth(0, 0, -9000, obj_mp_mirror);
    // (The second one draws the mirrored sprites that are behind the room's tiles.)
    var mpbk = instance_create_depth(0, 0, 1000000000, obj_mp_mirror);
    mpbk.mp_back = true;
}
