if (variable_global_exists("mp_inited"))
{
    var kind = variable_instance_exists(id, "mp_back") ? -1 : (variable_instance_exists(id, "mp_mid") ? mp_mid : 99);
    mp_mirror_draw(kind);
    if (kind == 99)
        mp_overheard_draw();
}
