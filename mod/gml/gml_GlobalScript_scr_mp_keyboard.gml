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

// Chapter 2's first room after the baseball game (room_dw_city_postbaseball_1): Kris's floor switch
// (switch2con, flag 448) opens the right force field, the teacup ride (flag 449) the top-left one.
// Both flags are read only when the room is built, so a friend's solve left my force fields up. Now,
// when a flag arrives from someone else (it changed between two of my controller's steps), my room
// goes the game's own way: the switch tile is held down (it then plays the sound, drops the field and
// starts the "Noelle comes back" step), and the teacup step jumps to "field gone". Not before
// Noelle's scene at the room's start is over (con 3), so it is not skipped. Simplest choice: the
// result is shared, not who stands where.

// Prepended to obj_room_dw_city_postbaseball's Step.
function mp_postbb_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on() || room != room_dw_city_postbaseball_1)
        return;
    if (!variable_instance_exists(id, "mp_f448"))
    {
        mp_f448 = global.flag[448];
        mp_f449 = global.flag[449];
    }
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPPOSTBB] flag448=" + string(global.flag[448]) + " flag449=" + string(global.flag[449]) + " con=" + string(con) + " switch2con=" + string(switch2con) + " rodeteacup=" + string(rodeteacup) + " forcefield=" + string(instance_number(obj_forcefield)));
    if (con < 3)
        return;
    // (Noelle's scene at the room's start always turns off the top-right force field; a player who
    // watched a friend's copy of the scene didn't run it, so it is done here.)
    if (!variable_instance_exists(id, "mp_tr_done"))
    {
        mp_tr_done = 1;
        if (instance_exists(forcefieldtopright) && switchcon == 0)
        {
            mp_log("post-baseball room: the top-right force field goes, as after Noelle's scene");
            switchcon = 1;
        }
    }
    if (mp_f448 != 1 && global.flag[448] == 1 && switch2con < 1)
    {
        mp_log("post-baseball room: a friend pressed the switch, my room follows");
        mp_f448 = 1;
        with (obj_pushtile_room)
        {
            if (pushVariableName == "switch2con")
                pushedoverride = 1;
        }
    }
    if (mp_f449 != 1 && global.flag[449] == 1 && rodeteacup < -2)
    {
        mp_log("post-baseball room: a friend rode the teacup, my room follows");
        mp_f449 = 1;
        rodeteacup = 1;
    }
}

// Appended to its Step: the flags as my own step left them.
function mp_postbb_after()
{
    if (variable_global_exists("mp_inited") && instance_exists(id) && room == room_dw_city_postbaseball_1)
    {
        mp_f448 = global.flag[448];
        mp_f449 = global.flag[449];
    }
}

// Chapter 2's second virus maze (room_dw_cyber_viromaze2): beating its virus sets flag 352, which
// turns the room's force fields off (and the one that closes behind you once you're in). The flag
// is read only when the room is built, so a friend's win left my fields up and could shut me in.
// Now, when flag 352 arrives from someone else (it changed between two of my controller's steps),
// my controller runs its own solve step ("Sounded like a forcefield deactivating", fields gone),
// once I'm free to read it. Simplest choice: the result is shared, not the fight.

// Prepended to obj_controller_dw_cyber_viromaze2's Step.
function mp_viromaze2_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    if (!variable_instance_exists(id, "mp_f352"))
        mp_f352 = global.flag[352];
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPVIRO2] flag352=" + string(global.flag[352]) + " con=" + string(con) + " forcefield=" + string(instance_number(obj_forcefield)) + " ia=" + string(global.interact));
    if (mp_f352 == 1 || global.flag[352] != 1 || con != 0 || global.interact != 0 || d_ex())
        return;
    mp_log("virus maze 2: won by a friend, my force fields go");
    mp_f352 = 1;
    con = 1;
}

// Appended to its Step: the flag as my own step left it.
function mp_viromaze2_after()
{
    if (variable_global_exists("mp_inited") && instance_exists(id))
        mp_f352 = global.flag[352];
}

// Chapter 2's mansion saucer puzzles (room_dw_mansion_east_2f_a: the locked door, flag 344;
// room_dw_mansion_2f shortcut: the bookcase, flag 346): when the saucers are filled a key flies to
// the door or bookcase, which explodes. The room's whole step runs only while the flag is 0, and the
// flag is read when the room is built, so a friend's solve froze my copy with the door locked (a
// solid block) or the bookcase in the way. Now, when the flag arrives from someone else, my room does
// what the game's own last step does (explosion, door open or bookcase gone, saucers, Monty and the
// force field gone), written safely: the game's step expects the key's sparkles to exist.

// Prepended to obj_ch2_room_mansion_east_2f_a's and obj_ch2_room_mansion_2f_shortcut's Step.
function mp_mansion_key_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return;
    var east = object_index == obj_ch2_room_mansion_east_2f_a;
    var fl = east ? 344 : 346;
    if (!variable_instance_exists(id, "mp_fkey"))
        mp_fkey = global.flag[fl];
    if (global.mp_test != "" && mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
        show_debug_message("[MPMANSION] flag" + string(fl) + "=" + string(global.flag[fl]) + " con=" + string(con) + " solid=" + string(instance_number(obj_solidblock)) + " forcefield=" + string(instance_number(obj_forcefield)) + " ia=" + string(global.interact));
    if (mp_fkey == 1 || global.flag[fl] != 1)
        return;
    mp_fkey = 1;
    mp_log("mansion saucer puzzle: solved by a friend (flag " + string(fl) + "), my " + (east ? "door opens" : "bookcase goes"));
    var target = east ? doorlocked : bookcase;
    if (instance_exists(target))
    {
        explosion = instance_create(target.x + 50, target.y + 30, obj_animation);
        explosion.sprite_index = spr_realisticexplosion;
        explosion.image_xscale = 2;
        explosion.image_yscale = 2;
        snd_play(snd_badexplosion);
        with (target)
            instance_destroy();
    }
    if (east)
    {
        if (instance_exists(exitcollider))
        {
            with (exitcollider)
                instance_destroy();
        }
        dooropen = scr_dark_marker(180, 40, spr_dw_mansion_door_open);
        dooropen.depth = 899999;
    }
    if (key != -1 && key != 0 && instance_exists(key))   // (key is 0 or -1 before it is made)
    {
        with (key)
            instance_destroy();
    }
    if (variable_instance_exists(id, "sparkle") && is_array(sparkle))
    {
        for (var i = 0; i < array_length(sparkle); i++)
        {
            with (sparkle[i])
                instance_destroy();
        }
    }
    with (obj_saucer_monty)
        instance_destroy();
    with (obj_saucer)
    {
        if (x < 520)
        {
            if (variable_instance_exists(id, "collider") && instance_exists(collider))
            {
                with (collider)
                    instance_destroy();
            }
            instance_destroy();
        }
    }
    var ff = east ? forcefield : (variable_instance_exists(id, "forcefield_right") ? forcefield_right : -4);
    if (ff != -4 && instance_exists(ff))
    {
        with (ff)
            instance_destroy();
    }
    if (con >= 1 && !d_ex() && !instance_exists(obj_cutscene_master))
        global.interact = 0;
    instance_destroy();
}

// Appended to their Step: the flag as my own step left it.
function mp_mansion_key_after()
{
    if (variable_global_exists("mp_inited") && instance_exists(id))
        mp_fkey = global.flag[object_index == obj_ch2_room_mansion_east_2f_a ? 344 : 346];
}

// Chapter 2's mansion secret walls (room_dw_mansion_east_1f_e, flag 339; room_dw_mansion_east_1f_secret,
// flag 340): finding the secret hides the wall tiles and removes a solid block at the exit. The flag
// is read only when the room is built, so a friend's find left my wall and block. Now, while the
// flag is set and my block is still there, my room takes its own "found" step (con 1). (It is the
// same step my own find takes, so nothing is done twice.)

// Prepended to obj_ch2_room_mansion_east_1f_e's and obj_ch2_room_mansion_east_1f_secret's Step.
function mp_mansion_secret_follow()
{
    if (!variable_global_exists("mp_inited") || !mp_on() || con == 1)
        return;
    var fl = object_index == obj_ch2_room_mansion_east_1f_e ? 339 : 340;
    if (global.flag[fl] != 1 || !variable_instance_exists(id, "exitcollider") || exitcollider == 0 || exitcollider == -4 || !instance_exists(exitcollider))
        return;
    mp_log("mansion secret wall: found by a friend (flag " + string(fl) + "), my wall opens");
    con = 1;
}
