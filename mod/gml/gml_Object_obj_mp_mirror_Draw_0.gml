if (variable_global_exists("mp_inited"))
{
    var bk = variable_instance_exists(id, "mp_back");
    mp_mirror_draw(bk);
    if (!bk)
        mp_overheard_draw();
}
