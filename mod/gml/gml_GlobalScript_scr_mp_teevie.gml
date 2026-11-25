// @chapters 3
// DELTARUNE Multiplayer - Chapter 3's TV quizzes (obj_dw_ch3_teevie_quiz_controller: the big TV
// rooms and the maze). Walking up to the TV starts a quiz scene (answered on the A/B floor tiles);
// a right answer sets the quiz's story flag (shared) and lowers the spikes. The quiz reads its flag
// only when the room is built, so after a friend's quiz (watched by the others as a scene) my TV
// still waited: walking up to it started the same quiz again, and my spikes stayed up. Now, when the
// flag arrives while my quiz still waits, my TV is done as it is when you come back later.
// Simplest choice: the result is shared, not each answer (the quiz itself plays as a shared scene).

// Prepended to the quiz controller's Step.
function mp_tvquiz_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPTVQUIZ] flag" + string(quiz_flag) + "=" + string(quiz_flag >= 0 ? global.flag[quiz_flag] : -1) + " con=" + string(con));
    if (con != 0 || quiz_flag < 0 || global.flag[quiz_flag] != 1)
        return;
    mp_log("TV quiz " + string(quiz_flag) + ": answered by a friend, my TV is done too");
    con = -1;
    hide_spikes = true;
}

// Chapter 3 rooms whose solve flag is read only when the room is built, so a friend's solve left
// mine shut. Both now take the game's own solve step when the flag is set (the same step my own solve
// takes, so nothing is done twice):
// - backstage extra puzzle (room_dw_b3bs_extrapuzzle): the floor switch opens the door (flag 1112);
// - Susie's bridge (room_dw_teevie_susiebridge): the board switch lowers the spikes (flag 1212 = 2).

// Prepended to obj_dw_b3bs_extrapuzzle's Step.
function mp_b3bs_extra_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPB3BS] flag1112=" + string(global.flag[1112]) + " doorcon=" + string(doorcon) + " door=" + string(instance_exists(doorblock)));
    if (doorcon == 0 && global.flag[1112] == 1)
    {
        mp_log("backstage extra puzzle: a friend opened the door, my door opens");
        doorcon = 1;
    }
}

// Prepended to obj_dw_teevie_susiebridge's Step.
function mp_susiebridge_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPBRIDGE] flag1212=" + string(global.flag[1212]) + " con=" + string(con) + " spikes=" + string(instance_exists(spikes) ? object_get_name(spikes.object_index) : "none"));
    if (con == 1 && global.flag[1212] == 2 && instance_exists(boardswitch) && !boardswitch.pressed)
    {
        mp_log("Susie's bridge: a friend pressed the switch, my spikes go down");
        boardswitch.pressed = true;
    }
}
