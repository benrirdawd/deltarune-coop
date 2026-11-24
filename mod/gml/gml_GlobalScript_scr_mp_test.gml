// DELTARUNE Multiplayer - automated test helpers (enabled with -mptest "<tokens>").
// Tokens (comma separated):
//   party           give the save a full dark-world party (Kris/Susie/Ralsei) and go to `room`
//   room:<name>     room to start in (with `party`)
//   plot:<n>        story progress to use (with `party`)
//   battle:<enc>    start encounter <enc> ~4s after arriving (once)
//   bot             press buttons automatically (menus, attacks, dodging)
//   log             log battle state every turn
//   check           log a self-check line twice a second (character drawn, followers drawn,
//                   other players' positions, shared state hash, sync state) for tools/mpcheck.py
//   mash            press Z through title screens, menus and cutscenes (real game start; not in battles: add bot)
//   wander          walk around randomly in free roam
//   partyat:<n>     do `party` after n frames (default 60)
//   walk:<d>:<t>:<n>  hold direction d (l/r/u/d) for n frames, t frames after arriving
//   bumpflag:<n>:<c> count story flag n up c times, fast, once someone else is in the room (counters add up)
//   songext:<v>:<p> with song: play it at volume v and pitch p (mus_loop_ext, as some Chapter 1 scenes do)
//   touch:<obj>@<f> f frames into the room, stand below the newest <obj> facing it and press Z (NPC, save point)
//   away:<room>:<n>[:<x>:<y>] once connected, n frames after the party setup, go to <room> (like walking through a door)
//                   (also from the opening's PLACE_* rooms: the host leaving its vessel creation)
//   fakescene       (test of the pulled-battle cleanup) start a cutscene of our own while being pulled into a battle
//   lightworld      with `party`: start in the Light World (Kris and Susie)
//   setplot:<n>     set the story progress to <n> after a while (shared with the others)
//   gotohost:<n>    press the "go to the other player" action n frames after the party setup
//   nododge         bot: don't dodge in the bullet phase (heroes go down)
//   battleat:<n>    with battle: start the encounter n frames after arriving (default 120)
//   charto:<c>@<f> change my character to c (1-4) at session frame f, as F9 "Play as" does
//   song:<file>     play this song after the party setup (music sync tests)
//   mashevery:<n>   mash presses Z every n frames (default 10); mashfrom:<n> only after n frames in the room
//   stuck:<n>       fake a stuck sync state n frames after the party setup (F8 must free it)
//   weak            enemies have 1 HP (battle ends quickly)
//   sturdy          heroes have 10 times their HP in fights (long fights)
//   dbgchar         log every party change made by the shared state, with the call stack
//   save            save the game to slot 0 once in free roam (for later load tests)
//   load:<slot>     load save slot <slot> from the title screen
//   solo            with `party`: Kris alone
//   duo             with `party`: Kris and Susie (with `battle`: the battle party)
//   watchplot       log plot, party and the room's story events every 5 s
//   staleplot:<a>:<b>  when the plot reaches a (outside battles), set it back to b once
//   noenemysync     (test of the touched-enemy sync) don't share touched overworld enemies
//   nomono          (test of the stale-plot guard) accept a lower plot from the others
//   battlesolo      with battle: the host starts it before anyone joined (joining mid-fight)
//   story           with battle: the encounter is treated as a story battle (calls everyone)
//   bringat:<frame> host: bring everyone over at this frame
//   battleclk:<ms>  with battle: wait for this moment of the shared clock (host's ms since start)
//   speed:<n>       run the game n times faster (30*n frames a second) to make tests quicker;
//                   the cutscene catch-up (mp_dlg_speed) still doubles on top of it
//   fastboot        with speed: the title / file select before `party` runs fast as well
//   connectat:<frame> client: connect only from this frame of its game on (joining late, mid-cutscene)
//   pushblock:<d>:<f>[/<f>...] push the room's first pushable block in direction d at room frame(s) f (Chapters 1, 5)
//   restartroom:<f> build the room again at room frame f (once)
//   useobj:<o>:<f>  use (as with Z) the room's first <o> at room frame f
//   watch:<f>       watch the first other player (F9 Watch) from room frame f
//   useseq:<o>:<i>@<f>/<i>@<f>...  use the room's <i>-th <o> at room frame <f>, for each pair
//   logpuz          log the tile puzzle's / suits puzzle's state every 5 s ([MPPUZ] lines)
//   logblocks       log the room's pushable blocks every 5 s ([MPBLOCKS] lines)
//   chat:<i>@<f>    send quick message i (F9 "Say") at frame f
//   pingat:<f>      press F5 (map ping) at frame f
//   watchnext:<f>   while watching, switch to the next player at room frame f
//   <name>/<token>  only for the player with that name (-mpname), e.g. P3/away:room_x:100
//   logreading      log who the player list shows as "(reading)" every 30 frames
//   reportzip       at frame 400, do F9 "Save logs for a bug report" into the save folder (not the desktop)
//   menupage:<n>    with openmenu: pick C-menu entry n (0 items, 1 equipment, 3 power/status)
//   players:<n>     with speed: speed up once n players (me included) are connected (default 2)

function mp_test_has(tok)
{
    var t = "," + global.mp_test + ",";
    return string_pos("," + tok + ",", t) > 0 || string_pos("," + tok + ":", t) > 0;
}

function mp_test_arg(tok)
{
    var t = "," + global.mp_test + ",";
    var p = string_pos("," + tok + ":", t);
    if (p == 0)
        return "";
    var rest = string_delete(t, 1, p + string_length(tok) + 1);
    return string_copy(rest, 1, string_pos(",", rest) - 1);
}

function mp_test_tick()
{
    if (!variable_global_exists("mp_test_state"))
    {
        global.mp_test_state = 0;
        global.mp_test_timer = 0;
        global.mp_test_battled = 0;
        global.mp_test_lastturn = -1;
    }
    global.mp_test_timer += 1;
    // speed:<n>: n times the normal 30 frames a second (kept up in case the game sets it back).
    // Only from the moment another player is connected: the games start a few real seconds
    // apart, and sped up before that the host would play through the scenario alone.
    // players:<n>: wait for n players in all (default 2), so nobody who starts a little later misses
    // the beginning.
    if (mp_test_arg("speed") != "" && !variable_global_exists("mp_test_fast") && mp_on())
    {
        var want = mp_test_arg("players") != "" ? real(mp_test_arg("players")) : 2;
        var have = 1;
        for (var si = 0; si < 8; si++)
        {
            if (si != global.mp_myid && global.mp_pconn[si])
                have += 1;
        }
        if (have >= want)
        {
            global.mp_test_fast = 1;
            // The scenario's own countdowns (battle:, walk: ...) start again from here when the party
            // is already set up: everyone in before it goes on, as it would be at normal speed.
            // (Otherwise a battle due while waiting started the very frame the others joined, before
            // their positions arrived, and left the last one out.)
            if (global.mp_test_state >= 1)
                global.mp_test_timer = 0;
        }
    }
    // fastboot (with speed): the opening (title, file select) runs fast too, until the party setup;
    // then normal speed until someone is connected. (Not with partyat: waiting at the title is
    // part of those scenarios.)
    var boot = mp_test_has("fastboot") && mp_test_arg("speed") != "" && global.mp_test_state == 0;
    if ((variable_global_exists("mp_test_fast") || boot) && !(variable_global_exists("mp_dlg_fast") && global.mp_dlg_fast))
    {
        var tfps = 30 * real(mp_test_arg("speed"));
        if (game_get_speed(gamespeed_fps) != tfps)
        {
            game_set_speed(tfps, gamespeed_fps);
            show_debug_message("[MP] test speed: " + string(tfps) + " frames a second");
        }
    }
    else if (mp_test_has("fastboot") && !variable_global_exists("mp_test_fast") && !(variable_global_exists("mp_dlg_fast") && global.mp_dlg_fast) && game_get_speed(gamespeed_fps) != 30)
    {
        game_set_speed(30, gamespeed_fps);
        show_debug_message("[MP] test speed: 30 frames a second (set up, waiting for the others)");
    }
    // immortal: my heroes stay at full HP (the others can go down without a Game Over).
    // revive:<n>: n frames into spectating, my heroes get half their HP back.
    if (variable_global_exists("mp_b_active") && mp_battle_on())
    {
        if (!variable_global_exists("mp_test_spec_t"))
            global.mp_test_spec_t = 0;
        global.mp_test_spec_t = global.mp_spec_on ? (global.mp_test_spec_t + 1) : 0;
        var heal_to = mp_test_has("immortal") ? 1 : (mp_test_has("revive") && global.mp_test_spec_t == real(mp_test_arg("revive")) ? 0.5 : 0);
        if (heal_to > 0)
        {
            for (var hs = 0; hs < 3; hs++)
            {
                if (global.char[hs] != 0 && global.mp_owner[hs] == global.mp_myid)
                    global.hp[global.char[hs]] = ceil(global.maxhp[global.char[hs]] * heal_to);
            }
            if (heal_to < 1)
                mp_log("[test] revived");
        }
    }
    // Wall clock for comparing games on one PC: waits once for the (whole-second) wall clock to
    // tick over, which ties this game's clock to it to about a millisecond.
    if (!variable_global_exists("mp_test_ws"))
    {
        global.mp_test_ws = floor((date_current_datetime() - 45000) * 86400 + 0.5);
        global.mp_test_wb = current_time;
    }
    if (!variable_global_exists("mp_test_wcal") && global.mp_frame > 60)
    {
        global.mp_test_wcal = 1;
        var wsec = floor((date_current_datetime() - 45000) * 86400 + 0.5);
        var wnow = wsec;
        while (wnow == wsec)
            wnow = floor((date_current_datetime() - 45000) * 86400 + 0.5);
        global.mp_test_ws = wnow;
        global.mp_test_wb = current_time;
    }
    // walkup:<frame>: stand next to the first other player, wherever they are in the room.
    if (mp_test_arg("walkup") != "" && !variable_global_exists("mp_test_walked") && global.mp_frame >= real(mp_test_arg("walkup")) && instance_exists(obj_mainchara))
    {
        global.mp_test_walked = 1;
        for (var wi = 0; wi < 8; wi++)
        {
            if (wi != global.mp_myid && global.mp_pconn[wi] && global.mp_proom[wi] == room)
            {
                obj_mainchara.x = global.mp_px[wi] + 30;
                obj_mainchara.y = global.mp_py[wi];
                mp_log("[test] walked up to player " + string(wi));
                break;
            }
        }
    }
    // touch:<object>@<frame>: stand just below the newest instance of <object>, facing it, and press Z
    // (talking to an NPC, a save point...). The Z goes out on the next few frames (mp_test_input).
    var tv = mp_test_arg("touch");
    if (tv != "" && !variable_global_exists("mp_test_touched") && instance_exists(obj_mainchara))
    {
        var ta = string_pos("@", tv);
        var tf = ta > 0 ? real(string_delete(tv, 1, ta)) : 300;
        var tobj = asset_get_index(ta > 0 ? string_copy(tv, 1, ta - 1) : tv);
        if (global.mp_room_frames >= tf && global.interact == 0)
        {
            global.mp_test_touched = 1;
            if (tobj >= 0 && instance_exists(tobj))
            {
                var tinst = instance_find(tobj, instance_number(tobj) - 1); // (the newest one)
                // (Collision boxes lined up: my box's top just under the object's box, centred on it.)
                obj_mainchara.x += round(((tinst.bbox_left + tinst.bbox_right) - (obj_mainchara.bbox_left + obj_mainchara.bbox_right)) / 2);
                obj_mainchara.y += (tinst.bbox_bottom + 2) - obj_mainchara.bbox_top;
                obj_mainchara.facing = 2;
                global.facing = 2;
                global.mp_test_touchz = global.mp_frame + 3;
                mp_log("[test] touch " + tv + " (box " + string(tinst.bbox_left) + "," + string(tinst.bbox_top) + "-" + string(tinst.bbox_right) + "," + string(tinst.bbox_bottom) + ") at " + string(obj_mainchara.x) + "," + string(obj_mainchara.y));
            }
            else
                mp_log("[test] touch: no " + tv + " here");
        }
    }
    // bumpflag:<n>:<count>: count story flag n up, count times, every 2 frames (in the same moments of the shared clock) from 300 frames into the
    // room once someone else is here (two games doing it at once: the counts must add up); logs the end.
    var bfv = mp_test_arg("bumpflag");
    if (bfv != "" && global.mp_room_frames >= 300 && mp_player_count() > 1)
    {
        var bc = string_pos(":", bfv);
        var bn = real(string_copy(bfv, 1, bc - 1));
        var bcount = real(string_delete(bfv, 1, bc));
        if (!variable_global_exists("mp_test_bumped"))
            global.mp_test_bumped = 0;
        // (Only in the first second of each 5 s of the shared clock: both games count at the same time.)
        if (global.mp_test_bumped < bcount && (global.mp_frame mod 2) == 0 && (floor(mp_clock_now()) mod 5000) < 1000)
        {
            global.flag[bn] += 1;
            global.mp_test_bumped += 1;
            // (And an ordinary flag scanned in the same slice, before it: flag 1600 + my number = how far I am.)
            global.flag[1600 + global.mp_myid] = global.mp_test_bumped;
        }
        if ((global.mp_frame mod 60) == 0)
            mp_log("[test] bumpflag " + string(bn) + " = " + string(global.flag[bn]) + " (bumped " + string(global.mp_test_bumped) + ") flags 1600-1601 = " + string(global.flag[1600]) + "," + string(global.flag[1601]));
    }
    // pingat:<frame>: the map ping (F5).
    if (mp_test_arg("pingat") != "" && mp_on() && global.mp_frame == real(mp_test_arg("pingat")))
        mp_ping_send();
    // chat:<i>@<frame>: a quick message.
    var chv = mp_test_arg("chat");
    if (chv != "" && mp_on() && string_pos("@", chv) > 0 && global.mp_frame == real(string_copy(chv, string_pos("@", chv) + 1, 10)))
        mp_chat_send(real(string_copy(chv, 1, string_pos("@", chv) - 1)));
    // reportzip: the bug report zip, into the save folder.
    if (mp_test_has("reportzip") && global.mp_frame == 400)
        mp_report_zip(game_save_id);
    // bringat:<frame>: (host) bring everyone over.
    if (mp_test_arg("bringat") != "" && global.mp_frame == real(mp_test_arg("bringat")))
        mp_bring_everyone();
    // uishot:<page>: show a page of the menu for a screenshot.
    if (mp_test_arg("uishot") != "" && global.mp_frame == 300)
    {
        global.mp_ui_open = 1;
        global.mp_ui_page = real(mp_test_arg("uishot"));
    }
    if (mp_test_has("open"))
        global.mp_open = 1;
    if (mp_test_has("everyone"))
        global.mp_open = 0;
    var partyat = 60;
    if (mp_test_arg("partyat") != "")
        partyat = real(mp_test_arg("partyat"));
    if (global.mp_test_state == 0 && mp_test_has("party") && global.mp_test_timer > partyat)
    {
        global.mp_test_state = 1;
        global.char[0] = 1;
        global.char[1] = 2;
        global.char[2] = 3;
        global.darkzone = 1;
        var pl = mp_test_arg("plot");
        // (A client that already joined keeps the story progress it got from the host.)
        if (pl != "" && !(mp_on() && global.mp_role == 2))
            global.plot = real(pl);
        mp_ch_test_party();
        // duo: Kris and Susie
        if (mp_test_has("duo"))
            global.char[2] = 0;
        // solo: Kris alone (the very start of the Dark World)
        if (mp_test_has("solo"))
        {
            global.char[1] = 0;
            global.char[2] = 0;
        }
        // lightworld: start as in the Light World (Kris and Susie only)
        if (mp_test_has("lightworld"))
        {
            global.darkzone = 0;
            global.char[2] = 0;
        }
        var rn = mp_test_arg("room");
        if (rn == "")
            rn = "room_field1";
        global.interact = 0;
        // A host sets its world up like loading a save: everyone gets the whole state now. (Sent as
        // ordinary changes it waits for the end of the room's cutscene, and a client that joined at
        // the file select would follow the host into the room with the file select's blank state.)
        if (global.mp_role == 1)
            global.mp_loaded = 1;
        room_goto(asset_get_index(rn));
        global.mp_test_timer = 0;
        mp_notify("[test] party ready, going to " + rn);
    }
    if (mp_test_has("pos") && !variable_global_exists("mp_test_posdone") && instance_exists(obj_mainchara) && global.mp_test_timer > 90)
    {
        global.mp_test_posdone = 1;
        var pv = mp_test_arg("pos");
        var c = string_pos(":", pv);
        with (obj_mainchara)
        {
            x = real(string_copy(pv, 1, c - 1));
            y = real(string_delete(pv, 1, c));
        }
        with (obj_caterpillarchara)
        {
            x = obj_mainchara.x;
            y = obj_mainchara.y;
            scr_caterpillar_interpolate();
        }
    }
    // steamhost: host on Steam 2 s after entering the room (scr_mp_steam)
    if (mp_test_has("steamhost") && global.mp_test_state == 1 && global.mp_test_timer == 60)
        mp_steam_host();
    // steamjoin:<code>: join a Steam game by its code 5 s after entering the room
    if (mp_test_has("steamjoin") && global.mp_test_state == 1 && global.mp_test_timer == 150)
        mp_steam_join_code(mp_test_arg("steamjoin"));
    // holdkeys:<letters>: hold each letter in turn for 2 s (simulated inside the game, so no window
    // focus is needed), from 3 s after entering the room; logs where the player is at each switch.
    if (mp_test_has("holdkeys") && global.mp_test_state == 1 && global.mp_test_timer >= 90)
    {
        var hk = mp_test_arg("holdkeys");
        var hn = floor((global.mp_test_timer - 90) / 60);
        if (hn <= string_length(hk))
        {
            if (((global.mp_test_timer - 90) mod 60) == 0)
            {
                if (hn > 0)
                    keyboard_key_release(ord(string_char_at(hk, hn)));
                mp_log("[test] holdkeys " + (hn < string_length(hk) ? string_char_at(hk, hn + 1) : "done") + " at " + (instance_exists(obj_mainchara) ? string(obj_mainchara.x) + "," + string(obj_mainchara.y) : "-"));
            }
            if (hn < string_length(hk))
                keyboard_key_press(ord(string_char_at(hk, hn + 1)));
        }
    }
    // A room entered straight at a story point puts you at its default start, which can be inside
    // something solid (Kris's bed after the wake-up scene: in play you are out of it by then, and
    // come back in through the door). Out of it to the nearest free spot, in the first seconds only
    // and never during a cutscene (the wake-up scene has Kris in bed on purpose).
    if (global.mp_test_state == 1 && global.mp_test_timer > 20 && global.mp_test_timer < 300 && (global.mp_test_timer mod 10) == 0 && global.interact == 0 && global.mp_sstate == 0 && instance_exists(obj_mainchara) && !instance_exists(obj_battlecontroller))
    {
        with (obj_mainchara)
        {
            if (place_meeting(x, y, obj_solidblock))
            {
                var done = false;
                for (var r = 4; r <= 160 && !done; r += 4)
                {
                    for (var a = 0; a < 360 && !done; a += 45)
                    {
                        var nx = x + round(lengthdir_x(r, a));
                        var ny = y + round(lengthdir_y(r, a));
                        if (!place_meeting(nx, ny, obj_solidblock))
                        {
                            mp_log("[test] start position " + string(x) + "," + string(y) + " is inside something solid: moved to " + string(nx) + "," + string(ny));
                            x = nx;
                            y = ny;
                            done = true;
                        }
                    }
                }
                with (obj_caterpillarchara)
                {
                    x = obj_mainchara.x;
                    y = obj_mainchara.y;
                    scr_caterpillar_interpolate();
                }
            }
        }
    }
    // watchplot: log story progress, party and what the room's story events are doing every 5 s
    if (mp_test_has("watchplot") && (global.mp_frame mod 150) == 0 && variable_global_exists("plot"))
    {
        var evs = "";
        with (all)
        {
            var onm = object_get_name(object_index);
            if (string_pos("obj_", onm) == 1 && string_pos("event", onm) > 0 && variable_instance_exists(id, "con"))
                evs += " " + onm + ":" + string(con);
        }
        mp_log("[watch] " + room_get_name(room) + " plot=" + string(global.plot) + " party=" + string(global.char[0]) + string(global.char[1]) + string(global.char[2]) + " interact=" + string(global.interact) + " susieblock=" + string(instance_number(obj_npc_susiedark)) + " battle=" + string(instance_exists(obj_battlecontroller)) + " xy=" + (instance_exists(obj_mainchara) ? string(obj_mainchara.x) + "," + string(obj_mainchara.y) : "-") + " enemies=" + string(instance_number(obj_chaseenemy)) + " gold=" + string(global.gold) + " flag500=" + string(global.flag[500]) + evs);
    }
    // staleplot:<a>:<b>: once the plot reaches <a> (outside battles), set it back to <b>, as the copy
    // of a cutscene that a lagging player still watches does (Chapter 1 castle softlock)
    if (mp_test_has("staleplot") && !variable_global_exists("mp_test_staledone") && variable_global_exists("plot") && !instance_exists(obj_battlecontroller))
    {
        var sa = mp_test_arg("staleplot");
        var sc = string_pos(":", sa);
        if (global.plot == real(string_copy(sa, 1, sc - 1)))
        {
            global.mp_test_staledone = 1;
            global.plot = real(string_delete(sa, 1, sc));
            mp_log("[test] stale plot written: " + string(global.plot));
        }
    }
    // setplot:<n>: move the story on to <n> after a while (another player doing it while I stand in a room)
    if (mp_test_has("setplot") && global.mp_test_timer == 700 && mp_on() && global.mp_test_state == 1)
    {
        global.plot = real(mp_test_arg("setplot"));
        mp_log("[test] plot set to " + string(global.plot));
    }
    // gotohost:<n>: use the "go to the other player" action n frames after the party setup
    if (mp_test_has("gotohost") && global.mp_test_state == 1 && mp_on() && global.mp_test_timer == real(mp_test_arg("gotohost")))
        mp_go_to_player(mp_goto_target());
    // song:<file>: play this song (instead of whatever plays) 20 frames after the party setup
    if (mp_test_has("song") && global.mp_test_state == 1 && global.mp_test_timer == 20 && variable_global_exists("currentsong"))
    {
        if (snd_is_playing(global.currentsong[1]))
            snd_stop(global.currentsong[1]);
        global.currentsong[0] = snd_init(mp_test_arg("song"));
        // songext:<volume>:<pitch>: play it as some Chapter 1 scenes do (mus_loop_ext).
        var sx = mp_test_arg("songext");
        if (sx != "")
        {
            var sc = string_pos(":", sx);
            global.currentsong[1] = mus_loop_ext(global.currentsong[0], real(string_copy(sx, 1, sc - 1)), real(string_delete(sx, 1, sc)));
        }
        else
            global.currentsong[1] = mus_loop(global.currentsong[0]);
        mp_log("[test] playing " + mp_test_arg("song"));
    }
    // stuck:<n>: n frames after the party setup, fake a stuck sync state (as after a cutscene that was cut short):
    // watching a cutscene that never ends, character hidden, interact stuck
    if (mp_test_has("stuck") && global.mp_test_state == 1 && mp_on() && global.mp_test_timer == real(mp_test_arg("stuck")) && instance_exists(obj_mainchara))
    {
        global.mp_sstate = 3;
        global.mp_slead = 0;
        global.interact = 1;
        with (obj_mainchara)
            visible = 0;
        mp_log("[test] faked a stuck state");
    }
    // setvars: change a story flag and gold after a while; logvars: report them.
    if (mp_test_has("setvars") && global.mp_test_timer == 400)
    {
        global.flag[500] = 7;
        global.gold += 123;
        show_debug_message("[MPVARS] set flag500=7 gold=" + string(global.gold));
    }
    if (mp_test_has("logvars") && (global.mp_test_timer == 200 || global.mp_test_timer == 700))
        show_debug_message("[MPVARS] t=" + string(global.mp_test_timer) + " flag500=" + string(global.flag[500]) + " xy=" + (instance_exists(obj_mainchara) ? string(obj_mainchara.x) + "," + string(obj_mainchara.y) : "-") + " enemies=" + string(instance_number(obj_chaseenemy)) + " gold=" + string(global.gold) + " plot=" + string(global.plot));
    var battle_delay = mp_test_arg("battleat") != "" ? real(mp_test_arg("battleat")) : 120;
    // battleclk:<ms>: start the battle at this moment of the shared clock (two players at once)
    var clk_ok = mp_test_arg("battleclk") == "" || (mp_on() && mp_clock_now() >= real(mp_test_arg("battleclk")));
    if (mp_test_has("battle") && clk_ok && !global.mp_test_battled && instance_exists(obj_mainchara) && global.mp_test_timer > battle_delay && global.interact == 0 && (mp_on() || global.mp_role == 0 || mp_test_has("battlesolo")))
    {
        var other_ready = true;
        if (global.mp_role == 1 && !mp_test_has("battlesolo"))
            other_ready = mp_player_count() > 1 && global.mp_proom[1] == room;
        if (other_ready)
        {
            global.mp_test_battled = 1;
            // Fight with the full test party (a room's own cutscene may have changed it).
            global.char[0] = 1;
            global.char[1] = 2;
            global.char[2] = 3;
            // duo: Kris and Susie only (whoever plays Ralsei watches)
            if (mp_test_has("duo"))
                global.char[2] = 0;
            global.encounterno = real(mp_test_arg("battle"));
            mp_notify("[test] starting encounter " + string(global.encounterno));
            mp_battle_force_start();
        }
    }
    if (mp_test_has("numtest") && global.mp_test_timer == 60)
    {
        var bb = buffer_create(8, buffer_fixed, 1);
        buffer_write(bb, buffer_s32, 71);
        buffer_seek(bb, buffer_seek_start, 0);
        var iv = buffer_read(bb, buffer_s32);
        buffer_delete(bb);
        var a = mp_num(iv);
        var r = real(iv);
        show_debug_message("[NUMTEST] raw " + typeof(iv) + " " + string(iv / 90) + " | mp_num " + typeof(a) + " " + string(a / 90) + " " + string(a) + " | real() " + typeof(r) + " " + string(r / 90));
    }
    // charto:<c>@<frame>: change my character to c (1-4) then, as with F9 "Play as".
    if (mp_test_arg("charto") != "" && mp_on())
    {
        var cto = mp_test_arg("charto");
        var cat = string_pos("@", cto);
        if (cat > 0 && global.mp_frame == real(string_copy(cto, cat + 1, 9)))
            mp_char_change(real(string_copy(cto, 1, cat - 1)));
    }
    if (mp_test_has("crashtest") && global.mp_test_timer == 100)
        show_debug_message(real(global.mp_test));
    if (mp_test_has("check") && (global.mp_frame mod 30) == 0)
        mp_test_check();
    if (mp_test_has("check") && (global.mp_frame mod 300) == 150 && variable_global_exists("flag"))
    {
        var fl = "";
        for (var i = 60; i < array_length(global.flag); i++)
        {
            if (global.flag[i] != 0)
                fl += string(i) + "=" + string(global.flag[i]) + ",";
        }
        show_debug_message("[MPFLAGS] t=" + string(current_time) + " hfl=" + string_copy(md5_string_utf8(fl), 1, 8) + " " + fl);
    }
    if (mp_test_has("save") && !variable_global_exists("mp_test_saved") && instance_exists(obj_mainchara) && global.interact == 0 && global.mp_test_timer > 600)
    {
        global.mp_test_saved = 1;
        scr_saveprocess(0);
        show_debug_message("[MPCHK] saved slot 0 room=" + room_get_name(room) + " plot=" + string(global.plot));
    }
    if (mp_test_has("log") && variable_global_exists("mp_b_active") && mp_battle_on() && global.mp_bturn != global.mp_test_lastturn && !global.mp_bwait)
    {
        global.mp_test_lastturn = global.mp_bturn;
        var s = "[MPLOG] turn=" + string(global.mp_bturn) + " tp=" + string(global.tension);
        for (var i = 0; i < 3; i++)
        {
            if (global.char[i] != 0)
                s += " hp" + string(i) + "=" + string(global.hp[global.char[i]]) + "/own" + string(global.mp_owner[i]);
            if (global.monster[i])
                s += " mon" + string(i) + "=" + string(global.monsterhp[i]) + "/mercy" + string(global.mercymod[i]);
        }
        show_debug_message(s);
    }
}

// Bot RNG independent of GameMaker's (which the battle sync seeds deterministically).
function mp_test_rand(n)
{
    if (!variable_global_exists("mp_test_lcg"))
        global.mp_test_lcg = ((global.mp_myid * 7777) + 12345) mod 65537;
    // Small LCG: GML's mod works on 32-bit integers, so keep every product below 2^31.
    global.mp_test_lcg = ((global.mp_test_lcg * 75) + 74) mod 65537;
    return floor((global.mp_test_lcg / 65537) * n) mod n;
}

// Simple input bot used by automated tests. Runs before the multiplayer input logic.
// "bot" mashes Z; "botrand" also picks random menu commands and sometimes backs out.
function mp_test_input()
{
    if (global.mp_test == "")
        return;
    var f = global.mp_frame;
    // mashevery:<n> presses every n frames instead of 10 (a slow reader), mashfrom:<n> starts n frames into the room.
    var mash_every = mp_test_arg("mashevery") != "" ? real(mp_test_arg("mashevery")) : 10;
    var mash_from = mp_test_arg("mashfrom") != "" ? real(mp_test_arg("mashfrom")) : 15;
    // climb:<frame>: (Chapters 4-5) at that test frame, start climbing at the nearest climbing
    // spot; climbup then climbs up for a while every few seconds.
    if (mp_test_arg("climb") != "" && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(mp_test_arg("climb")))
    {
        var cso = asset_get_index("obj_climbstarter");
        if (cso >= 0 && instance_exists(cso))
        {
            global.flag[23] = 1;
            with (instance_exists(obj_mainchara) ? instance_nearest(obj_mainchara.x, obj_mainchara.y, cso) : instance_find(cso, 0))
                forcetoclimb = true;
            mp_log("[test] climbing");
        }
        else
            mp_log("[test] climb: no climbing spot here");
    }
    if (mp_test_has("climbup") && mp_climb_on() && (global.mp_frame mod 90) < 30)
        global.input_held[2] = 1;
    // weird: (Chapter 5) the walking character in "weird mode" (drawn with draw_sprite, shaking).
    if (mp_test_has("weird") && instance_exists(obj_mainchara))
    {
        with (obj_mainchara)
        {
            if (variable_instance_exists(id, "_weird_mode"))
                _weird_mode = true;
        }
    }
    // openmenu: open the C menu once, a few seconds into the room (to see what it shows).
    if (mp_test_has("openmenu") && variable_global_exists("mp_test_timer") && global.mp_test_timer == 150 && global.interact == 0)
    {
        global.input_pressed[6] = 1;
        global.input_held[6] = 1;
    }
    // restartroom:<frame>: build the room again at that frame of the room (once), like walking back in.
    if (mp_test_has("restartroom") && !variable_global_exists("mp_test_rrdone") && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(mp_test_arg("restartroom")))
    {
        global.mp_test_rrdone = 1;
        mp_log("test: room built again");
        room_restart();
    }
    // useobj:<object>:<frame>: use (as with Z) the first <object> in the room at that room frame.
    if (mp_test_has("useobj") && variable_global_exists("mp_test_timer"))
    {
        var ua = mp_test_arg("useobj");
        var uc = string_pos(":", ua);
        var uo = asset_get_index(string_copy(ua, 1, uc - 1));
        if (global.mp_test_timer == real(string_delete(ua, 1, uc)) && uo >= 0 && instance_exists(uo))
        {
            mp_log("test: using " + object_get_name(uo));
            with (instance_find(uo, 0))
                event_user(0);
        }
    }
    // logreading: every 5 frames, who the player list shows as "(reading)".
    if (mp_test_has("logreading") && mp_on() && (global.mp_frame mod 5) == 0)
    {
        var rd = "";
        for (var ri = 0; ri < 8; ri++)
        {
            if (ri != global.mp_myid && global.mp_pconn[ri] && mp_player_reading(ri))
                rd += global.mp_pname[ri] + " ";
        }
        if (rd != "")
            mp_log("[test] reading: " + rd + "(box " + string(global.mp_dlg_n) + ")");
    }
    // watchnext:<frame>: switch to watching the next player (as right on the map while watching).
    if (mp_test_has("watchnext") && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(mp_test_arg("watchnext")) && mp_on() && mp_spec_on())
        mp_spec_set(mp_spec_next(global.mp_spec, 1) < 0 ? mp_spec_next(-1, 1) : mp_spec_next(global.mp_spec, 1));
    // watch:<frame>: start watching the first other player at that room frame.
    if (mp_test_has("watch") && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(mp_test_arg("watch")) && mp_on())
        mp_spec_set(mp_spec_next(-1, 1));
    // useseq:<object>:<i>@<frame>/<i>@<frame>...: use the i-th <object> at each of those room frames.
    if (mp_test_has("useseq") && variable_global_exists("mp_test_timer"))
    {
        var qa = mp_test_arg("useseq");
        var qc = string_pos(":", qa);
        var qo = asset_get_index(string_copy(qa, 1, qc - 1));
        var qs = string_split(string_delete(qa, 1, qc), "/");
        for (var qi = 0; qi < array_length(qs) && qo >= 0; qi++)
        {
            var qp = string_split(qs[qi], "@");
            if (array_length(qp) == 2 && global.mp_test_timer == real(qp[1]) && instance_number(qo) > real(qp[0]))
            {
                mp_log("test: using " + object_get_name(qo) + " #" + qp[0]);
                with (instance_find(qo, real(qp[0])))
                    event_user(0);
            }
        }
    }
    // logpuz, suits puzzles: the suits shown, every 5 s.
    if (mp_test_has("logpuz") && (global.mp_frame mod 150) == 0 && asset_get_index("obj_suitspuzz") >= 0 && instance_exists(asset_get_index("obj_suitspuzz")))
    {
        with (asset_get_index("obj_suitspuzz"))
        {
            var su = "";
            for (var si = 0; si < max_suit; si++)
                su += string(suit[si]);
            show_debug_message("[MPPUZ] suits=" + su + " won=" + string(won));
        }
    }
    // logpuz, Chapter 2 traffic lights and alley switches: on or off, every 5 s.
    if (mp_test_has("logpuz") && (global.mp_frame mod 150) == 0)
    {
        var tso = asset_get_index("obj_traffic_switch");
        if (tso >= 0)
        {
            with (tso)
                show_debug_message("[MPPUZ] traffic " + string(round(xstart)) + "," + string(round(ystart)) + " active=" + string(active));
        }
        var fso = asset_get_index("obj_floorswitch");
        if (fso >= 0)
        {
            with (fso)
                show_debug_message("[MPPUZ] floorswitch " + string(round(xstart)) + "," + string(round(ystart)) + " pressed=" + string(pressed));
        }
        var aso = asset_get_index("obj_alleySwitch");
        if (aso >= 0)
        {
            with (aso)
                show_debug_message("[MPPUZ] alley " + string(round(xstart)) + "," + string(round(ystart)) + " toggle=" + string(toggle));
        }
    }
    // logpuz: the tile puzzle's state every 5 s (switch on, tiles stood on, rounds won).
    if (mp_test_has("logpuz") && (global.mp_frame mod 150) == 0 && asset_get_index("obj_glowtilepuzz") >= 0 && instance_exists(asset_get_index("obj_glowtilepuzz")))
    {
        var tl = "";
        with (asset_get_index("obj_glowtile"))
            tl += " " + string(round(x)) + "," + string(round(y)) + (active ? "+" : "-") + (stepped ? "S" : "");
        with (asset_get_index("obj_glowtilepuzz"))
            show_debug_message("[MPPUZ] active=" + string(active) + " won=" + string(wonamt) + " tiles:" + tl);
    }
    // logblocks: log where the room's pushable blocks are, every 5 s.
    if (mp_test_has("logblocks") && (global.mp_frame mod 150) == 0 && mp_puz_block_obj() >= 0)
    {
        var bl = "";
        with (mp_puz_block_obj())
            bl += " " + string(round(xstart)) + "," + string(round(ystart)) + "->" + string(round(x)) + "," + string(round(y));
        show_debug_message("[MPBLOCKS] room=" + room_get_name(room) + bl);
    }
    // pushblock:<dir>:<frame>: push the room's first pushable block in direction dir (0 down, 1 right,
    // 2 up, 3 left) at that frame of the room, as if I pushed it (made pushable if the story hasn't yet).
    if (mp_test_has("pushblock") && variable_global_exists("mp_test_timer") && global.interact == 0)
    {
        var pb = mp_test_arg("pushblock");
        var pc = string_pos(":", pb);
        var pfr = string_split(string_delete(pb, 1, pc), "/");
        var pnow = false;
        for (var pq = 0; pq < array_length(pfr); pq++)
            pnow = pnow || global.mp_test_timer == real(pfr[pq]);
        if (pnow)
        {
            var bo = mp_puz_block_obj();
            if (bo >= 0 && instance_exists(bo))
            {
                global.facing = real(string_copy(pb, 1, pc - 1));
                with (instance_find(bo, 0))
                {
                    event = 0;
                    event_user(0);
                }
                mp_log("test: pushed a block, confirm=" + string(instance_find(bo, 0).confirm) + " movecourse=" + string(instance_find(bo, 0).movecourse));
            }
        }
    }
    // menupage:<n>: with openmenu, then pick entry n of the C menu (0 items, 1 equipment, 3 power/status).
    if (mp_test_has("menupage") && variable_global_exists("mp_test_timer") && global.mp_test_timer == 190 && global.interact == 5 && variable_global_exists("menucoord"))
    {
        global.menucoord[0] = real(mp_test_arg("menupage"));
        global.input_pressed[4] = 1;
    }
    // buy:<item>: once everyone is in, at the next whole 5 s of the wall clock (the same moment in
    // every game on this PC), pay 50 and put the item in the first empty slot, as a shop does: two
    // players buying at the same time.
    if (mp_test_has("buy") && mp_on() && mp_player_count() >= 2 && global.mp_frame > 300 && !variable_global_exists("mp_test_bought") && variable_global_exists("mp_test_wcal") && global.interact == 0
        && (floor(global.mp_test_ws + ((current_time - global.mp_test_wb) / 1000)) mod 5) == 0)
    {
        global.mp_test_bought = 1;
        global.gold -= 50;
        for (var bi = 0; bi < array_length(global.item); bi++)
        {
            if (global.item[bi] == 0)
            {
                global.item[bi] = real(mp_test_arg("buy"));
                break;
            }
        }
        mp_log("[test] bought item " + mp_test_arg("buy") + " gold now " + string(global.gold));
    }
    // leaveat:<frame>: leave the session then (the host leaving, for the new-host test).
    if (mp_test_arg("leaveat") != "" && mp_on() && global.mp_frame == real(mp_test_arg("leaveat")))
        mp_disconnect("You left the session.");
    // setcon:<obj>:<con>:<frame>: at that test frame, sets that object's con (starts a scene the
    // way the game's own trigger would, the classroom's after its choice, for one).
    if (mp_test_arg("setcon") != "")
    {
        var sv = string_split(mp_test_arg("setcon"), ":");
        if (array_length(sv) >= 3 && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(sv[2]))
        {
            var so = asset_get_index(sv[0]);
            if (so >= 0 && instance_exists(so))
            {
                with (so)
                    con = real(sv[1]);
                mp_log("[test] " + sv[0] + ".con = " + sv[1]);
            }
            else
                mp_log("[test] setcon: no " + sv[0]);
        }
    }
    // drift:<flag>:<frame>: at that test frame, changes that story flag here without telling anyone
    // (as a lost change would): the drift check must find it and bring the host's value back.
    if (mp_test_arg("drift") != "")
    {
        var dv = string_split(mp_test_arg("drift"), ":");
        if (array_length(dv) >= 2 && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(dv[1]))
        {
            var df = real(dv[0]);
            global.flag[df] = global.flag[df] + 7;
            var fv = mp_var_index("flag");
            var sh = global.mp_vshadow[fv];
            sh[df] = global.flag[df];
            global.mp_vshadow[fv] = sh;
            mp_log("[test] flag " + string(df) + " = " + string(global.flag[df]) + " (not sent)");
        }
    }
    // fakechoice:<frame>: at that test frame, a two-answer choice box opens (as in a scene); logs the
    // answer once it is picked. pickright: while a choice box can be answered, right then Z.
    if (mp_test_arg("fakechoice") != "" && variable_global_exists("mp_test_timer") && (mp_test_arg("fakechoice") == "watch" ? (mp_test_watch_frames() == 60 && !variable_global_exists("mp_test_fchoice")) : global.mp_test_timer == real(mp_test_arg("fakechoice"))))
    {
        global.choice = -1;
        global.choicemsg[0] = "#Left";
        global.choicemsg[1] = "#Right";
        global.choicemsg[2] = "";
        global.choicemsg[3] = "";
        var mc_off = !instance_exists(obj_mainchara);
        if (mc_off)
            instance_activate_object(obj_mainchara);
        var fc = instance_create(0, 0, obj_choicer_neo);
        if (mc_off)
            instance_deactivate_object(obj_mainchara);
        fc.choicetotal = 1;
        global.mp_test_fchoice = 1;
        mp_log("[test] choice box opened");
    }
    if (variable_global_exists("mp_test_fchoice") && global.mp_test_fchoice && !instance_exists(obj_choicer_neo))
    {
        global.mp_test_fchoice = 0;
        mp_log("[test] choice answered: " + string(global.choice));
    }
    // pick:<n>: the same with answer n (0 left, 1 right).
    var pickn = mp_test_has("pickright") ? 1 : (mp_test_arg("pick") != "" ? real(mp_test_arg("pick")) : -1);
    if (pickn >= 0 && instance_exists(obj_choicer_neo) && (global.mp_test_timer mod 20) == 0)
    {
        if (obj_choicer_neo.mychoice != pickn)
            global.input_held[pickn == 1 ? 1 : 3] = 1;
        else
            global.input_pressed[4] = 1;
    }
    // vote: (host) everyone votes on scene choices.
    if (mp_test_has("vote") && global.mp_role == 1 && !global.mp_vote)
    {
        global.mp_vote = 1;
        mp_open_send();
    }
    // saytext:<frame>: at that test frame, a text box opens as if I talked to someone.
    if (mp_test_arg("saytext") != "" && variable_global_exists("mp_test_timer") && global.mp_test_timer == real(mp_test_arg("saytext")) && global.interact == 0)
    {
        global.msc = 0;
        global.typer = 5;
        global.fc = 0;
        global.msg[0] = "* This is a test of talking to someone on your own./";
        global.msg[1] = "* Everyone else should see it over your head./%";
        global.mp_lastz = global.mp_frame; // (as if Z was pressed on someone to talk)
        global.interact = 1;
        instance_create(0, 0, obj_dialoguer);
        mp_log("[test] text box opened");
    }
    // playersonly: (host) story fights with the players' heroes only.
    if (mp_test_has("playersonly") && global.mp_role == 1 && !global.mp_noai)
    {
        global.mp_noai = 1;
        mp_open_send();
    }
    // holdx: hold X all the time (speeds text up; set in the input state, so it works unfocused).
    if (mp_test_has("holdx"))
        global.input_held[5] = 1;
    // touch: the Z press, facing up.
    if (variable_global_exists("mp_test_touchz") && global.mp_frame >= global.mp_test_touchz && global.mp_frame < global.mp_test_touchz + 2)
    {
        global.input_held[2] = 1;
        if (global.mp_frame == global.mp_test_touchz + 1)
        {
            global.input_pressed[4] = 1;
            global.mp_lastz = global.mp_frame; // (injected after the game's own Z check, as for mash)
        }
    }
    // failz: press Continue on the Game Over screen.
    if (mp_test_has("failz") && string_pos("room_gameover", room_get_name(room)) == 1 && (f mod 4) == 0)
        global.input_pressed[4] = 1;
    if (mp_test_has("mash") && !global.mp_ui_open && string_pos("PLACE_", room_get_name(room)) != 1 && !instance_exists(obj_battlecontroller) && (f mod mash_every) == 0 && global.mp_room_frames > mash_from && (!instance_exists(obj_mainchara) || global.interact == 1))
    {
        // Dialogue choices need a direction first.
        if (instance_exists(obj_choicer_neo) && (f mod 20) == 0)
        {
            global.input_held[3] = 1;
            global.input_pressed[3] = 1;
        }
        else
            global.input_pressed[4] = 1;
    }
    if (mp_test_has("wander") && !instance_exists(obj_battlecontroller) && (instance_exists(obj_mainchara) || mp_plat_on()) && global.interact == 0 && variable_global_exists("mp_test_timer") && global.mp_test_timer > 200)
    {
        if (!variable_global_exists("mp_test_wdir") || (f mod 45) == 0)
            global.mp_test_wdir = mp_test_rand(6);
        if (global.mp_test_wdir < 4)
            global.input_held[global.mp_test_wdir] = 1;
        // Platforming: jump now and then (X).
        if (mp_plat_on() && (f mod 40) == 0 && mp_test_rand(2) == 0)
        {
            global.input_pressed[5] = 1;
            global.input_held[5] = 1;
        }
    }
    // fakescene: while being pulled into a battle, start a cutscene of our own (an object with a
    // cutscene master, like every story cutscene), once - the thing mp_kill_scenes must stop.
    if (mp_test_has("fakescene") && global.mp_battle_pulled && !mp_in_battle_scene() && !variable_global_exists("mp_fake_done") && asset_get_index("obj_marker") >= 0 && asset_get_index("scr_cutscene_make") >= 0)
    {
        global.mp_fake_done = 1;
        var fo = instance_create(0, 0, asset_get_index("obj_marker"));
        fo.cutscene_master = script_execute(asset_get_index("scr_cutscene_make"));
        with (fo)
            script_execute(asset_get_index("c_wait"), 600);
        global.interact = 1;
        mp_log("fakescene created, master " + string(fo.cutscene_master) + " exists " + string(mp_cutscene_master_exists()));
    }
    if (mp_test_has("away") && variable_global_exists("mp_test_state") && mp_on() && global.mp_test_state == 1 && !variable_global_exists("mp_test_awaydone") && global.interact == 0 && (instance_exists(obj_mainchara) || string_pos("PLACE_", room_get_name(room)) == 1))
    {
        // away:<room>:<n>[:<x>:<y>]
        var aw = mp_test_arg("away");
        var ap = string_pos(":", aw);
        var ar = string_delete(aw, 1, ap);
        var ap2 = string_pos(":", ar);
        var an = ap2 > 0 ? real(string_copy(ar, 1, ap2 - 1)) : real(ar);
        var ax = 300;
        var ay = 300;
        if (ap2 > 0)
        {
            var axy = string_delete(ar, 1, ap2);
            var ap3 = string_pos(":", axy);
            ax = real(string_copy(axy, 1, ap3 - 1));
            ay = real(string_delete(axy, 1, ap3));
        }
        if (global.mp_test_timer >= an)
        {
            global.mp_test_awaydone = 1;
            mp_warp(asset_get_index(string_copy(aw, 1, ap - 1)), ax, ay, 0);
        }
    }
    if (mp_test_has("walk") && instance_exists(obj_mainchara) && variable_global_exists("mp_test_timer"))
    {
        var wa = mp_test_arg("walk");
        var p1 = string_pos(":", wa);
        var wd = string_copy(wa, 1, p1 - 1);
        var wr = string_delete(wa, 1, p1);
        var p2 = string_pos(":", wr);
        var wt = real(string_copy(wr, 1, p2 - 1));
        var wn = real(string_delete(wr, 1, p2));
        if (global.mp_test_state == 1 && global.mp_test_timer >= wt && global.mp_test_timer < wt + wn && global.interact == 0)
        {
            var di = 0;
            if (wd == "r")
                di = 1;
            if (wd == "u")
                di = 2;
            if (wd == "l")
                di = 3;
            global.input_held[di] = 1;
        }
    }
    if (!mp_test_has("bot"))
        return;
    if (instance_exists(obj_battlecontroller))
    {
        if (global.mnfight == 2 && instance_exists(obj_heart))
        {
            // nododge: stand still and take the hits (to test downed players and Game Over)
            if (!mp_test_has("nododge"))
            {
                var d = floor(f / 20) mod 4;
                global.input_held[d] = 1;
            }
            return;
        }
        // fulltp: TP full at every menu turn (spells can be cast). botslow: in the menu, a press every
        // 30 frames instead of 6 (others get time to choose ahead).
        if (mp_test_has("fulltp") && instance_exists(obj_battlecontroller) && global.myfight == 0 && global.mnfight == 0)
            global.tension = 250;
        if (mp_test_has("botslow") && global.myfight == 0 && global.mnfight == 0 && global.charturn < 3 && global.mp_owner[global.charturn] == global.mp_myid && (f mod 30) != 0)
            return;
        // plan:<bar>:<n1>:<n2>: while someone else chooses, plan my next hero's action: that bar,
        // then n1 presses down on level 1, n2 on level 2 (Z between). The bot's Z plays it after.
        if (mp_test_arg("plan") != "" && (f mod 6) == 0 && global.mp_presel >= 0 && global.mp_pl_slot == global.mp_presel && !global.mp_pl_ready && global.charturn < 3 && global.mp_owner[global.charturn] != global.mp_myid)
        {
            var pv = string_split(mp_test_arg("plan"), ":");
            if (!variable_global_exists("mp_test_pl_k") || global.mp_test_pl_t != global.mp_bturn)
            {
                global.mp_test_pl_k = 0;
                global.mp_test_pl_t = global.mp_bturn;
            }
            var lvl = global.mp_pl_d;
            if (lvl == 0 && global.bmenucoord[0][global.mp_presel] != real(pv[0]))
                global.input_pressed[1] = 1;
            else if (lvl > 0 && global.mp_test_pl_k < real(pv[lvl]))
            {
                global.input_pressed[0] = 1;
                global.mp_test_pl_k += 1;
            }
            else
            {
                global.input_pressed[4] = 1;
                global.mp_test_pl_k = 0;
            }
            return;
        }
        if ((f mod 6) == 0)
        {
            var menu = global.myfight == 0 && global.mnfight == 0;
            if (menu && mp_test_has("botrand"))
            {
                var r = mp_test_rand(10);
                if (r < 3)
                    global.input_pressed[1] = 1;      // right
                else if (r < 4)
                    global.input_pressed[0] = 1;      // down
                else if (r < 5)
                    global.input_pressed[5] = 1;      // X (back)
                else
                    global.input_pressed[4] = 1;      // Z
            }
            else if (!mp_test_has("botquiet"))   // botquiet: never presses Z on battle text
            {
                global.input_pressed[4] = 1;
            }
        }
        return;
    }
    if (global.interact != 0 && (f mod 8) == 0)
        global.input_pressed[4] = 1;
    // walkto:<x>:<y> walks the player there once the other player is in the room.
    if (mp_test_has("walkto") && global.interact == 0 && instance_exists(obj_mainchara) && variable_global_exists("mp_test_posdone") && global.mp_test_timer > 300)
    {
        var wv = mp_test_arg("walkto");
        var c = string_pos(":", wv);
        var tx = real(string_copy(wv, 1, c - 1));
        var ty = real(string_delete(wv, 1, c));
        if (obj_mainchara.x < tx - 2)
            global.input_held[1] = 1;
        else if (obj_mainchara.x > tx + 2)
            global.input_held[3] = 1;
        if (obj_mainchara.y < ty - 2)
            global.input_held[0] = 1;
        else if (obj_mainchara.y > ty + 2)
            global.input_held[2] = 1;
    }
}

function mp_log(s)
{
    var line = "[MPD f=" + string(global.mp_frame) + " t=" + string(current_time) + "] " + s;
    if (variable_global_exists("mp_test") && global.mp_test != "" && mp_test_has("log"))
        show_debug_message(line);
    if (variable_global_exists("mp_logq") && global.mp_log_lines < 50000)
    {
        array_push(global.mp_logq, line);
        global.mp_log_lines += 1;
    }
}

// Every session writes multiplayer_log.txt next to the save files (the one before is kept as
// multiplayer_log_prev.txt), so a problem in real play can be looked into afterwards.
function mp_filelog_init()
{
    global.mp_logq = [];
    global.mp_log_lines = 0;
    if (file_exists("multiplayer_log.txt"))
    {
        if (file_exists("multiplayer_log_prev.txt"))
            file_delete("multiplayer_log_prev.txt");
        file_rename("multiplayer_log.txt", "multiplayer_log_prev.txt");
    }
    mp_log("session start: chapter " + string(__CHAPTER__) + ", " + date_datetime_string(date_current_datetime()) + ", mod protocol " + string(global.mp_version));
}

function mp_filelog_flush()
{
    if (!variable_global_exists("mp_logq") || array_length(global.mp_logq) == 0)
        return;
    var fh = file_text_open_append("multiplayer_log.txt");
    if (fh >= 0)
    {
        for (var i = 0; i < array_length(global.mp_logq); i++)
        {
            file_text_write_string(fh, global.mp_logq[i]);
            file_text_writeln(fh);
        }
        file_text_close(fh);
    }
    global.mp_logq = [];
}

function mp_test_battle_created()
{
    // fragile: my hero starts the fight at 1 HP (to test a downed player's SOUL).
    if (global.mp_test != "" && mp_test_has("fragile"))
        global.hp[global.mp_pchar[global.mp_myid]] = 1;
    // sturdy: the heroes have 10 times their HP (a long fight, e.g. one player alone for a while).
    if (global.mp_test != "" && mp_test_has("sturdy"))
    {
        for (var hc = 1; hc <= 4; hc++)
        {
            if (hc < array_length(global.maxhp) && global.maxhp[hc] < 1000)
            {
                global.maxhp[hc] *= 10;
                global.hp[hc] = global.maxhp[hc];
            }
        }
    }
    if (global.mp_test != "" && mp_test_has("weak"))
    {
        // weak: enemies have 1 HP, so the fight ends after the first hits (tests what comes after a battle).
        for (var j = 0; j < 3; j++)
        {
            global.monsterhp[j] = min(global.monsterhp[j], 1);
            global.monstermaxhp[j] = min(global.monstermaxhp[j], 1);
        }
        return;
    }
    if (global.mp_test == "" || !mp_test_has("tough"))
        return;
    for (var i = 0; i < 3; i++)
    {
        global.monsterhp[i] *= 8;
        global.monstermaxhp[i] *= 8;
    }
}

function mp_ch_test_party()
{
    for (var c = 1; c <= 3; c++)
        global.hp[c] = global.maxhp[c];
}

// One self-check line (see tools/mpcheck.py).
function mp_test_check()
{
    var mx = -1;
    var my = -1;
    var vis = 0;
    if (instance_exists(obj_mainchara))
    {
        mx = obj_mainchara.x;
        my = obj_mainchara.y;
        vis = obj_mainchara.visible && (global.mp_frame - global.mp_my_drawn) < 3;
    }
    var s = "[MPCHK] t=" + string(current_time) + " wc=" + string_format(global.mp_test_ws - ((global.mp_test_wb - current_time) / 1000), 1, 3) + " f=" + string(global.mp_frame) + " id=" + string(global.mp_myid);
    s += " on=" + string(mp_on()) + " want=" + string(global.mp_cfg_char);
    s += " room=" + room_get_name(room) + " x=" + string(round(mx)) + " y=" + string(round(my));
    // What the player walks with when it is not Kris (Chapter 4 basement: a heart, Kris parked off screen)
    var hobj = asset_get_index("obj_homealone_heart");
    if (hobj >= 0 && instance_exists(hobj))
        s += " walk=" + string(round(hobj.x)) + "," + string(round(hobj.y));
    var ddx = global.mp_my_x;
    var ddy = global.mp_my_y;
    var dspr = global.mp_my_spr;
    var bi = mp_board_send_info();
    if (is_array(bi))
    {
        // On the Chapter 3 board: my piece, in whole-board coordinates.
        ddx = bi[0];
        ddy = bi[1];
        dspr = bi[2];
        vis = bi[6];
        var tl0 = layer_get_id("BOARD_Tiles");
        s += " bvx=" + string(round(128 - layer_get_x(tl0))) + " bvy=" + string(round(64 - layer_get_y(tl0)));
    }
    var pli = mp_plat_send_info();
    if (is_array(pli))
    {
        // In a Chapter 5 platforming section: my platformer figure.
        ddx = pli[0];
        ddy = pli[1];
        dspr = pli[2];
        vis = pli[6];
    }
    s += " plat=" + string(mp_plat_on());
    s += " dx=" + string(round(ddx)) + " dy=" + string(round(ddy)) + " vis=" + string(vis);
    s += " drawn=" + string(mp_test_sprite_char(dspr)) + " spr=" + sprite_get_name(dspr) + " board=" + string(mp_board_on());
    s += " sst=" + string(global.mp_sstate) + " ia=" + string(global.interact) + " bat=" + string(mp_in_battle_scene()) + " dlg=" + string(global.mp_local_dlg) + " dz=" + string(mp_dz()) + " rf=" + string(global.mp_room_frames) + " hpv=" + string(global.hp[1]) + "/" + string(global.hp[2]) + "/" + string(global.hp[3]) + " cct=" + string(global.charcantarget[0]) + string(global.charcantarget[1]) + string(global.charcantarget[2]) + " ch=" + string(global.char[0]) + string(global.char[1]) + string(global.char[2]);
    s += " fol=" + string(global.mp_fol_last);
    var gs = "";
    for (var i = 0; i < 8; i++)
    {
        if (i == global.mp_myid || !global.mp_pconn[i])
            continue;
        gs += string(i) + ":" + string(global.mp_pchar[i]) + ":" + string(global.mp_proom[i]) + ":" + string(global.mp_px[i]) + ":" + string(global.mp_py[i]);
        var g = global.mp_pghost[i];
        if (instance_exists(g))
        {
            var gx = g.x;
            var gy = g.y;
            if (mp_board_on())
            {
                var tl = layer_get_id("BOARD_Tiles");
                gx -= layer_get_x(tl);
                gy -= layer_get_y(tl);
            }
            gs += ":G" + string(round(gx)) + ":" + string(round(gy));
        }
        gs += ";";
    }
    s += " peers=" + gs + " " + mp_test_hash();
    show_debug_message(s);
}

// Hash of the shared story state, split in parts so a mismatch shows what differs.
function mp_test_hash()
{
    var fl = "";
    var n = array_length(global.flag);
    for (var i = 60; i < n; i++)
    {
        if (global.flag[i] != 0)
            fl += string(i) + "=" + string(global.flag[i]) + ",";
    }
    var it = "";
    for (var j = 0; j < array_length(global.item); j++)
        it += string(global.item[j]) + ",";
    for (var j = 0; j < array_length(global.keyitem); j++)
        it += string(global.keyitem[j]) + ",";
    for (var j = 0; j < array_length(global.weapon); j++)
        it += string(global.weapon[j]) + ",";
    for (var j = 0; j < array_length(global.armor); j++)
        it += string(global.armor[j]) + ",";
    var hp = "";
    for (var j = 0; j < array_length(global.hp); j++)
        hp += string(global.hp[j]) + "/" + string(global.maxhp[j]) + ",";
    var party = string(global.char[0]) + string(global.char[1]) + string(global.char[2]);
    global.mp_tmp_mus = "none";
    if (variable_global_exists("currentsong") && is_array(global.currentsong) && audio_is_playing(global.currentsong[1]))
    {
        with (obj_astream)
        {
            if (variable_instance_exists(id, "songname") && variable_instance_exists(id, "mystream") && mystream == global.currentsong[0])
                global.mp_tmp_mus = songname;
        }
    }
    var mus = global.mp_tmp_mus;
    return "mus=" + mus + " nact=" + string(asset_get_index("obj_actor") >= 0 ? instance_number(asset_get_index("obj_actor")) : 0) + " plot=" + string(global.plot) + " xy=" + (instance_exists(obj_mainchara) ? string(obj_mainchara.x) + "," + string(obj_mainchara.y) : "-") + " enemies=" + string(instance_number(obj_chaseenemy)) + " gold=" + string(global.gold) + " party=" + party + " hfl=" + string_copy(md5_string_utf8(fl), 1, 8) + " hit=" + string_copy(md5_string_utf8(it), 1, 8) + " hhp=" + string_copy(md5_string_utf8(hp), 1, 8);
}

// Character a (field or board) sprite belongs to.
function mp_test_sprite_char(spr)
{
    if (!sprite_exists(spr))
        return 0;
    var n = sprite_get_name(spr);
    if (string_pos("spr_board_", n) == 1)
        n = "spr_" + string_delete(n, 1, 10);
    if (string_pos("spr_kris", n) == 1)
        return 1;
    if (string_pos("spr_susie", n) == 1)
        return 2;
    if (string_pos("spr_ralsei", n) == 1)
        return 3;
    if (string_pos("spr_noelle", n) == 1)
        return 4;
    return 0;
}

// How many frames I have been watching another player's scene (0 when not).
function mp_test_watch_frames()
{
    if (!variable_global_exists("mp_test_w5"))
        global.mp_test_w5 = 0;
    if (global.mp_sstate == 5)
        global.mp_test_w5 += 1;
    else
        global.mp_test_w5 = 0;
    return global.mp_test_w5;
}
