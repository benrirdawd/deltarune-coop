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
    if (mp_rhythm_my_part() != 2)
        return;
    if (!variable_instance_exists(id, "vocals") || !instance_exists(vocals))
        return;
    if (!variable_instance_exists(id, "mp_rh_set"))
    {
        mp_rh_set = 1;
        mp_log("rhythm: I sing the vocals, the guitar plays itself");
    }
    auto_play = 1;
    vocals.auto_play = 0;
}

// Is this chart played by my keys?
function mp_rhythm_mine(ch)
{
    if (ch.auto_play || ch.instrument != 2)
        return false;
    if (!instance_exists(obj_rhythmgame) || obj_rhythmgame.tenna_boss)
        return false;
    return mp_rhythm_my_part() == 2;
}

function mp_rhythm_key(lane, held)
{
    var r = false;
    // (Test token rhythmbot: press each vocal note on time, hold the long ones.)
    if (mp_test_has("rhythmbot") && instance_exists(obj_rhythmgame))
    {
        var tp = obj_rhythmgame.trackpos;
        with (obj_rhythmgame_chart)
        {
            if (instrument != 2)
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
            mp_log("rhythm: vocal key " + string(lane) + " (bot)");
        return r;
    }
    with (obj_rhythmgame)
    {
        if (lane == 0)
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

// A vocal note hit by my keys: Ralsei sings it, as on autoplay.
function mp_rhythm_hit(ch)
{
    if (!mp_rhythm_mine(ch))
        return;
    if (ch.instrument == 2 && instance_exists(ch.performer))
        ch.performer.sprite_index = ch.performer.mid;
    global.mp_rh_hits = (variable_global_exists("mp_rh_hits") ? global.mp_rh_hits : 0) + 1;
    mp_log("rhythm: vocal hit " + string(global.mp_rh_hits) + " score " + string(obj_rhythmgame.total_score));
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
