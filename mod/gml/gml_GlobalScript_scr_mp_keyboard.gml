// @chapters 2
// DELTARUNE Multiplayer - Chapter 2's keyboard puzzles (room_dw_cyber_keyboard_puzzle_1..3).
//
// Typing the right word on the floor keyboard sets a story flag (390, 333, 420; shared) and the
// room reacts: puzzle 1's force field goes, puzzle 2 and 3 play their scene (the rooms' own
// controllers already watch the flags every frame). But the keyboard's screen only reads the flag
// when the room is built, and puzzle 1's force field only goes while that screen shows the win. So a
// friend's solve left my force field up. Now the screen follows the flag, the way it starts when
// you come back later: the right word shown, the win picture, force field gone.
// Simplest choice: the solve is shared, not each key.

// Prepended to obj_ch2_keyboardpuzzle_controller's Step.
function mp_kbpuzzle_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    var f = -1;
    if (room == room_dw_cyber_keyboard_puzzle_1)
        f = 390;
    else if (room == room_dw_cyber_keyboard_puzzle_2)
        f = 333;
    else if (room == room_dw_cyber_keyboard_puzzle_3)
        f = 420;
    if (f >= 0 && global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPKEYB] room=" + room_get_name(room) + " flag" + string(f) + "=" + string(global.flag[f]) + " won=" + string(won) + " forcefield=" + string(instance_number(obj_forcefield)));
    if (f < 0 || won || con != 0 || global.flag[f] != 1)
        return;
    mp_log("keyboard puzzle: solved by a friend (flag " + string(f) + "), my screen follows");
    if (f == 420)
        victorySprite = spr_keyboard_puzzle_bluecheck;
    won = true;
    currentString = idealString;
    imageTimer = sprite_get_number(victorySprite) - 0.5;
}

// ---------------------------------------------------------------- the mice switch room

// room_dw_city_mice2: a mouse (or Noelle) landing on the switch turns the force field off and ends the
// room's puzzle: story flags 368 (solved) and 915, shared. The room reads them only when it is built,
// so a friend's solve left my force field up and my room still waiting. Now, when flag 368 arrives
// from someone else (it changed between two of my controller's steps: my own solve sets it inside
// the step), my room does what it does when you come back later: the switch frozen down, the force
// field gone, the room's controller gone. Simplest choice: the result is shared, not the mice.

// Prepended to obj_controller_city_mice2's Step.
function mp_mice2_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (!variable_instance_exists(id, "mp_f368"))
        mp_f368 = global.flag[368];
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPMICE] flag368=" + string(global.flag[368]) + " flag915=" + string(global.flag[915]) + " victory=" + string(victory) + " forcefield=" + string(instance_number(obj_forcefield)));
    if (mp_f368 == 1 || global.flag[368] != 1)
        return;
    mp_log("mice switch room: solved by a friend, my room follows");
    if (global.flag[915] != 0)
    {
        with (obj_mice2Switch)
        {
            toggle = 1;
            depth = 600000;
            scr_createFrozen(0);
        }
        with (obj_rotationController_track)
            scr_createFrozen(1);
    }
    with (obj_forcefield)
        instance_destroy();
    if (!instance_exists(obj_cutscene_master) && !d_ex() && global.flag[7] == 1)
    {
        global.flag[7] = 0;
        global.interact = 0;
    }
    instance_destroy();
}

// Appended to its Step: the flag as my own step left it.
function mp_mice2_after()
{
    if (variable_global_exists("mp_inited") && instance_exists(id))
        mp_f368 = global.flag[368];
}
