// @chapters 5
// DELTARUNE Multiplayer - Chapter 5 castle puzzles solved by one player, solved for everyone.
//
// The rooms keep "solved" as a bit of a story flag (shared with everyone), and read it only when the
// room is built. So a friend's solve reached my flags but not my room. These follow it: when the
// bit arrives while my room still waits, the room opens the way it does after a solve (or after
// coming back later). Simplest choice: the result is shared, not each step of the puzzle.
//  * room_dw_fcastle_terracotta_puzzle: statues on the floor switches open the shortcut (flag 1744
//    bit 10).
//  * room_dw_fcastle_right_puzzle: the orange key opens the orange door (flag 1317 bit 0).
// (room_dw_fcastle_sidepuzzle has nothing to solve together: a platforming room and a sign.)

// Prepended to obj_dw_fcastle_terracotta_puzzle's Step.
function mp_castle_terracotta_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    mp_castle_test(1744, 10);
    if (!init || con != 0 || !scr_flag_get_ext(_ROOM_STATE_FLAG, _PUZZLE_SOLVED_BIT))
        return;
    mp_log("terracotta puzzle: solved by a friend, my room opens");
    // (The room's own step does the opening on the next line of its code: con 1 at timer 30.)
    con = 1;
    timer = 29;
}

// Prepended to obj_dw_fcastle_right_puzzle's Step.
function mp_castle_right_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    mp_castle_test(1317, 0);
    if (!init || keycon != 0 || !scr_flag_get_ext(_ROOM_FLAG, _BIT_DOOR, 1))
        return;
    mp_log("orange door: opened by a friend, my room opens it too");
    keycon = 3;
    with (obj_plat_hanging_key)
        broken = true;
    with (doormarker)
        sprite_index = spr_fcastle_left_twodoors_orangedoor_open;
    with (obj_solidblocksized_alt)
        instance_destroy();
    with (doorinteract)
        instance_destroy();
    snd_play(snd_locker);
}

// Test token castlesolve:<frame>: at that room frame, set the room's "solved" bit, as a friend's
// solve does (in this game the room then follows it too). logpuz logs the room's state.
function mp_castle_test(fl, bit)
{
    if (global.mp_test == "" || !variable_global_exists("mp_test_timer"))
        return;
    if (mp_test_has("castlesolve") && global.mp_test_timer == real(mp_test_arg("castlesolve")))
    {
        mp_log("[test] castlesolve flag " + string(fl) + " bit " + string(bit));
        scr_flag_set_ext(fl, bit, 1);
    }
    if (mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPCASTLE] room=" + room_get_name(room) + " flag" + string(fl) + "=" + string(global.flag[fl]) + " solids=" + string(instance_number(obj_solidblocksized_alt)));
}
