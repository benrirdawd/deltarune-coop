// Rhythm game together, part 1 (Chapter 3's band song): everyone plays the song in their own
// game. The player whose hero is Ralsei sings the vocal chart (three columns: Left/Z, Down or
// Up, Right/X), and Kris's guitar plays itself there, as the vocals do in the solo game. Kris's
// player plays as before. Not in the Tenna fight (that one is a shared battle).

// The instrument I play: 0 guitar (Kris, the game's own), 1 drums, 2 vocals, -1 none.
function mp_rhythm_my_part()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return 0;
    var c = global.mp_pchar[global.mp_myid];
    if (c == 3)
        return 2;
    if (c == 2)
        return 1;
    return 0;
}

// obj_rhythmgame Step (prepended).
function mp_rhythm_step()
{
    if (variable_instance_exists(id, "tenna_boss") && tenna_boss)
        return;
    // (Test token rhythmbot, for Kris's player: the guitar plays itself.)
    if (mp_rhythm_my_part() == 0 && variable_global_exists("mp_inited") && mp_test_has("rhythmbot"))
        auto_play = 1;
    var part = mp_rhythm_my_part();
    if (!variable_instance_exists(id, "vocals") || !instance_exists(vocals) || !variable_instance_exists(id, "drums") || !instance_exists(drums))
        return;
    // Susie's drums in the band song: a real part when someone plays Susie (in their game, by
    // their keys; in the others', on its own) instead of the story's failing drummer.
    if (song_id == 0 && (part == 1 || mp_char_controller(2) >= 0))
    {
        with (drums)
        {
            auto_play = (part != 1);
            fade = 1;
            con = -1;
            mash_hit = -1;
        }
    }
    if (part == 0)
        return;
    if (!variable_instance_exists(id, "mp_rh_set"))
    {
        mp_rh_set = 1;
        mp_log(part == 2 ? "rhythm: I sing the vocals, the guitar plays itself" : "rhythm: I play the drums, the guitar plays itself");
    }
    auto_play = 1;
    if (part == 2)
        vocals.auto_play = 0;
}

// Is this chart played by my keys?
function mp_rhythm_mine(ch)
{
    if (ch.auto_play || ch.instrument == 0)
        return false;
    if (!instance_exists(obj_rhythmgame) || obj_rhythmgame.tenna_boss)
        return false;
    return mp_rhythm_my_part() == ch.instrument;
}

function mp_rhythm_key(lane, held)
{
    var r = false;
    // (Test token rhythmbot: press each vocal note on time, hold the long ones.)
    if (mp_test_has("rhythmbot") && instance_exists(obj_rhythmgame))
    {
        var tp = obj_rhythmgame.trackpos;
        var mine = mp_rhythm_my_part();
        with (obj_rhythmgame_chart)
        {
            if (instrument != mine)
                continue;
            if (held && hold_end[lane] > 0 && tp < hold_end[lane])
                r = true;
            for (var k = minnote; k < maxnote && !r; k++)
            {
                if (notetime[k] - tp > 0.1)
                    break;
                if (notetype[k] == lane && notealive[k] == 1 && abs(notetime[k] - tp) < 0.04)
                    r = true;
            }
        }
        if (r && !held)
            mp_log("rhythm: key " + string(lane) + " (bot)");
        return r;
    }
    var drum = mp_rhythm_my_part() == 1;
    with (obj_rhythmgame)
    {
        // (Drums: the two pads Left/Z and Right/X, the bass bar across them Down or Up.)
        if (drum && lane == 1)
            r = held ? (buttonr_h() || right_h()) : (buttonr_p() || right_p());
        else if (drum && lane == 2)
            r = held ? (down_h() || up_h()) : (down_p() || up_p());
        else if (lane == 0)
            r = held ? (buttonb_h() || left_h()) : (buttonb_p() || left_p());
        else if (lane == 1)
            r = held ? (down_h() || up_h()) : (down_p() || up_p());
        else
            r = held ? (buttonr_h() || right_h()) : (buttonr_p() || right_p());
        if (lose_con == 2)
            r = false;
    }
    return r;
}

// A note hit by my keys: Ralsei sings it, as on autoplay; Susie strikes that drum and it sounds
// with the game's own snare.
function mp_rhythm_hit(ch, lane)
{
    if (!mp_rhythm_mine(ch))
        return;
    if (instance_exists(ch.performer))
    {
        if (ch.instrument == 2)
            ch.performer.sprite_index = ch.performer.mid;
        else
        {
            var sp = asset_get_index(lane == 0 ? "spr_susie_drum_play" : (lane == 1 ? "spr_susie_drum_play_right" : "spr_susie_drum_play_mid"));
            if (sp >= 0)
                ch.performer.sprite_index = sp;
            with (ch.performer)
                event_user(0);
            var sn = asset_get_index("rhythm_battle_snare");
            if (sn >= 0)
                snd_play_x(sn, 0.8, obj_rhythmgame.pitch);
        }
    }
    global.mp_rh_hits = (variable_global_exists("mp_rh_hits") ? global.mp_rh_hits : 0) + 1;
    mp_log("rhythm: " + (ch.instrument == 2 ? "vocal" : "drum") + " hit " + string(global.mp_rh_hits) + " score " + string(obj_rhythmgame.total_score));
}

// Chapter 3's band song (not the sound check before it) is playing here. It is not a shared
// scene: each player plays it in their own copy, so the others stop watching mine and their
// room's scene starts their own song (mp_cutscene_running, mp_mirror_after_check).
function mp_rhythm_song_on()
{
    var gs = asset_get_index("obj_ch3_GSB02");
    if (gs < 0 || !instance_exists(gs))
        return false;
    with (gs)
    {
        if (game_active && !sound_check)
            return true;
    }
    return false;
}

// ---------------------------------------------------------------- part 3: one band, one score
//
// Parts: 0 guitar (Kris), 1 drums (Susie), 2 vocals (Ralsei). Each part's score counts from the
// game of the player who plays it: in my game a part played by someone else adds nothing by
// itself (its autoplay gains are taken back) and what its player scored is added instead
// (message 88, every 15 frames). The game's fame meter, which decides the win at the end, is
// the guitar's: in the others' games it follows Kris's player's (and their quitting).

function mp_rhythm_owner(part)
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return -1;
    return mp_char_controller(part + 1);
}

function mp_rhythm_remote(part)
{
    var o = mp_rhythm_owner(part);
    return o >= 0 && o != global.mp_myid;
}

// obj_rhythmgame_chart Step (prepended) and just before its end.
function mp_rhythm_chart_pre()
{
    mp_rh_pre = instance_exists(obj_rhythmgame) ? obj_rhythmgame.total_score : 0;
}

function mp_rhythm_chart_post(ch)
{
    if (!variable_instance_exists(ch, "mp_rh_gain"))
        ch.mp_rh_gain = 0;
    ch.mp_rh_gain += obj_rhythmgame.total_score - ch.mp_rh_pre;
}

function mp_rhythm_recv(from, b)
{
    var part = buffer_read(b, buffer_u8);
    var sc = buffer_read(b, buffer_s32);
    var fm = buffer_read(b, buffer_f64);
    var lc = buffer_read(b, buffer_u8);
    if (part > 2 || mp_rhythm_owner(part) != from)
        return;
    if (!is_array(global.mp_rh_rem))
        global.mp_rh_rem = [0, 0, 0];
    global.mp_rh_rem[part] = sc;
    if (part == 0)
    {
        global.mp_rh_rfame = fm;
        global.mp_rh_rlose = lc;
        global.mp_rh_rfame_t = current_time;
    }
}

// obj_rhythmgame End Step (prepended). The SCORE on screen is the game's `points` (in the solo
// game, Kris's guitar only); here it becomes the band's: the guitar's points from Kris's player
// plus the drums' and the vocals' from their players (parts nobody plays add nothing, as before).
function mp_rhythm_end_step()
{
    if (tenna_boss || !variable_global_exists("mp_inited") || !mp_on())
        return;
    if (!variable_global_exists("mp_rh_rem") || !is_array(global.mp_rh_rem))
        global.mp_rh_rem = [0, 0, 0];
    if (!variable_instance_exists(id, "mp_rh_last"))
    {
        mp_rh_last = points;
        mp_rh_applied = [0, 0, 0];
        mp_rh_mine = [0, 0, 0];
        mp_rh_tick = 0;
    }
    var gd = 0, gv = 0;
    if (variable_instance_exists(id, "drums") && instance_exists(drums) && variable_instance_exists(drums, "mp_rh_gain"))
    {
        gd = drums.mp_rh_gain;
        drums.mp_rh_gain = 0;
    }
    if (variable_instance_exists(id, "vocals") && instance_exists(vocals) && variable_instance_exists(vocals, "mp_rh_gain"))
    {
        gv = vocals.mp_rh_gain;
        vocals.mp_rh_gain = 0;
    }
    if (!mp_rhythm_song_on())
    {
        mp_rh_last = points;
        return;
    }
    // (A new run of the song starts the count again.)
    if (points == 0 && mp_rh_last != 0)
    {
        mp_rh_applied = [0, 0, 0];
        mp_rh_mine = [0, 0, 0];
    }
    var g = [points - mp_rh_last, gd, gv];
    for (var p = 0; p < 3; p++)
    {
        var o = mp_rhythm_owner(p);
        if (o >= 0 && o != global.mp_myid)
        {
            if (p == 0)
                points -= g[p];
            points += global.mp_rh_rem[p] - mp_rh_applied[p];
            mp_rh_applied[p] = global.mp_rh_rem[p];
        }
        else if (p == 0 || o == global.mp_myid)
        {
            mp_rh_mine[p] += g[p];
            if (p > 0)
                points += g[p];
        }
    }
    // The guitar's fame from Kris's player.
    if (mp_rhythm_remote(0) && variable_global_exists("mp_rh_rfame") && (current_time - global.mp_rh_rfame_t) < 3000 && !song_done)
    {
        fame = global.mp_rh_rfame;
        if (global.mp_rh_rlose > 0 && lose_con == 0)
        {
            lose_con = 1;
            mp_log("rhythm: Kris's player lost the song: mine fades out too");
        }
    }
    mp_rh_last = points;
    // My part goes out.
    mp_rh_tick++;
    if ((mp_rh_tick mod 15) == 0)
    {
        var mypart = mp_rhythm_my_part();
        if (mp_rhythm_owner(mypart) == global.mp_myid)
        {
            mp_begin(88);
            mp_wu8(mypart);
            mp_ws32(mp_rh_mine[mypart]);
            mp_wf64(fame);
            mp_wu8(lose_con);
            mp_send();
        }
        if ((mp_rh_tick mod 300) == 0)
            mp_log("rhythm: band score " + string(points) + " (mine " + string(mp_rh_mine[mypart]) + ", others " + string(global.mp_rh_rem) + ") fame " + string(fame));
    }
}
