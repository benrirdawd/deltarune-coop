// DELTARUNE Multiplayer - battles.
//
// Every player runs the battle locally. To keep all copies identical:
//  * Menu: the player who owns the hero whose turn it is drives the menu; their button
//    presses (with original frame spacing) are replayed by everyone else.
//  * Attack timing: each player presses for their own hero(es); results are shared.
//  * Random numbers are re-seeded identically at each phase.
//  * Bullets: everyone dodges with their own SOUL; hits only hurt the hero you play.
//    HP is owned by the hero's player and broadcast as it changes.
//  * Turn barrier: before each new menu turn everyone waits for the host's TURN_GO,
//    which carries the authoritative TP (everyone's grazes added up), HP and enemy state.

function mp_battle_init()
{
    global.mp_minq = ds_list_create();
    global.mp_qte = ds_map_create();
    global.mp_owner = array_create(3, 0);
    global.mp_rhp = array_create(3, 0);
    global.mp_rhp_known = array_create(3, 0);
    global.mp_hp_sent = array_create(3, -99999);
    global.mp_tdone_bid = array_create(8, -1);
    global.mp_tdone_turn = array_create(8, -1);
    global.mp_tdone_gain = array_create(8, 0);
    global.mp_tdone_late = array_create(8, 0);
    global.mp_tgo_sent = -1;
    global.mp_tgo_stash = -1;
    mp_battle_reset();
}

// Clears the per-battle buffers (inputs and attack results received from others).
function mp_battle_clear_buffers()
{
    ds_list_clear(global.mp_minq);
    ds_map_clear(global.mp_qte);
}

function mp_battle_reset()
{
    if (variable_global_exists("mp_hold"))
    {
        mp_hold_end();
        global.mp_hold_want = 0;
        global.mp_tgo_pending = -1;
        mp_gate_reset();
    }
    if (variable_global_exists("mp_susie_lent"))
        mp_susie_restore();
    global.mp_susie_lent = 0;
    global.mp_gameover = 0;
    global.mp_tgo_sent = -1;
    global.mp_b_active = 0;
    global.mp_bid = -1;
    global.mp_bturn = 0;
    global.mp_bgo = -1;
    global.mp_prev_myfight = 0;
    global.mp_prev_charturn = 0;
    global.mp_bwait = 0;
    global.mp_bwait_names = "";
    global.mp_bwait_names_time = -99999;
    global.mp_bwait_names_sent = "";
    global.mp_bwait_turn = 0;
    global.mp_bwait_since = 0;
    global.mp_bgate_open = 0;
    global.mp_mn = 0;
    global.mp_mn_last = 0;
    global.mp_mn_pend = 0;
    global.mp_prev_mnfight = -99;
    global.mp_tension_b0 = 0;
    global.mp_act_wn = 0;
    global.mp_act_wr = false;
    global.mp_presel = -1;
    global.mp_susie_lock_log = -1;
    global.mp_t_mine = 0;           // TP my own SOUL earned (grazes) or lost (hits while down) this bullet phase
    global.mp_t_shown = 0;
    global.mp_t_sent = -99999;
    global.mp_t_sent_f = 0;
    global.mp_t_remote = array_create(8, 0);
    global.mp_t_rturn = array_create(8, -1);
    global.mp_down_hit_f = -9999;
    global.mp_down_hit_n = 0;
    global.mp_tp_flash_f = -9999;
    global.mp_qte_since = 0;
    for (var s = 0; s < 3; s++)
    {
        global.mp_rhp_known[s] = 0;
        global.mp_hp_sent[s] = -99999;
    }
    global.mp_soul_x = array_create(8, 0);
    global.mp_soul_y = array_create(8, 0);
    global.mp_soul_tx = array_create(8, 0);
    global.mp_soul_ty = array_create(8, 0);
    global.mp_soul_f = array_create(8, -9999);
    global.mp_soul_seen = 0;
    global.mp_spec_on = false;
    global.mp_spec_target = -1;
    global.mp_spec_alpha = 1;
}

function mp_battle_on()
{
    return global.mp_b_active && mp_on() && (global.mp_hold || instance_exists(obj_battlecontroller));
}

function mp_slot_mine(s)
{
    if (!mp_battle_on())
        return true;
    if (s < 0 || s > 2)
        return false;
    return global.mp_owner[s] == global.mp_myid;
}

// Who controls each party slot: the lowest-id player who picked that character,
// otherwise the host. Players whose character is not in the party watch.
function mp_participating(i)
{
    if (!global.mp_pconn[i])
        return false;
    if (!mp_b_lead() || i == global.mp_myid)
        return true;
    return mp_in_mask(i) && global.mp_tdone_bid[i] == global.mp_bid;
}

function mp_compute_owners()
{
    var lead = global.mp_b_leader;
    for (var s = 0; s < 3; s++)
    {
        var c = global.char[s];
        var o = lead;
        if (c == 0)
            o = 255;
        else
        {
            // (Of the players with this character, the one who picked it first.)
            var best = -1;
            for (var i = 0; i < 8; i++)
            {
                if (global.mp_pchar[i] == c && mp_participating(i) && (best < 0 || global.mp_ppick[i] < global.mp_ppick[best]))
                    best = i;
            }
            if (best >= 0)
                o = best;
        }
        global.mp_owner[s] = o;
    }
}

// Chapter 1 puts Susie on autopilot until the prison (global.charauto[2]): she gets no menu and no
// attack row, and swings by herself. A player who picked Susie plays her instead, for this battle.
// Decided from the owners the host sent, so every game agrees.
function mp_susie_update()
{
    var played = false;
    for (var s = 0; s < 3; s++)
    {
        var o = global.mp_owner[s];
        if (global.char[s] == 2 && o != 255 && global.mp_pchar[o] == 2)
            played = true;
    }
    if (!played)
        mp_susie_restore();
    else if (!global.mp_susie_lent && global.charauto[2] == 1)
    {
        global.mp_susie_lent = 1;
        global.charauto[2] = 0;
        mp_log("susie: autopilot off, a player has her");
    }
}

// Chapter 1's Susie only ever attacks the topmost enemy (the story has her not listening yet): the
// player playing her gets FIGHT and the topmost enemy, and does the attack timing. Run by every game
// on its own copy of the menu, so all agree.
function mp_susie_lock()
{
    if (!global.mp_susie_lent || global.mp_chapter != 1 || global.char[global.charturn] != 2)
        return;
    var ct = global.charturn;
    if (global.mp_susie_lock_log != global.mp_bturn)
    {
        global.mp_susie_lock_log = global.mp_bturn;
        mp_log("susie lock turn " + string(global.mp_bturn));
    }
    if (global.bmenuno == 0)
    {
        global.bmenucoord[0][ct] = 0;
        global.input_pressed[1] = 0;
        global.input_pressed[3] = 0;
    }
    else if (global.bmenuno == 1)
    {
        for (var m = 0; m < 3; m++)
        {
            if (global.monster[m] == 1)
            {
                global.bmenucoord[1][ct] = m;
                break;
            }
        }
        global.input_pressed[0] = 0;
        global.input_pressed[2] = 0;
    }
}

// Back to autopilot once the battle is over, so the story's own setting is what remains.
function mp_susie_restore()
{
    if (global.mp_susie_lent)
    {
        global.mp_susie_lent = 0;
        global.charauto[2] = 1;
        mp_log("susie: autopilot back on");
    }
}

function mp_battle_seed(phase)
{
    if (!mp_battle_on())
        return;
    var sd = (global.mp_seed + (global.mp_bturn * 7919) + (phase * 104729) + (global.mp_bid * 31)) mod 2147483647;
    random_set_seed(sd);
}

// ---------------------------------------------------------------- lifecycle

// Appended to obj_battlecontroller's Create event.
function mp_battle_created()
{
    if (!mp_on())
        return;
    mp_battle_reset();
    mp_test_battle_created();
    global.mp_b_active = 1;
    global.mp_bid = global.encounterno;
    global.mp_bturn = 0;
    global.mp_bwait = 1;
    global.mp_bwait_turn = 0;
    global.mp_bwait_since = current_time;
    global.mp_tension_b0 = global.tension;
    mp_tp_phase_start();
    global.mp_hold_want = 1;
    mp_stand_in_make();
    // No fight yet: a story battle started by my own cutscene.
    mp_gid_ensure(255, !instance_exists(obj_testoverworldenemy));
    mp_fight_snapshot();
    mp_compute_owners();
    mp_send_tdone(0, 0);
    global.mp_tdone_bid[global.mp_myid] = global.mp_bid;
    global.mp_tdone_turn[global.mp_myid] = 0;
}

function mp_battle_ended()
{
    if (global.mp_scenes_killed)
    {
        global.mp_scenes_killed = 0;
        global.mp_postbattle = 120;
    }
    global.mp_b_active = 0;
    mp_susie_restore();
    mp_battle_clear_buffers();
    global.mp_tgo_stash = -1;
    mp_fight_settle(mp_b_lead());
    mp_party_restore();
    mp_gid_clear();
    for (var i = 0; i < 8; i++)
    {
        global.mp_tdone_bid[i] = -1;
        global.mp_tdone_turn[i] = -1;
    }
}

function mp_send_tdone(turn, gain)
{
    mp_begin_b(44);
    mp_wu16(global.mp_bid);
    mp_wu16(turn);
    mp_wf64(gain);
    mp_send();
}

// Prepended to scr_mnendturn: holds the next menu turn until everyone is ready.
function mp_turn_gate()
{
    if (!mp_battle_on())
        return true;
    if (global.mp_bgate_open)
    {
        global.mp_bgate_open = 0;
        return true;
    }
    // Keep the battle controller from re-arming its end-of-turn alarm while we wait.
    with (obj_battlecontroller)
    {
        reset = 1;
        alarm[2] = -1;
    }
    if (!global.mp_bwait)
    {
        global.mp_bwait = 1;
        global.mp_bwait_turn = global.mp_bturn + 1;
        global.mp_bwait_since = current_time;
        mp_battle_send_hp();
        // (Can be negative: hits taken while down cost TP.)
        var gain = global.mp_t_mine;
        mp_log("gate reached, tdone " + string(global.mp_bwait_turn) + " gain=" + string(gain) + " myfight=" + string(global.myfight) + " mnfight=" + string(global.mnfight) + " mon=" + string(global.monster[0]) + string(global.monster[1]) + string(global.monster[2]) + " types=" + string(global.monstertype[0]) + "," + string(global.monstertype[1]) + "," + string(global.monstertype[2]));
        mp_send_tdone(global.mp_bwait_turn, gain);
        global.mp_tdone_bid[global.mp_myid] = global.mp_bid;
        global.mp_tdone_turn[global.mp_myid] = global.mp_bwait_turn;
        global.mp_tdone_gain[global.mp_myid] = 0;
    }
    return false;
}

// ---------------------------------------------------------------- receive

function mp_battle_recv(type, from, b)
{
    if (type == 52) // a player asks to join my fight
    {
        if (buffer_read(b, buffer_u8) == global.mp_myid)
            mp_join_answer(from);
        return;
    }
    // Everything else belongs to one fight: not mine, not for me.
    if (buffer_read(b, buffer_u16) != global.mp_gid)
        return;
    if (type >= 48 && type <= 51)
    {
        mp_timing_recv(type, from, b);
        return;
    }
    if (type == 54) // where another player's next hero's bar is (choosing ahead)
    {
        var pturn = buffer_read(b, buffer_u16);
        var pslot = buffer_read(b, buffer_u8);
        var pbar = buffer_read(b, buffer_u8);
        if (pturn == global.mp_bturn && pslot < 3 && pbar < 5 && global.mp_owner[pslot] == from && pslot > global.charturn && global.bmenuno >= 0)
            global.bmenucoord[0][pslot] = pbar;
        return;
    }
    if (type == 53) // the sender's own TP gain this bullet phase (live TP)
    {
        var tturn = buffer_read(b, buffer_u16);
        var tv = buffer_read(b, buffer_f64);
        if (from >= 0 && from < 8)
        {
            global.mp_t_rturn[from] = tturn;
            global.mp_t_remote[from] = tv;
        }
        return;
    }
    if (type == 47) // where the sender's SOUL is
    {
        var sx = buffer_read(b, buffer_s16);
        var sy = buffer_read(b, buffer_s16);
        if (from >= 0 && from < 8)
        {
            global.mp_soul_tx[from] = sx;
            global.mp_soul_ty[from] = sy;
            // First update of this bullet phase: appear there instead of sliding across the box.
            if ((global.mp_frame - global.mp_soul_f[from]) > 15)
            {
                global.mp_soul_x[from] = sx;
                global.mp_soul_y[from] = sy;
            }
            global.mp_soul_f[from] = global.mp_frame;
        }
        return;
    }
    if (type == 41) // MENU INPUT
    {
        var bid = buffer_read(b, buffer_u16);
        var turn = buffer_read(b, buffer_u16);
        var n = buffer_read(b, buffer_u16);
        var dt = buffer_read(b, buffer_u8);
        var mask = buffer_read(b, buffer_u16);
        var c0 = buffer_read(b, buffer_u8);
        ds_list_add(global.mp_minq, [bid, turn, n, dt, mask, c0]);
        return;
    }
    if (type == 42) // QTE RESULT
    {
        var bid2 = buffer_read(b, buffer_u16);
        var turn2 = buffer_read(b, buffer_u16);
        var slot = buffer_read(b, buffer_u8);
        var pts = mp_num(buffer_read(b, buffer_s16));
        ds_map_set(global.mp_qte, (turn2 * 4) + slot, pts);
        mp_log("qte recv turn=" + string(turn2) + " slot=" + string(slot) + " pts=" + string(pts));
        return;
    }
    if (type == 43) // HP
    {
        var slot2 = buffer_read(b, buffer_u8);
        var chr = buffer_read(b, buffer_u8);
        var hp = mp_num(buffer_read(b, buffer_s16));
        if (mp_battle_on() && slot2 < 3 && global.char[slot2] == chr && global.mp_owner[slot2] == from)
        {
            global.mp_rhp[slot2] = hp;
            global.mp_rhp_known[slot2] = 1;
        }
        return;
    }
    if (type == 44) // TURN DONE (host collects)
    {
        var bid3 = buffer_read(b, buffer_u16);
        var turn3 = buffer_read(b, buffer_u16);
        var gain = buffer_read(b, buffer_f64);
        // (Everyone keeps this: anyone may have to take over as the fight's leader.)
        global.mp_tdone_bid[from] = bid3;
        global.mp_tdone_turn[from] = turn3;
        global.mp_tdone_gain[from] = gain;
        global.mp_b_mask |= (1 << from);
        // Ready for a turn that was already released: a late joiner. They'll enter at
        // the next TURN_GO, so nobody waits for them until then.
        global.mp_tdone_late[from] = global.mp_b_active && bid3 == global.mp_bid && turn3 <= global.mp_tgo_sent;
        return;
    }
    if (type == 46) // GAME OVER: the party was wiped in someone's game
    {
        var bid4 = buffer_read(b, buffer_u16);
        if (mp_battle_on() && bid4 == global.mp_bid && !global.mp_gameover)
        {
            mp_log("remote game over from " + string(from));
            mp_hold_end();
            mp_wipe_mark();
            global.mp_gameover = 1;
            scr_gameover();
        }
        return;
    }
    if (type == 45) // TURN GO
    {
        var st = [];
        st[0] = buffer_read(b, buffer_u16);
        st[1] = buffer_read(b, buffer_u16);
        st[2] = buffer_read(b, buffer_f64);
        for (var s = 0; s < 3; s++)
        {
            st[3 + s] = buffer_read(b, buffer_u8);
            st[6 + s] = mp_num(buffer_read(b, buffer_s16));
            st[9 + s] = buffer_read(b, buffer_f64);
            st[12 + s] = buffer_read(b, buffer_f64);
            st[15 + s] = buffer_read(b, buffer_u8);
        }
        st[18] = buffer_read(b, buffer_f64);
        for (var s3 = 0; s3 < 3; s3++)
            st[19 + s3] = buffer_read(b, buffer_u8);
        st[22] = buffer_read(b, buffer_u8);
        if (mp_battle_on() && st[0] == global.mp_bid)
        {
            global.mp_tgo_pending = st;
            global.mp_tgo_sent = max(global.mp_tgo_sent, st[1]);
            global.mp_b_mask = st[22];
        }
        return;
    }
}

// st: [bid, turn, tension, owner0..2, hp0..2, monsterhp0..2, mercy0..2, present0..2]
function mp_apply_tgo(st)
{
    var turn = st[1];
    mp_log("tgo turn=" + string(turn) + " waiting=" + string(global.mp_bwait) + "/" + string(global.mp_bwait_turn) + " alive=" + string(st[15]) + string(st[16]) + string(st[17]) + " mine=" + string(global.monster[0]) + string(global.monster[1]) + string(global.monster[2]));
    if (!global.mp_bwait || turn < global.mp_bwait_turn)
        return;
    for (var s = 0; s < 3; s++)
        global.mp_owner[s] = st[3 + s];
    // Someone walked up and joined: their hero steps in, here too.
    if (mp_open_fight())
    {
        for (var s9 = 0; s9 < 3; s9++)
        {
            if (global.char[s9] == 0 && st[19 + s9] != 0)
                mp_battle_add_hero(s9, st[19 + s9]);
        }
    }
    mp_susie_update();
    if (turn > 0)
    {
        global.tension = st[2];
        for (var s2 = 0; s2 < 3; s2++)
        {
            var c = global.char[s2];
            if (c > 0 && global.mp_owner[s2] != global.mp_myid)
            {
                global.mp_rhp[s2] = st[6 + s2];
                global.mp_rhp_known[s2] = 1;
            }
            if (global.monster[s2])
            {
                global.monsterhp[s2] = st[9 + s2];
                global.mercymod[s2] = st[12 + s2];
                // The host already beat this enemy: remove it here too.
                if (!st[15 + s2])
                    mp_ch_remove_monster(s2);
            }
        }
        mp_battle_apply_hp();
    }
    global.mp_bturn = turn;
    global.mp_bgo = turn;
    global.mp_bwait = 0;
    global.mp_mn = 0;
    global.mp_mn_last = global.mp_frame - 30;
    global.mp_mn_pend = 0;
    // Drop menu inputs from older turns.
    for (var i = ds_list_size(global.mp_minq) - 1; i >= 0; i--)
    {
        var e = ds_list_find_value(global.mp_minq, i);
        if (e[1] < turn || e[0] != global.mp_bid)
            ds_list_delete(global.mp_minq, i);
    }
    mp_battle_seed(0);
    if (turn > 0)
    {
        global.mp_bgate_open = 1;
        with (obj_battlecontroller)
        {
            reset = 0;
            alarm[2] = -1;
            scr_mnendturn();
        }
        global.mp_bgate_open = 0;
    }
}

// Host: release the next turn once every participant reached the barrier.
function mp_host_turn_check()
{
    if (!mp_b_lead() || !global.mp_bwait)
        return;
    var t = global.mp_bwait_turn;
    if (t <= global.mp_tgo_sent)
        return; // already released: starts at its timed moment
    var waited = current_time - global.mp_bwait_since;
    var ready = true;
    for (var i = 0; i < 8; i++)
    {
        if (i == global.mp_myid || !global.mp_pconn[i] || !mp_in_mask(i))
            continue;
        if (global.mp_tdone_bid[i] == global.mp_bid && (global.mp_tdone_turn[i] >= t || global.mp_tdone_late[i]))
            continue;
        if (t == 0)
        {
            // Give everyone a moment to arrive at the start of a battle.
            if (waited < 12000 && (global.mp_pstate[i] & 1) == 0 && waited > 4000)
                continue;
            if (waited < 12000)
                ready = false;
        }
        else
        {
            // Only wait for players that actually joined this battle and are still in it.
            // Late joiners (not present for the previous turn) get pulled in by this TURN_GO.
            if (global.mp_tdone_bid[i] != global.mp_bid)
                continue;
            if (global.mp_tdone_late[i])
                continue;
            if ((global.mp_pstate[i] & 1) == 0 && (current_time - global.mp_ppostime[i]) < 5000 && waited > 3000)
                continue;
            if (waited < 60000)
                ready = false;
        }
    }
    if (!ready)
        return;
    mp_party_grow();
    mp_compute_owners();
    var tension = global.tension;
    if (t > 0)
    {
        // (My game already shows everyone's TP live, mp_tp_tick: start over from the phase's start
        // with each player's final count, so a lost live update can't stay wrong.)
        tension = global.mp_tension_b0 + global.mp_t_mine;
        for (var j = 0; j < 8; j++)
        {
            if (j != global.mp_myid && global.mp_pconn[j] && global.mp_tdone_bid[j] == global.mp_bid && global.mp_tdone_turn[j] == t)
                tension += global.mp_tdone_gain[j];
        }
        tension = clamp(tension, 0, global.maxtension);
    }
    var st = [];
    st[0] = global.mp_bid;
    st[1] = t;
    st[2] = tension;
    mp_begin_b(45);
    mp_wu16(global.mp_bid);
    mp_wu16(t);
    mp_wf64(tension);
    for (var s = 0; s < 3; s++)
    {
        var c = global.char[s];
        var hp = 0;
        if (c > 0)
            hp = global.hp[c];
        st[3 + s] = global.mp_owner[s];
        st[6 + s] = hp;
        st[9 + s] = global.monsterhp[s];
        st[12 + s] = global.mercymod[s];
        st[15 + s] = global.monster[s];
        mp_wu8(st[3 + s]);
        mp_ws16(st[6 + s]);
        mp_wf64(st[9 + s]);
        mp_wf64(st[12 + s]);
        mp_wu8(st[15 + s]);
    }
    st[18] = mp_clock_now() + mp_timing_lead();
    mp_wf64(st[18]);
    for (var s4 = 0; s4 < 3; s4++)
    {
        st[19 + s4] = global.char[s4];
        mp_wu8(global.char[s4]);
    }
    st[22] = global.mp_b_mask;
    mp_wu8(global.mp_b_mask);
    mp_send();
    global.mp_tgo_sent = t;
    for (var k = 0; k < 8; k++)
        global.mp_tdone_late[k] = 0;
    global.mp_tgo_pending = st;
}

// ---------------------------------------------------------------- per-frame

// Runs right after input sampling (before any game Step event).
function mp_battle_input()
{
    if (!mp_battle_on())
        return;
    // A new phase: wait for the others, frozen, before anything of it runs.
    if (mp_phase_gate_check())
    {
        mp_ui_block();
        return;
    }
    // Seed the enemy's turn identically everywhere.
    if (global.mnfight != global.mp_prev_mnfight)
    {
        if (global.mnfight == 1)
            mp_battle_seed(2);
        if (global.mnfight == 2)
        {
            mp_battle_seed(3);
            global.mp_tension_b0 = global.tension;
            mp_tp_phase_start();
        }
        global.mp_prev_mnfight = global.mnfight;
    }
    // Each hero's action (ACT, spell, attack...) starts from the same random state everywhere:
    // some ACTs roll dice after text that takes a different time to read for each player.
    if (global.myfight == 1 && (global.myfight != global.mp_prev_myfight || global.charturn != global.mp_prev_charturn))
        mp_battle_seed(10 + global.charturn);
    // ...and again each time one of its text boxes opens or closes: an ACT that rolls once its
    // text is read rolls the same everywhere, however long each player took to read it.
    var acting = global.myfight != 0 && global.mnfight == 0;
    var wr = acting && instance_exists(obj_writer);
    if (acting && global.myfight != global.mp_prev_myfight)
        global.mp_act_wn = 0;
    if (acting && wr != global.mp_act_wr)
    {
        global.mp_act_wn += 1;
        mp_battle_seed(20 + global.charturn + (global.mp_act_wn * 3));
    }
    global.mp_act_wr = wr;
    global.mp_prev_myfight = global.myfight;
    global.mp_prev_charturn = global.charturn;
    // Waiting for everyone at the end of a turn: nobody acts in their own game meanwhile,
    // whatever state the battle is in (e.g. an intro that opened the menu early).
    if (global.mp_bwait || global.mp_bgo < global.mp_bturn)
    {
        mp_ui_block();
        return;
    }
    // Spectating: the hidden SOUL takes no input (a yellow SOUL could still shoot, for one).
    if (mp_spectating() && instance_exists(obj_heart))
    {
        mp_ui_block();
        return;
    }
    var menu = global.myfight == 0 && global.mnfight == 0 && global.charturn < 3;
    if (!menu)
        return;
    mp_susie_lock();
    var owner = global.mp_owner[global.charturn];
    if (owner == global.mp_myid)
    {
        if (global.bmenuno == 0 && !mp_presel_ok(global.charturn, global.bmenucoord[0][global.charturn]))
            global.bmenucoord[0][global.charturn] = 0;
        var mask = 0;
        for (var i = 0; i < 10; i++)
        {
            if (global.input_pressed[i])
                mask |= (1 << i);
        }
        // The menu ignores presses for a few frames after the previous one. A press that
        // early would be ignored here but could land in time in the others' replay (which
        // can only be later), so hold it back until it is safely accepted everywhere.
        // Likewise while the menu itself still ignores presses (its onebuffer/twobuffer countdowns,
        // e.g. on the first frames of a turn): a press the menu drops here would count elsewhere.
        if ((global.mp_frame - global.mp_mn_last) < 5 || !mp_menu_ready())
        {
            if (mask != 0)
            {
                global.mp_mn_pend = mask;
                mp_ui_block();
            }
            return;
        }
        if (mask == 0 && global.mp_mn_pend != 0)
        {
            mask = global.mp_mn_pend;
            for (var i2 = 0; i2 < 10; i2++)
            {
                if ((mask >> i2) & 1)
                {
                    global.input_pressed[i2] = 1;
                    global.input_held[i2] = 1;
                }
            }
        }
        global.mp_mn_pend = 0;
        if (mask != 0)
        {
            var dt = min(30, global.mp_frame - global.mp_mn_last);
            mp_begin_b(41);
            mp_wu16(global.mp_bid);
            mp_wu16(global.mp_bturn);
            mp_wu16(global.mp_mn);
            mp_wu8(dt);
            mp_wu16(mask);
            // (Where the main-row bar is before this press: it can have been moved before my turn.)
            mp_wu8(global.bmenuno == 0 ? global.bmenucoord[0][global.charturn] : 255);
            mp_send();
            mp_log("menu send n=" + string(global.mp_mn) + " mask=" + string(mask) + " ct=" + string(global.charturn) + " bm=" + string(global.bmenuno));
            global.mp_mn += 1;
            global.mp_mn_last = global.mp_frame;
        }
        return;
    }
    // Someone else is choosing: replay their presses in order, with their original spacing. Meanwhile
    // I can already move the bar of my hero who comes next (mp_presel_input).
    global.mp_mn_pend = 0;
    mp_presel_input();
    mp_ui_block();
    for (var k = 0; k < ds_list_size(global.mp_minq); k++)
    {
        var e = ds_list_find_value(global.mp_minq, k);
        if (e[0] == global.mp_bid && e[1] == global.mp_bturn && e[2] == global.mp_mn)
        {
            if ((global.mp_frame - global.mp_mn_last) >= e[3] && mp_menu_ready())
            {
                if (array_length(e) > 5 && e[5] != 255 && global.bmenuno == 0)
                    global.bmenucoord[0][global.charturn] = e[5];
                for (var j = 0; j < 10; j++)
                {
                    var on = (e[4] >> j) & 1;
                    global.input_pressed[j] = on;
                    global.input_held[j] = on;
                }
                ds_list_delete(global.mp_minq, k);
                mp_log("menu apply n=" + string(global.mp_mn) + " mask=" + string(e[4]) + " ct=" + string(global.charturn) + " bm=" + string(global.bmenuno));
                global.mp_mn += 1;
                global.mp_mn_last = global.mp_frame;
            }
            break;
        }
    }
}

// ---------------------------------------------------------------- choosing ahead

// My hero who chooses after the current one this turn (-1 none).
function mp_presel_slot()
{
    for (var s = global.charturn + 1; s < 3; s++)
    {
        if (global.char[s] != 0 && global.mp_owner[s] == global.mp_myid && global.hp[global.char[s]] > 0)
            return s;
    }
    return -1;
}

// Can the main-row option b be picked for slot s? (ITEM is greyed out with an empty bag.)
function mp_presel_ok(s, b)
{
    if (b != 2)
        return true;
    var ok = true;
    with (obj_battlecontroller)
    {
        if (variable_instance_exists(id, "tempitem") && is_array(tempitem) && tempitem[0][s] == 0)
            ok = false;
    }
    return ok;
}

// While someone else chooses: left/right move my next hero's bar (only the bar: Z does nothing
// until it's my turn). The bar's position reaches the others with my first press then.
function mp_presel_input()
{
    var s = mp_presel_slot();
    global.mp_presel = s;
    if (s < 0)
        return;
    var d = 0;
    if (global.input_pressed[1])
        d = 1;
    if (global.input_pressed[3])
        d = -1;
    var b = global.bmenucoord[0][s];
    if (d != 0)
    {
        for (var t = 0; t < 5; t++)
        {
            b = (b + d + 5) mod 5;
            if (mp_presel_ok(s, b))
                break;
        }
        global.bmenucoord[0][s] = b;
        mp_log("choose ahead: slot " + string(s) + " bar " + string(b));
        mp_presel_send(s);
        var snd = asset_get_index("snd_menumove");
        if (snd >= 0)
            snd_play(snd);
    }
    else if (!mp_presel_ok(s, b))
        global.bmenucoord[0][s] = 0;
}

function mp_presel_send(s)
{
    mp_begin_b(54);
    mp_wu16(global.mp_bturn);
    mp_wu8(s);
    mp_wu8(global.bmenucoord[0][s]);
    mp_send();
}

// The others' bars while they wait for their turn, for the status line ("" none).
function mp_presel_others()
{
    var t = "";
    for (var s = global.charturn + 1; s < 3; s++)
    {
        var o = global.mp_owner[s];
        if (global.char[s] == 0 || o == global.mp_myid || o >= 8 || !global.mp_pconn[o] || global.hp[global.char[s]] <= 0)
            continue;
        t += "  " + global.mp_pname[o] + ": " + mp_presel_name(s);
    }
    return t;
}

function mp_presel_name(s)
{
    var b = global.bmenucoord[0][s];
    var c = global.char[s];
    switch (b)
    {
        case 0:
            return "FIGHT";
        case 1:
            return c == 1 ? "ACT" : "MAGIC";
        case 2:
            return "ITEM";
        case 3:
            return "SPARE";
        case 4:
            return "DEFEND";
    }
    return "?";
}

// The battle menu takes a press this frame (it ignores them while its countdowns run).
function mp_menu_ready()
{
    var ok = true;
    with (obj_battlecontroller)
    {
        if (variable_instance_exists(id, "onebuffer") && (onebuffer >= 0 || twobuffer >= 0))
            ok = false;
    }
    return ok;
}

function mp_battle_tick()
{
    if (mp_b_lead() && global.mp_bwait)
    {
        var bn = mp_bwait_names();
        if ((global.mp_frame mod 30) == 0 || bn != global.mp_bwait_names_sent)
        {
            global.mp_bwait_names_sent = bn;
            mp_begin(35);
            mp_wu16(global.mp_gid);
            mp_wstr(bn);
            mp_send();
        }
    }
    if (global.mp_b_active && !instance_exists(obj_battlecontroller))
        mp_battle_ended();
    // Nobody we follow is fighting: drop anything buffered from a battle we never joined.
    if (!global.mp_b_active && !mp_in_battle_scene() && global.mp_gid == 0 && !is_array(global.mp_pull))
    {
        if (ds_list_size(global.mp_minq) > 0 || ds_map_size(global.mp_qte) > 0)
            mp_battle_clear_buffers();
        global.mp_tgo_stash = -1;
    }
    if (!mp_battle_on())
        return;
    mp_stand_in_tick();
    mp_host_turn_check();
    mp_gate_host_tick();
    mp_client_gate_fallback();
    mp_battle_send_hp();
    mp_battle_apply_hp();
}

// Broadcast HP of the heroes I play whenever it changes.
function mp_battle_send_hp()
{
    for (var s = 0; s < 3; s++)
    {
        var c = global.char[s];
        if (c <= 0 || global.mp_owner[s] != global.mp_myid)
            continue;
        if (global.hp[c] != global.mp_hp_sent[s])
        {
            global.mp_hp_sent[s] = global.hp[c];
            mp_log("hp send slot=" + string(s) + " hp=" + string(global.hp[c]) + " mnfight=" + string(global.mnfight));
            mp_begin_b(43);
            mp_wu8(s);
            mp_wu8(c);
            mp_ws16(global.hp[c]);
            mp_send();
        }
    }
}

// Brings remote heroes' HP in line with what their players report.
function mp_battle_apply_hp()
{
    var changed = false;
    for (var s = 0; s < 3; s++)
    {
        var c = global.char[s];
        if (c <= 0 || global.mp_owner[s] == global.mp_myid || global.mp_rhp_known[s] == 0)
            continue;
        // A hero someone else controls: each new report from their game is applied as is.
        // In between, my own copy of the battle may heal them the same way their game does
        // (that stands), but never hurt them below what they reported (a stray hit here).
        var old = global.hp[c];
        var nw = global.mp_rhp[s];
        if (global.mp_rhp_known[s] == 1)
            global.mp_rhp_known[s] = 2;
        else if (old >= nw)
            continue;
        if (old == nw)
            continue;
        global.hp[c] = nw;
        mp_log("hp apply slot=" + string(s) + " " + string(old) + "->" + string(nw) + " (" + typeof(nw) + ")");
        changed = true;
        var inst = global.charinstance[s];
        if (nw < old && instance_exists(inst))
        {
            with (inst)
            {
                hurt = 1;
                hurttimer = 0;
            }
            var dw = instance_create(inst.x, (inst.y + inst.myheight) - 24, obj_dmgwriter);
            dw.damage = old - nw;
            if (nw <= 0)
                dw.type = 4;
        }
        if (nw <= 0 && old > 0)
            scr_dead(s);
        if (nw > 0 && old <= 0)
            mp_ch_revive(s);
    }
    if (changed)
    {
        var alive = false;
        for (var s2 = 0; s2 < 3; s2++)
        {
            if (global.char[s2] != 0 && global.hp[global.char[s2]] > 0)
                alive = true;
        }
        if (!alive)
            scr_gameover();
    }
}

// Prepended to scr_damage: a bullet that hits my SOUL hurts the hero I play.
// Returns the slot to damage, or -1 if I play nobody in this battle.
function mp_damage_target(t)
{
    if (!mp_battle_on())
        return t;
    var mine = [];
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0 && global.mp_owner[s] == global.mp_myid)
            mine[array_length(mine)] = s;
    }
    var n = array_length(mine);
    if (n == 0)
        return -1;
    if (t == 3)
    {
        if (n == mp_party_size())
            return 3;
        t = mine[0];
    }
    for (var k = 0; k < n; k++)
    {
        if (mine[k] == t && global.hp[global.char[t]] > 0)
            return t;
    }
    // Prefer one of my heroes that is still standing. If all of mine are down, the hit is
    // absorbed: it must never spill over onto a hero another player controls.
    for (var k2 = 0; k2 < n; k2++)
    {
        if (global.hp[global.char[mine[k2]]] > 0)
            return mine[k2];
    }
    return -1;
}

function mp_party_size()
{
    var n = 0;
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0)
            n++;
    }
    return n;
}

// A SOUL that controls no standing hero was hit: it is hidden and spectating, so nothing happens.
// Called from scr_damage (self is usually the bullet). All my heroes are down: the hit costs the
// team twice the TP a graze of this bullet gives, with the usual invincibility after it.
function mp_damage_spectator()
{
    if (mp_soul_state() != 1 || global.inv >= 0)
        return;
    var g = 4;
    if (variable_instance_exists(id, "grazepoints") && is_real(grazepoints) && grazepoints > 0)
        g = grazepoints;
    var cost = min(2 * g, global.tension);
    global.tension -= cost;
    global.inv = global.invc * 40;
    global.mp_down_hit_f = global.mp_frame;
    global.mp_down_hit_n = cost;
    mp_log("down hit: tp -" + string(cost) + " -> " + string(global.tension));
    var snd = asset_get_index("snd_hurt1");
    if (snd >= 0)
        snd_play(snd);
}

// ---------------------------------------------------------------- attack timing (QTE)

function mp_qte_mine(slot)
{
    return mp_slot_mine(slot);
}

// Called before a hero's attack is triggered by obj_attackpress.
function mp_qte_report(slot, pts)
{
    mp_log("qte attack slot=" + string(slot) + " pts=" + string(pts) + " mine=" + string(mp_slot_mine(slot)));
    if (!mp_battle_on() || !mp_slot_mine(slot))
        return;
    mp_begin_b(42);
    mp_wu16(global.mp_bid);
    mp_wu16(global.mp_bturn);
    mp_wu8(slot);
    mp_ws16(pts);
    mp_send();
}

// Can a bolt of this slot run out (miss) locally? Remote players' bolts wait for their result.
function mp_qte_canexpire(slot)
{
    if (!mp_battle_on() || mp_slot_mine(slot))
        return true;
    return false;
}

// Called each frame inside obj_attackpress: applies remote players' attack results.
function mp_qte_apply()
{
    if (!mp_battle_on())
        return;
    if (global.mp_qte_since == 0 || (current_time - global.mp_qte_since) > 600000)
        global.mp_qte_since = current_time;
    var timeout = (current_time - global.mp_qte_since) > 20000;
    for (var s = 0; s < 3; s++)
    {
        if (mp_slot_mine(s) || havechar[s] == 0 || attacked[s] == 1)
            continue;
        var key = (global.mp_bturn * 4) + s;
        var have = ds_map_exists(global.mp_qte, key);
        if (have || timeout)
        {
            var pts = 0;
            if (have)
                pts = ds_map_find_value(global.mp_qte, key);
            points[s] = pts;
            for (var i = 0; i < bolttotal; i++)
            {
                if (boltchar[i] == s && boltalive[i] == 1)
                {
                    boltalive[i] = 0;
                    if (pts > 0)
                    {
                        var bb = instance_create((x + 80 + (boltframe[i] * boltspeed)) - (boltx * boltspeed), y + (38 * s), obj_burstbolt);
                        bb.image_blend = boltcolor[s];
                    }
                }
            }
        }
    }
}

function mp_qte_done()
{
    mp_log("attackpress created");
    global.mp_qte_since = 0;
}

function mp_qte_waiting_name()
{
    if (!instance_exists(obj_attackpress))
        return "";
    var nm = "";
    with (obj_attackpress)
    {
        for (var s = 0; s < 3; s++)
        {
            if (havechar[s] == 1 && attacked[s] == 0 && !mp_slot_mine(s) && (boltx - 40) > 0)
                nm = global.mp_pname[global.mp_owner[s]];
        }
    }
    return nm;
}

// Who the turn barrier is waiting for: computed by the host, sent to the others (type 35).
function mp_bwait_names()
{
    if (!mp_b_lead())
    {
        if ((current_time - global.mp_bwait_names_time) < 2500)
            return global.mp_bwait_names;
        return "";
    }
    var names = "";
    for (var i = 0; i < 8; i++)
    {
        if (i != global.mp_myid && global.mp_pconn[i] && mp_in_mask(i) && !(global.mp_tdone_bid[i] == global.mp_bid && global.mp_tdone_turn[i] >= global.mp_bwait_turn))
        {
            if (names != "")
                names += ", ";
            names += global.mp_pname[i];
        }
    }
    return names;
}

function mp_battle_status()
{
    if (!mp_battle_on())
        return "";
    if (global.mp_hold)
        return mp_timing_status();
    if (global.mp_bwait)
    {
        var names = mp_bwait_names();
        if (names != "")
            return "Waiting for " + names + "...";
        return "Waiting for other players...";
    }
    var q = mp_qte_waiting_name();
    if (q != "")
        return "Waiting for " + q + "'s attack...";
    if (mp_soul_state() == 1 && instance_exists(obj_heart))
    {
        return "You're down: keep dodging.";
    }
    if (global.myfight == 0 && global.mnfight == 0 && global.charturn < 3)
    {
        var o = global.mp_owner[global.charturn];
        var cn = mp_char_name(global.char[global.charturn]);
        if (o == global.mp_myid)
            return "Your turn: choose " + cn + "'s action!" + mp_presel_others();
        if (o < 8 && global.mp_pconn[o])
        {
            var ps = mp_presel_slot();
            if (ps >= 0)
                return global.mp_pname[o] + " is choosing for " + cn + ". Your " + mp_char_name(global.char[ps]) + ": < " + mp_presel_name(ps) + " > (Z on your turn)" + mp_presel_others();
            return global.mp_pname[o] + " is choosing for " + cn + "..." + mp_presel_others();
        }
    }
    if (mp_my_slot_count() == 0)
    {
        for (var s = 0; s < 3; s++)
        {
            var o2 = global.mp_owner[s];
            if (global.char[s] == global.mp_cfg_char && o2 < 8 && o2 != global.mp_myid && global.mp_pconn[o2])
                return "Watching " + global.mp_pname[o2] + ", who plays " + mp_char_name(global.mp_cfg_char) + ". You take over if they change character or leave.";
        }
        return "Watching: " + mp_char_name(global.mp_cfg_char) + " is not in this battle. No need to dodge.";
    }
    if (mp_soul_state() == 1)
        return "You're down: you'll be back when you're revived.";
    return "";
}

// How many party slots I control in this battle (0: I only watch).
function mp_my_slot_count()
{
    var mine = 0;
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0 && global.mp_owner[s] == global.mp_myid)
            mine++;
    }
    return mine;
}

// An enemy the host already defeated/spared is still here (desync): defeat it locally.
function mp_ch_remove_monster(s)
{
    mp_log("removing desynced enemy " + string(s));
    if (instance_exists(global.monsterinstance[s]))
    {
        with (global.monsterinstance[s])
            scr_monsterdefeat();
    }
    global.monster[s] = 0;
}

// Prepended to scr_gameover: everyone in this battle goes down together.
function mp_on_gameover()
{
    if (!variable_global_exists("mp_inited") || !mp_battle_on() || global.mp_gameover)
        return;
    global.mp_gameover = 1;
    mp_wipe_mark();
    mp_battle_send_hp();
    mp_begin_b(46);
    mp_wu16(global.mp_bid);
    mp_send();
    mp_flush();
}

// Client: if the host is no longer in this battle, stop waiting and carry on alone.
function mp_client_gate_fallback()
{
    if (mp_b_lead() || !global.mp_bwait || is_array(global.mp_tgo_pending))
        return;
    var waited = current_time - global.mp_bwait_since;
    if (waited > 90000)
    {
        mp_hold_end();
        mp_log("the fight's leader stopped answering; continuing alone");
        mp_notify("The fight's leader stopped answering - continuing on your own.");
        for (var s = 0; s < 3; s++)
            global.mp_owner[s] = global.mp_myid;
        var st = [global.mp_bid, global.mp_bwait_turn, global.tension];
        for (var s2 = 0; s2 < 3; s2++)
        {
            st[3 + s2] = global.mp_myid;
            st[6 + s2] = 0;
            if (global.char[s2] > 0)
                st[6 + s2] = global.hp[global.char[s2]];
            st[9 + s2] = global.monsterhp[s2];
            st[12 + s2] = global.mercymod[s2];
            st[15 + s2] = global.monster[s2];
        }
        global.mp_b_active = 0;
        global.mp_bwait = 1;
        global.mp_bgate_open = 1;
        with (obj_battlecontroller)
        {
            reset = 0;
            alarm[2] = -1;
            scr_mnendturn();
        }
        global.mp_bgate_open = 0;
        global.mp_bwait = 0;
    }
}

// Starts global.encounterno exactly like an overworld enemy would (same music choice and
// "!" horn intro in every chapter) by spawning an invisible enemy that was just touched.
function mp_battle_force_start()
{
    var px = 0;
    var py = 0;
    if (instance_exists(obj_mainchara))
    {
        px = obj_mainchara.x;
        py = obj_mainchara.y;
    }
    global.interact = 0;
    var e = instance_create(px, py, obj_testoverworldenemy);
    e.visible = 0;
    e.speed = 0;
    with (e)
        event_user(0);
}

function mp_ch_revive(slot)
{
    scr_revive(slot);
}

// 0: I have a hero standing in this battle. 1: all my heroes are down. 2: I play nobody in it.
function mp_soul_state()
{
    if (!variable_global_exists("mp_inited") || !mp_battle_on())
        return 0;
    var mine = 0;
    var up = 0;
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0 && global.mp_owner[s] == global.mp_myid)
        {
            mine++;
            if (global.hp[global.char[s]] > 0)
                up++;
        }
    }
    if (mine == 0)
        return 2;
    return up > 0 ? 0 : 1;
}

// (A player whose heroes are all down keeps their SOUL: it dodges, grazes for TP and loses TP when
// hit, mp_damage_spectator. Only a player with no hero in the fight watches.)
function mp_spectating()
{
    return mp_soul_state() == 2;
}

// Does player i play heroes in this fight that are all down?
function mp_player_down(i)
{
    var mine = 0;
    var up = 0;
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0 && global.mp_owner[s] == i)
        {
            mine++;
            if (global.hp[global.char[s]] > 0)
                up++;
        }
    }
    return mine > 0 && up == 0;
}

// ---------------------------------------------------------------- live TP

// Drawn after the TP bar (obj_tensionbar's Draw): when TP is lost in a fight, the bar flashes
// white and shakes for a moment. (The game's own red bar under the orange one already shows how
// much went, shrinking after a short pause.)
function mp_tp_bar_fx()
{
    if (!mp_on() || !variable_global_exists("mp_tp_flash_f"))
        return;
    var age = global.mp_frame - global.mp_tp_flash_f;
    if (age < 0 || age >= 12)
        return;
    var a = 0.75 * (1 - age / 12);
    var dx = (age < 6) ? ((age mod 2) == 0 ? 2 : -2) : 0;
    var oa = draw_get_alpha();
    var oc = draw_get_colour();
    draw_set_alpha(a);
    draw_set_colour(c_white);
    var w = sprite_get_width(spr_tensionbar);
    var h = sprite_get_height(spr_tensionbar);
    draw_rectangle(x + dx, y, x + dx + w - 1, y + h - 1, false);
    draw_set_alpha(oa);
    draw_set_colour(oc);
}

function mp_tp_phase_start()
{
    global.mp_t_mine = 0;
    global.mp_t_shown = global.tension;
    global.mp_t_sent = -99999;
    for (var i = 0; i < 8; i++)
    {
        global.mp_t_remote[i] = 0;
        global.mp_t_rturn[i] = -1;
    }
}

// During the bullet phase, every frame: whatever my own game changed in TP (my grazes, my hits
// while down) is mine; the bar shows the phase's start plus everyone's gains, so TP goes up and
// down for all players as it happens. At the turn's end the leader's count settles it.
function mp_tp_tick()
{
    if (!mp_battle_on() || global.mnfight != 2 || global.mp_bwait)
        return;
    var d = global.tension - global.mp_t_shown;
    // Down: a hit costs TP, and for a moment after it grazes give none (the same bullet would
    // otherwise pay part of it back at once).
    if (d > 0 && mp_soul_state() == 1 && (global.mp_frame - global.mp_down_hit_f) < 45)
        d = 0;
    global.mp_t_mine += d;
    var t = global.mp_tension_b0 + global.mp_t_mine;
    for (var i = 0; i < 8; i++)
    {
        if (i != global.mp_myid && global.mp_pconn[i] && global.mp_t_rturn[i] == global.mp_bturn)
            t += global.mp_t_remote[i];
    }
    var before = global.mp_t_shown;
    global.tension = clamp(t, 0, global.maxtension);
    global.mp_t_shown = global.tension;
    // TP lost (anyone's hit while down): the bar flashes and shakes (mp_tp_bar_fx).
    if (global.tension < before - 0.5)
        global.mp_tp_flash_f = global.mp_frame;
    if ((global.mp_t_sent != global.mp_t_mine || (global.mp_frame - global.mp_t_sent_f) > 15) && (global.mp_frame - global.mp_t_sent_f) >= 2)
    {
        mp_begin_b(53);
        mp_wu16(global.mp_bturn);
        mp_wf64(global.mp_t_mine);
        mp_send();
        global.mp_t_sent = global.mp_t_mine;
        global.mp_t_sent_f = global.mp_frame;
    }
}

// Spectating: my SOUL is hidden and takes no input or hits and earns no TP, and sits where the
// player I'm watching is, so that bullets aiming at "the SOUL" in my game aim at them.
function mp_spectate_tick(spec)
{
    if (spec != global.mp_spec_on)
    {
        global.mp_spec_on = spec;
        mp_log(spec ? "spectating" : "back from spectating");
        with (obj_heart)
        {
            if (spec)
                global.mp_spec_alpha = image_alpha;
            else
                image_alpha = global.mp_spec_alpha;
        }
        with (obj_grazebox)
            visible = !spec;
    }
    if (!spec)
        return;
    global.mp_spec_target = -1;
    // Whoever plays my character, when they have a SOUL; otherwise anyone who has one.
    var mc = mp_char_controller(global.mp_pchar[global.mp_myid]);
    if (mc >= 0 && mc != global.mp_myid && (global.mp_frame - global.mp_soul_f[mc]) <= 15)
        global.mp_spec_target = mc;
    for (var i = 0; i < 8 && global.mp_spec_target < 0; i++)
    {
        if (i != global.mp_myid && global.mp_pconn[i] && (global.mp_frame - global.mp_soul_f[i]) <= 15)
            global.mp_spec_target = i;
    }
    with (obj_heart)
    {
        image_alpha = 0;
        if (global.mp_spec_target >= 0)
        {
            x = global.mp_soul_tx[global.mp_spec_target];
            y = global.mp_soul_ty[global.mp_spec_target];
        }
    }
}

// While I have a SOUL in a battle, tell the others where it is.
function mp_soul_tick()
{
    mp_tp_tick();
    if (!mp_battle_on() || !instance_exists(obj_heart))
    {
        global.mp_soul_seen = 0;
        global.mp_spec_on = false;
        return;
    }
    var spec = mp_spectating();
    mp_spectate_tick(spec);
    if (spec)
        return;
    if (!global.mp_soul_seen)
    {
        // Logged so the bullet phase's start can be compared between players.
        global.mp_soul_seen = 1;
        if (variable_global_exists("mp_test_ws"))
            mp_log("soul phase start turn=" + string(global.mp_bturn) + " wc=" + string_format(global.mp_test_ws - ((global.mp_test_wb - current_time) / 1000), 1, 3));
    }
    if ((global.mp_frame mod 2) != 0)
        return;
    mp_begin_b(47);
    mp_ws16(obj_heart.x);
    mp_ws16(obj_heart.y);
    mp_send();
}

// The colour of a character's SOUL. Deep shades on purpose: mid-tones can come out much brighter on
// some screens (seen on an HDR monitor), and these stay purple and green either way.
function mp_soul_color(c)
{
    switch (c)
    {
        case 2:
            return make_color_rgb(110, 35, 170); // Susie: purple
        case 3:
            return make_color_rgb(0, 170, 60); // Ralsei: green
        case 4:
            return make_color_rgb(255, 238, 112); // Noelle: yellow
    }
    return make_color_rgb(255, 0, 0); // Kris: red, as in the normal game
}

// A copy of a SOUL sprite in a character's colour, made once from the game's own sprite. Only the
// red pixels change, so size, shape, outline and frames stay exactly as they are, and SOULs that
// aren't red (a yellow SOUL, for one) keep their colour.
function mp_soul_sprite(spr, c)
{
    if (c <= 1)
        return spr;
    if (!variable_global_exists("mp_soul_sprs"))
        global.mp_soul_sprs = ds_map_create();
    var key = string(spr) + ":" + string(c);
    if (ds_map_exists(global.mp_soul_sprs, key))
        return ds_map_find_value(global.mp_soul_sprs, key);
    var w = sprite_get_width(spr);
    var h = sprite_get_height(spr);
    var xo = sprite_get_xoffset(spr);
    var yo = sprite_get_yoffset(spr);
    var col = mp_soul_color(c);
    var cr = color_get_red(col);
    var cg = color_get_green(col);
    var cb = color_get_blue(col);
    var surf = surface_create(w, h);
    var buf = buffer_create(w * h * 4, buffer_fixed, 1);
    var out = -1;
    // Which byte of a pixel is red depends on the platform: draw red and see where it lands.
    surface_set_target(surf);
    draw_clear_alpha(c_red, 1);
    surface_reset_target();
    buffer_get_surface(buf, surf, 0);
    var ri = buffer_peek(buf, 0, buffer_u8) > 128 ? 0 : 2;
    var bi = 2 - ri;
    for (var f = 0; f < sprite_get_number(spr); f++)
    {
        surface_set_target(surf);
        draw_clear_alpha(c_black, 0);
        draw_sprite(spr, f, xo, yo);
        surface_reset_target();
        buffer_get_surface(buf, surf, 0);
        for (var p = 0; p < (w * h * 4); p += 4)
        {
            var pr = buffer_peek(buf, p + ri, buffer_u8);
            var pg = buffer_peek(buf, p + 1, buffer_u8);
            var pb = buffer_peek(buf, p + bi, buffer_u8);
            if (pr > (pg + 30) && pr > (pb + 30))
            {
                buffer_poke(buf, p + ri, buffer_u8, floor((cr * pr) / 255));
                buffer_poke(buf, p + 1, buffer_u8, floor((cg * pr) / 255));
                buffer_poke(buf, p + bi, buffer_u8, floor((cb * pr) / 255));
            }
        }
        buffer_set_surface(buf, surf, 0);
        if (out < 0)
            out = sprite_create_from_surface(surf, 0, 0, w, h, false, false, xo, yo);
        else
            sprite_add_from_surface(out, surf, 0, 0, w, h, false, false);
    }
    buffer_delete(buf);
    surface_free(surf);
    ds_map_set(global.mp_soul_sprs, key, out);
    mp_log("made a SOUL sprite for character " + string(c) + " from " + sprite_get_name(spr) + " (" + string(w) + "x" + string(h) + ", " + string(sprite_get_number(spr)) + " frames)");
    return out;
}

// Appended to obj_heart's Draw: the other players' SOULs, in their character's colour with their
// name, then my own over them (in my character's colour, if it's the plain red SOUL).
function mp_heart_draw_others()
{
    if (!variable_global_exists("mp_inited") || !mp_battle_on())
        return;
    var of = draw_get_font();
    var oh = draw_get_halign();
    var ov = draw_get_valign();
    var oc = draw_get_color();
    var oa = draw_get_alpha();
    if (global.mp_font_small >= 0)
        draw_set_font(global.mp_font_small);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_alpha(1);
    for (var i = 0; i < 8; i++)
    {
        if (!global.mp_cfg_souls)
            break;
        if (i == global.mp_myid || !global.mp_pconn[i] || (global.mp_frame - global.mp_soul_f[i]) > 15)
            continue;
        global.mp_soul_x[i] += (global.mp_soul_tx[i] - global.mp_soul_x[i]) * 0.4;
        global.mp_soul_y[i] += (global.mp_soul_ty[i] - global.mp_soul_y[i]) * 0.4;
        // Whole pixels, like the real SOUL: in-between positions would look blurred.
        var sx = round(global.mp_soul_x[i]);
        var sy = round(global.mp_soul_y[i]);
        var col = mp_soul_color(global.mp_pchar[i]);
        draw_sprite_ext(mp_soul_sprite(sprite_index, global.mp_pchar[i]), 0, sx, sy, image_xscale, image_yscale, 0, mp_player_down(i) ? mp_down_blend() : c_white, 1);
        var label = string_copy(global.mp_pname[i], 1, 8);
        draw_text_transformed_color(sx + 9 + 1, sy - 4 + 1, label, 1, 1, 0, c_black, c_black, c_black, c_black, 1);
        draw_text_transformed_color(sx + 9, sy - 4, label, 1, 1, 0, col, col, col, col, 1);
    }
    draw_set_font(of);
    draw_set_halign(oh);
    draw_set_valign(ov);
    draw_set_color(oc);
    draw_set_alpha(oa);
    // color 0 is the normal SOUL (the other colours are special modes the game draws in its own way;
    // Chapter 1 only has the normal one and no such variable).
    if (!global.mp_spec_on && (!variable_instance_exists(id, "color") || color == 0))
        draw_sprite_ext(mp_soul_sprite(sprite_index, global.mp_pchar[global.mp_myid]), image_index, x, y, image_xscale, image_yscale, image_angle, mp_soul_state() == 1 ? mp_down_blend() : c_white, image_alpha);
}

// A downed player's SOUL: their own colour, darker.
function mp_down_blend()
{
    return make_color_rgb(110, 110, 110);
}

// Prepended to scr_damage outside battles. HP is shared, so another player's hit can take one of
// my heroes to 0 HP without the game's own handling having run here. Outside battles the game
// never has a hero at 0 HP (that is a Game Over: scr_damage's target code looks for another
// hero, whose instance may not exist, and crashes), so when that has happened the Game Over
// is what has to run. Returns true then.
function mp_overworld_all_down()
{
    if (!variable_global_exists("mp_inited") || !mp_on() || mp_battle_on() || mp_in_battle_scene())
        return false;
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] != 0 && global.hp[global.char[s]] <= 0)
            return true;
    }
    return false;
}
