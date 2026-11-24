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
