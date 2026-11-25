// @chapters 5
// DELTARUNE Multiplayer - Chapter 5's new glowing tile puzzles (obj_glowtile_puzzle_new, the garden's
// hard pressure plates room).
//
// The puzzle already checks its completion flag (1431/1432) every frame, so a friend's solve (shared
// flag) ends my copy too. But if my own run was going at that moment, the game jumped straight to
// "done" without its end step: the spikes it had raised (with their solid blocks) stayed up and
// could shut me in, and the camera stayed held. Now, when that happens, my copy runs its own end
// step and gives control back (its alarm), and for flag 1431 the room's held camera goes as it does
// when you come back later. Simplest choice: the result is shared, not the tiles.

// Prepended to obj_glowtile_puzzle_new's Step.
function mp_glownew_before()
{
    mp_glow_state = state;
}

// Appended to its Step.
function mp_glownew_after()
{
    if (!variable_global_exists("mp_inited") || !mp_on() || !variable_instance_exists(id, "mp_glow_state"))
        return;
    if (mp_glow_state < 2 && state == 2 && puzzle_phase < puzzle_win_phase)
    {
        mp_log("glowing tiles: solved by a friend (flag " + string(flag_on_completion) + "), my copy ends (was state " + string(mp_glow_state) + ")");
        if (mp_glow_state == 1)
            end_function();
        if (mp_glow_state > 0)
            alarm[0] = 30;
        if (flag_on_completion == 1431)
        {
            with (obj_camera_clamper)
            {
                if (image_blend == c_red)
                    instance_destroy();
            }
        }
    }
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPGLOWNEW] flag=" + string(flag_on_completion) + " state=" + string(state) + " phase=" + string(puzzle_phase) + "/" + string(puzzle_win_phase) + " solids=" + string(instance_number(obj_solidblocksized_alt)) + " ia=" + string(global.interact));
}
