// DELTARUNE Multiplayer - F9 menu, HUD, notifications, name tags.

function mp_ui_init()
{
    global.mp_ui_open = 0;
    global.mp_ui_sel = 0;
    global.mp_chat_sel = 0;    // F9 "Say": which quick message
    global.mp_chat_t = 0;      // when I last sent one
    global.mp_pping_t = array_create(8, -100000);   // when each player last pinged (F5)
    global.mp_ping_sent = -100000;
    global.mp_ui_edit = -1;    // which text field is being edited (-1 none)
    global.mp_ui_text = "";
    global.mp_ui_page = 0;     // 0 main, 1 settings, 2 controls & info
    global.mp_ui_scroll = 0;
    global.mp_fade = 0;
    global.mp_status_text = "";
    global.mp_font = asset_get_index("fnt_main");
    // All of the mod's text uses the game's clear main font: the small pixel fonts are hard to read.
    global.mp_font_small = global.mp_font;
    global.mp_ui_bind = 0;
    global.mp_ui_wrapped = -1;
    global.mp_ui_wrap_rows = 20;
    global.mp_font_tiny = asset_get_index("fnt_tinynoelle");
}

// Menu rows (built each frame so they reflect the session state).
function mp_ui_rows()
{
    if (global.mp_ui_page == 1)
        return ["battles", "noai", "vote", "hud", "tags", "souls", "vmode", "vkey", "vmic", "vmicvol", "vsens", "vvol", "vrange", "vtest", "back"];
    if (global.mp_ui_page == 2)
        return ["back"];
    if (global.mp_ui_page == 3)
    {
        // Steam friends in a game right now.
        var fr = [];
        var nf = variable_global_exists("mp_steam_frname") ? array_length(global.mp_steam_frname) : 0;
        for (var f = 0; f < nf; f++)
            array_push(fr, "fr" + string(f));
        if (nf == 0)
            array_push(fr, "frnone");
        array_push(fr, "frrefresh", "back");
        return fr;
    }
    var r = ["name", "char"];
    if (global.mp_role == 0)
    {
        if (mp_migrate_offer_on())
            array_push(r, "become_host");
        array_push(r, "host", "ip", "join", "steam_host", "steam_code", "steam_friends");
    }
    else
    {
        array_push(r, "goto", "spec", "chat");
        if (global.mp_role == 1)
            array_push(r, "bring");
        if (global.mp_role == 1 && variable_global_exists("mp_steam_code") && global.mp_steam_code != "")
            array_push(r, "steam_show");
        array_push(r, "leave");
    }
    array_push(r, "help", "settings", "stopsound", "noclip", "logzip");
    // Softlock tools that change the shared story: the host's (or a single player's) to use.
    if (mp_story_tools_allowed() && variable_global_exists("plot"))
        array_push(r, "story", "rewind");
    array_push(r, "close");
    return r;
}

// Reads menu input and hides it from the game while the menu is open.
function mp_ui_input()
{
    if (keyboard_check_pressed(vk_f7) && !global.mp_ui_open)
        mp_stop_all_sound();
    if (keyboard_check_pressed(vk_f5) && !global.mp_ui_open && mp_on())
        mp_ping_send();
    if (keyboard_check_pressed(vk_f6) && !global.mp_ui_open)
        mp_noclip_toggle();
    if (keyboard_check_pressed(vk_f8) && !global.mp_ui_open && mp_on())
    {
        if (keyboard_check(vk_shift) && global.mp_role == 1)
            mp_bring_everyone();
        else
            mp_go_to_player(mp_goto_target());
    }
    if (keyboard_check_pressed(vk_f9))
    {
        global.mp_ui_open = !global.mp_ui_open;
        global.mp_ui_edit = -1;
        global.mp_ui_sel = 0;
        global.mp_ui_page = 0;
        mp_ui_test_off();
        if (variable_global_exists("plot"))
            global.mp_ui_plot = global.plot;
        mp_ui_block();
        return;
    }
    if (!global.mp_ui_open)
        return;
    // Waiting for the new talk key.
    if (global.mp_ui_bind)
    {
        if (keyboard_check_pressed(vk_escape))
        {
            global.mp_ui_bind = 0;
        }
        else if (keyboard_check_pressed(vk_anykey))
        {
            var nk = keyboard_key;
            if (nk > 0 && mp_key_allowed(nk))
            {
                global.mp_cfg_vkey = nk;
                global.mp_ui_bind = 0;
                mp_config_save();
            }
            else
            {
                mp_notify("That key is already used. Pick another, or Esc to cancel.");
            }
        }
        mp_ui_block();
        return;
    }
    var rows = mp_ui_rows();
    var nrows = array_length(rows);
    global.mp_ui_sel = clamp(global.mp_ui_sel, 0, nrows - 1);
    if (global.mp_ui_edit >= 0)
    {
        // Text entry: collect typed characters ourselves (starts empty; empty keeps the old value).
        var t = global.mp_ui_text + string_replace_all(keyboard_string, "\n", "");
        keyboard_string = "";
        if (keyboard_check_pressed(vk_backspace) && string_length(t) > 0)
            t = string_copy(t, 1, string_length(t) - 1);
        if (string_length(t) > 40)
            t = string_copy(t, 1, 40);
        global.mp_ui_text = t;
        if (keyboard_check_pressed(vk_enter))
        {
            if (rows[global.mp_ui_edit] == "name" && t != "")
            {
                global.mp_cfg_name = string_copy(t, 1, 12);
                if (mp_on())
                {
                    global.mp_pname[global.mp_myid] = global.mp_cfg_name;
                    mp_send_pinfo(global.mp_myid);
                }
            }
            if (rows[global.mp_ui_edit] == "ip" && t != "")
                mp_cfg_set_address(t);
            if (rows[global.mp_ui_edit] == "steam_code" && t != "")
            {
                global.mp_ui_open = 0;
                global.mp_steam_want_mig = 0;
                mp_steam_join_code(t);
            }
            mp_config_save();
            global.mp_ui_edit = -1;
        }
        if (keyboard_check_pressed(vk_escape))
            global.mp_ui_edit = -1;
        mp_ui_block();
        return;
    }
    // Controls & info: up and down read through it; anything else goes back.
    if (global.mp_ui_page == 2)
    {
        var lines = is_array(global.mp_ui_wrapped) ? array_length(global.mp_ui_wrapped) : 0;
        if (global.input_pressed[2])
            global.mp_ui_scroll = max(0, global.mp_ui_scroll - 3);
        if (global.input_pressed[0])
            global.mp_ui_scroll = min(max(0, lines - mp_ui_help_rows()), global.mp_ui_scroll + 3);
        if (global.input_pressed[4] || global.input_pressed[5] || keyboard_check_pressed(vk_enter))
        {
            global.mp_ui_page = 0;
            global.mp_ui_sel = 0;
        }
        mp_ui_block();
        return;
    }
    if (global.input_pressed[2])
        global.mp_ui_sel = (global.mp_ui_sel + nrows - 1) mod nrows;
    if (global.input_pressed[0])
        global.mp_ui_sel = (global.mp_ui_sel + 1) mod nrows;
    var row = rows[global.mp_ui_sel];
    if (row == "char" && (global.input_pressed[1] || global.input_pressed[3]))
    {
        var d = 1;
        if (global.input_pressed[3])
            d = -1;
        mp_char_change(((global.mp_cfg_char - 1 + d + mp_char_max()) mod mp_char_max()) + 1);
    }
    if (row == "story" && (global.input_pressed[1] || global.input_pressed[3]))
    {
        var step = keyboard_check(vk_shift) ? 10 : 1;
        if (global.input_pressed[3])
            step = -step;
        global.mp_ui_plot = max(0, global.mp_ui_plot + step);
    }
    if (global.input_pressed[1] || global.input_pressed[3])
        mp_ui_adjust(row, global.input_pressed[3] ? -1 : 1);
    var confirm = global.input_pressed[4] || keyboard_check_pressed(vk_enter);
    if (confirm)
    {
        if (row == "help")
        {
            global.mp_ui_page = 2;
            global.mp_ui_scroll = 0;
            mp_ui_block();
            return;
        }
        if (row == "settings")
        {
            global.mp_ui_page = 1;
            global.mp_ui_sel = 0;
            mp_ui_block();
            return;
        }
        if (row == "back")
        {
            mp_ui_test_off();
            mp_config_save();
            global.mp_ui_page = 0;
            global.mp_ui_sel = 0;
            mp_ui_block();
            return;
        }
        if (row == "vtest")
            global.mp_v_test = !global.mp_v_test;
        if (row == "vkey")
        {
            global.mp_ui_bind = 1;
            mp_ui_block();
            return;
        }
        if (row == "spec")
            mp_ui_adjust(row, 1);
        if (row == "chat")
        {
            global.mp_ui_open = 0;
            mp_chat_send(global.mp_chat_sel);
        }
        if (row == "battles" || row == "noai" || row == "vote" || row == "hud" || row == "tags" || row == "souls" || row == "vmode" || row == "vrange" || row == "vmic" || row == "vsens")
            mp_ui_adjust(row, 1);
        if (row == "steam_host")
        {
            global.mp_ui_open = 0;
            mp_steam_host();
        }
        if (row == "become_host")
        {
            global.mp_ui_open = 0;
            mp_migrate_accept();
        }
        if (row == "steam_friends" || row == "frrefresh")
        {
            mp_steam_friends_refresh();
            global.mp_ui_page = 3;
            global.mp_ui_sel = 0;
            mp_ui_block();
            return;
        }
        if (string_copy(row, 1, 2) == "fr" && string_digits(row) != "" && string_length(string_digits(row)) == string_length(row) - 2)
        {
            var fi = real(string_digits(row));
            global.mp_ui_open = 0;
            global.mp_ui_page = 0;
            mp_steam_join_lobby(global.mp_steam_frlobby[fi], global.mp_steam_frname[fi]);
        }
        if (row == "steam_show")
        {
            clipboard_set_text(global.mp_steam_code);
            mp_notify("Code " + global.mp_steam_code + " copied.");
        }
        if (row == "name" || row == "ip" || row == "steam_code")
        {
            global.mp_ui_edit = global.mp_ui_sel;
            keyboard_string = "";
            global.mp_ui_text = "";
        }
        if (row == "host")
        {
            mp_config_save();
            mp_host_start(global.mp_cfg_port);
            global.mp_ui_open = 0;
        }
        if (row == "join")
        {
            mp_config_save();
            mp_join(global.mp_cfg_ip, global.mp_cfg_port);
            global.mp_ui_open = 0;
        }
        if (row == "goto")
        {
            global.mp_ui_open = 0;
            mp_go_to_player(mp_goto_target());
        }
        if (row == "bring")
        {
            global.mp_ui_open = 0;
            mp_bring_everyone();
        }
        if (row == "leave")
        {
            mp_resume_clear();
            mp_disconnect("You left the session.");
            global.mp_ui_open = 0;
        }
        if (row == "stopsound")
            mp_stop_all_sound();
        if (row == "logzip")
            mp_report_zip("");
        if (row == "noclip")
            mp_noclip_toggle();
        if (row == "story")
        {
            global.mp_ui_open = 0;
            mp_story_set(global.mp_ui_plot);
        }
        if (row == "rewind")
        {
            global.mp_ui_open = 0;
            mp_checkpoint_rewind();
        }
        if (row == "close")
            global.mp_ui_open = 0;
    }
    if (global.input_pressed[5])
    {
        if (global.mp_ui_page != 0)
        {
            mp_ui_test_off();
            mp_config_save();
            global.mp_ui_page = 0;
            global.mp_ui_sel = 0;
        }
        else
        {
            global.mp_ui_open = 0;
        }
    }
    mp_ui_block();
}

function mp_ui_test_off()
{
    global.mp_v_test = 0;
}

// Left and right on a settings row.
// F9 "Play as" (or the test's charto): my character, now and in the settings, told to everyone.
function mp_char_change(c)
{
    global.mp_cfg_char = c;
    mp_config_save();
    if (mp_on())
    {
        mp_pick_note(global.mp_myid, global.mp_cfg_char);
        global.mp_pchar[global.mp_myid] = global.mp_cfg_char;
        mp_send_pinfo(global.mp_myid);
        mp_log("character changed to " + mp_char_name(c));
        var taken = mp_char_player_other(global.mp_cfg_char);
        if (taken >= 0)
            mp_notify(global.mp_pname[taken] + " already plays " + mp_char_name(global.mp_cfg_char) + ": you'll watch them in fights, and take over if they change or leave.");
    }
}

function mp_ui_adjust(row, d)
{
    switch (row)
    {
        case "battles":
            // The host's to decide. (Not in a session yet: what I'd host with.)
            if (global.mp_role != 2)
            {
                global.mp_cfg_open = !global.mp_cfg_open;
                global.mp_open = global.mp_cfg_open;
                mp_open_send();
            }
            break;
        case "vote":
            if (global.mp_role != 2)
            {
                global.mp_cfg_vote = !global.mp_cfg_vote;
                global.mp_vote = global.mp_cfg_vote;
                mp_open_send();
            }
            break;
        case "noai":
            if (global.mp_role != 2)
            {
                global.mp_cfg_noai = !global.mp_cfg_noai;
                global.mp_noai = global.mp_cfg_noai;
                mp_open_send();
            }
            break;
        case "spec":
            mp_spec_set(mp_spec_next(mp_spec_on() ? global.mp_spec : (d > 0 ? -1 : 8), d));
            return;
        case "chat":
            var nm = array_length(mp_chat_msgs());
            global.mp_chat_sel = (global.mp_chat_sel + d + nm) mod nm;
            return;
        case "hud":
            global.mp_cfg_hud = !global.mp_cfg_hud;
            break;
        case "tags":
            global.mp_cfg_tags = !global.mp_cfg_tags;
            break;
        case "souls":
            global.mp_cfg_souls = !global.mp_cfg_souls;
            break;
        case "vmode":
            global.mp_cfg_vmode = (global.mp_cfg_vmode + d + 3) mod 3;
            break;
        case "vmic":
            mp_voice_mic_off();
            global.mp_cfg_vmic = (global.mp_cfg_vmic + d + max(1, audio_get_recorder_count())) mod max(1, audio_get_recorder_count());
            // A new choice is tried at once, even right after the last one failed to open.
            global.mp_v_retry_at = 0;
            global.mp_v_failed_told = 0;
            break;
        case "vvol":
            global.mp_cfg_vvol = clamp(global.mp_cfg_vvol + (d * 10), 0, 200);
            break;
        case "vmicvol":
            global.mp_cfg_vmicvol = clamp(global.mp_cfg_vmicvol + (d * 10), 0, 200);
            break;
        case "vrange":
            global.mp_cfg_vrange = (global.mp_cfg_vrange + d + 4) mod 4;
            break;
        case "vsens":
            global.mp_cfg_vsens = (global.mp_cfg_vsens + d + 3) mod 3;
            break;
        default:
            return;
    }
    mp_config_save();
}

// The Controls & info page.
function mp_ui_help()
{
    return [
        "== CONTROLS ==",
        "Arrow keys: move, and choose in menus",
        "Z or Enter: confirm, talk, and join a fight you walked up to",
        "X or Shift: cancel, run",
        "C or Ctrl: open the game's menu",
        "F9: this multiplayer menu",
        "F8: go to another player (press twice if you're stuck)",
        "Shift+F8 (host): bring everyone to where you are",
        "F7: stop all music and sounds, if the music gets out of step",
        "F6: noclip, walk through walls, your game only",
        mp_key_name(global.mp_cfg_vkey) + ": hold to talk (change the key in Settings)",
        "",
        "== BATTLES ==",
        "Each player plays one hero, picked under 'Play as' in this menu.",
        "Dodge with your own SOUL. Only bullets that hit your SOUL hurt you.",
        "Other players' SOULs are only shown, they can't be hit on your screen.",
        "So a bullet can seem to pass through a friend. Their game is what counts.",
        "Fights wait for everyone, then each attack starts at the same moment.",
        "",
        "Open-world battles (the host picks this in Settings):",
        " - Touch an enemy and you fight it with the players on your screen.",
        " - Alone, you fight with only your own hero.",
        " - Walk up to a friend in a fight and press Z to join at the next turn.",
        " - Story battles and bosses always bring in everyone.",
        " - If your whole fight falls, only your fight sees Game Over. You come",
        "   back at the room's entrance and nothing is reloaded.",
        "Everyone gets pulled in: every battle is every player's.",
        "",
        "== VOICE CHAT ==",
        "You hear players in the same room, quieter as they get further away.",
        "Push to talk is the default. Your mic is only on while you hold the talk key.",
        "Settings has your microphone, talk key, volumes, open mic sensitivity and",
        "how far voices carry. 'Mic test' lets you hear yourself and shows your level.",
        "It uses about 8 KB/s for each person talking.",
        "",
        "== PLAYING ONLINE ==",
        "Everyone needs the same version of this mod (the launcher keeps it updated). This is build " + string(global.mp_build) + " (network " + string(global.mp_version) + ").",
        "The host chooses 'Host a game', and needs UDP port " + string(global.mp_cfg_port) + " open.",
        "Everyone else enters the host's address under 'Host address', then Join.",
        "No router access? Use Radmin VPN, ZeroTier or Tailscale and the host's address there.",
        "",
        "== IF YOU GET STUCK ==",
        "Press F8 twice to go to another player.",
        "Noclip (F6) gets you past anything blocking the way.",
        "The host can replay a room's story or set story progress in this menu.",
        "This mod keeps its own save files, so your normal saves stay untouched.",
        "",
        "== CREDITS ==",
        "DELTARUNE Online by traebon, continued by benrirdawd.",
        "github.com/benrirdawd/deltarune-coop  -  Discord: b.001",
        "Help, bug reports and people to play with: discord.gg/GRX6XbTYRG",
        "Built on DELTARUNE Multiplayer by AeEn123AI (GPL-3.0).",
        "DELTARUNE is by Toby Fox. You need your own copy of the game."
    ];
}

function mp_ui_help_rows()
{
    return global.mp_ui_wrap_rows;
}

// The page's lines cut to fit the window, using the font it's drawn in.
function mp_ui_help_wrap(maxw, sc)
{
    var src = mp_ui_help();
    var out = [];
    for (var i = 0; i < array_length(src); i++)
    {
        var rest = src[i];
        while (string_width(rest) * sc > maxw)
        {
            var cut = string_length(rest);
            while (cut > 1 && (string_char_at(rest, cut) != " " || (string_width(string_copy(rest, 1, cut - 1)) * sc) > maxw))
                cut -= 1;
            if (cut <= 1)
                break;
            array_push(out, string_copy(rest, 1, cut - 1));
            rest = "   " + string_delete(rest, 1, cut);
        }
        array_push(out, rest);
    }
    return out;
}

function mp_ui_block()
{
    for (var i = 0; i < 10; i++)
    {
        global.input_pressed[i] = 0;
        global.input_held[i] = 0;
    }
}

function mp_ui_rowtext(row)
{
    if (string_copy(row, 1, 2) == "fr" && string_digits(row) != "" && string_length(string_digits(row)) == string_length(row) - 2)
    {
        var fi = real(string_digits(row));
        return fi < array_length(global.mp_steam_frname) ? "Join " + global.mp_steam_frname[fi] : "";
    }
    switch (row)
    {
        case "name":
            return "Name:  " + global.mp_cfg_name;
        case "char":
            var ct = "Play as:  < " + mp_char_name(global.mp_cfg_char) + " >";
            // Several players may play the same character; in battle the first of them
            // (lowest player number) controls it and the others watch.
            var co = mp_on() ? mp_char_player_other(global.mp_cfg_char) : -1;
            if (co >= 0)
            {
                ct += "  (also " + global.mp_pname[co];
                if (co < global.mp_myid)
                    ct += ": you watch battles";
                ct += ")";
            }
            return ct;
        case "host":
            return "Host a game (port " + string(global.mp_cfg_port) + ")";
        case "ip":
            return "Host address:  " + global.mp_cfg_ip + ":" + string(global.mp_cfg_port);
        case "join":
            return "Join game";
        case "steam_host":
            return "Host on Steam (code / friends)";
        case "become_host":
            return "Become the host (the others are waiting)";
        case "steam_code":
            return "Join on Steam with a code";
        case "steam_friends":
            return "Join a Steam friend";
        case "steam_show":
            return "Steam code:  " + global.mp_steam_code + "   (Z: copy)";
        case "frnone":
            return "No friends in a game right now";
        case "frrefresh":
            return "Refresh";
        case "spec":
            return "Watch:  < " + (mp_spec_on() ? global.mp_pname[global.mp_spec] : "off") + " >";
        case "chat":
            var cm = mp_chat_msgs();
            return "Say:  < " + cm[global.mp_chat_sel] + " >  (Z: send)";
        case "goto":
            var gt = mp_goto_target();
            if (gt < 0)
                return "Go to other player (F8)";
            return "Go to " + global.mp_pname[gt] + "  (F8)";
        case "bring":
            return "Bring everyone here  (Shift+F8)";
        case "leave":
            if (global.mp_role == 1)
                return "Stop hosting";
            return "Leave session";
        case "hud":
            return "Player list:  " + (global.mp_cfg_hud ? "ON" : "OFF");
        case "tags":
            return "Name tags:  " + (global.mp_cfg_tags ? "ON" : "OFF");
        case "souls":
            return "Other players' SOULs:  " + (global.mp_cfg_souls ? "ON" : "OFF");
        case "battles":
            var bm = global.mp_open ? "Open-world" : "Everyone gets pulled in";
            if (global.mp_role == 2)
                return "Battles:  " + bm + "  (the host chooses)";
            return "Battles:  < " + bm + " >";
        case "vote":
            var vt = global.mp_vote ? "Everyone votes" : "Host picks";
            if (global.mp_role == 2)
                return "Scene choices:  " + vt + "  (the host chooses)";
            return "Scene choices:  < " + vt + " >";
        case "noai":
            var na = global.mp_noai ? "Players' heroes only" : "Whole party";
            if (global.mp_role == 2)
                return "Story fights:  " + na + "  (the host chooses)";
            return "Story fights:  < " + na + " >";
        case "vmode":
            var vn = ["Off", "Push to talk", "Open mic"];
            return "Voice chat:  < " + vn[clamp(global.mp_cfg_vmode, 0, 2)] + " >";
        case "vkey":
            if (global.mp_ui_bind)
                return "Talk key:  press a key...  (Esc cancels)";
            return "Talk key:  " + mp_key_name(global.mp_cfg_vkey) + "  (Z to change)";
        case "vsens":
            return "Open mic sensitivity:  < " + mp_voice_sens_name() + " >";
        case "vmic":
            return "Microphone:  < " + mp_voice_mic_name() + " >";
        case "vvol":
            return "Voice volume:  < " + string(global.mp_cfg_vvol) + "% >";
        case "vmicvol":
            return "Mic volume:  < " + string(global.mp_cfg_vmicvol) + "% >";
        case "vrange":
            return "Hearing range:  < " + mp_voice_range_name() + " >";
        case "vtest":
            return "Mic test:  " + (global.mp_v_test ? "ON, you should hear yourself" : "OFF");
        case "help":
            return "Controls & info";
        case "settings":
            return "Settings";
        case "back":
            return "Back";
        case "stopsound":
            return "Stop all music and sounds  (F7)";
        case "logzip":
            return "Save logs for a bug report (zip on the desktop)";
        case "noclip":
            return "Noclip (walk through walls):  " + (global.mp_noclip ? "ON" : "OFF") + "  (F6)";
        case "story":
            var sp = "Fix softlock: story progress < " + string(global.mp_ui_plot) + " >";
            if (global.mp_ui_plot != global.plot)
                sp += " (now " + string(global.plot) + ")";
            return sp;
        case "rewind":
            return "Fix softlock: replay this room's story";
        case "close":
            return "Close";
    }
    return row;
}

// A dark strip behind on-screen text, so it stays readable over bright scenery.
function mp_ui_backing(xx, yy, w, h, sc, alpha = 0.6)
{
    var oa = draw_get_alpha();
    draw_set_color(c_black);
    draw_set_alpha(alpha);
    draw_rectangle(xx, yy, xx + w + (4 * sc), yy + h - 1, false);
    draw_set_alpha(oa);
}

function mp_draw_text_outlined(xx, yy, str, col)
{
    draw_set_color(c_black);
    draw_text(xx + 1, yy + 1, str);
    draw_text(xx - 1, yy + 1, str);
    draw_text(xx + 1, yy - 1, str);
    draw_text(xx - 1, yy - 1, str);
    draw_set_color(col);
    draw_text(xx, yy, str);
}

function mp_draw_gui()
{
    if (!variable_global_exists("mp_inited"))
        return;
    var gw = display_get_gui_width();
    var gh = display_get_gui_height();
    var sc = max(1, floor(gh / 480));
    var oldfont = draw_get_font();
    var oldcol = draw_get_color();
    var oldalpha = draw_get_alpha();
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    if (global.mp_font_small >= 0)
        draw_set_font(global.mp_font_small);
    draw_set_alpha(1);
    var lh = string_height("Ag") * sc;

    // A client in the opening while the host isn't in the game yet (mp_opening_tick).
    if (global.mp_open_wait)
    {
        draw_set_color(c_black);
        draw_rectangle(0, 0, gw, gh, false);
        var wt = global.mp_pname[0] + " (the host) is creating the vessel...";
        var wt2 = "You will join them when they are in the game.";
        mp_draw_text_outlined((gw - string_width(wt)) / 2, gh / 2 - lh, wt, c_white);
        mp_draw_text_outlined((gw - string_width(wt2)) / 2, gh / 2 + lh / 2, wt2, c_gray);
    }

    mp_ping_draw(gw, gh, sc);

    // Player list.
    if (global.mp_role != 0 && global.mp_cfg_hud)
    {
        var yy = 4 * sc;
        var head = "";
        if (global.mp_role == 1)
            head = "HOST";
        else if (global.mp_linkstate == 3)
            head = "PING " + string(global.mp_rtt) + "ms";
        else
            head = "CONNECTING...";
        var headt = head + "  " + string_format(global.mp_kbps_in + global.mp_kbps_out, 1, 1) + "KB/s";
        mp_ui_backing(2 * sc, yy, string_width(headt) * sc, lh, sc);
        draw_text_transformed_color(4 * sc, yy, headt, sc, sc, 0, c_ltgray, c_ltgray, c_ltgray, c_ltgray, 1);
        yy += lh;
        for (var i = 0; i < 8; i++)
        {
            if (!global.mp_pconn[i])
                continue;
            var label = global.mp_pname[i] + " (" + mp_char_name(global.mp_pchar[i]) + ")";
            if (i == global.mp_myid)
                label = "> " + label;
            else if (global.mp_proom[i] != room && global.mp_proom[i] >= 0)
                label += " - elsewhere";
            var st = global.mp_pstate[i];
            if (i == global.mp_myid)
                st = mp_state_bits();
            if (mp_voice_speaking(i))
                label += " (talking)";
            if (i != global.mp_myid && mp_player_reading(i))
                label += " (reading)";
            var pmg = (i == global.mp_myid) ? global.mp_mg : mp_player_minigame(i);
            if (st & 1)
                label += " [battle]";
            else if (st & 2)
                label += " [cutscene]";
            else if (pmg != "")
                label += " [" + string_replace(pmg, "the ", "") + "]";
            var col = mp_char_color(global.mp_pchar[i]);
            mp_ui_backing(2 * sc, yy, string_width(label) * sc, lh, sc);
            draw_text_transformed_color(4 * sc + 1, yy + 1, label, sc, sc, 0, c_black, c_black, c_black, c_black, 1);
            draw_text_transformed_color(4 * sc, yy, label, sc, sc, 0, col, col, col, col, 1);
            yy += lh;
        }
    }

    // Battle / sync status line.
    var status = mp_status_line();
    if (status != "")
    {
        var w = string_width(status) * sc;
        var sx = (gw - w) / 2;
        var sy = 4 * sc;
        draw_set_color(c_black);
        draw_set_alpha(0.6);
        draw_rectangle(sx - 6 * sc, sy - 2 * sc, sx + w + 6 * sc, sy + lh, false);
        draw_set_alpha(1);
        draw_text_transformed_color(sx, sy, status, sc, sc, 0, c_yellow, c_yellow, c_yellow, c_yellow, 1);
    }

    // Spectators of a cutscene that didn't start in their game see the leader's dialogue.
    if (global.mp_sstate == 4 && global.mp_watch_text != "")
    {
        var tw = gw - 40 * sc;
        var th = (lh * 3) + (12 * sc);
        var tx = 20 * sc;
        var ty = gh - th - 24 * sc;
        draw_set_color(c_black);
        draw_set_alpha(0.85);
        draw_rectangle(tx, ty, tx + tw, ty + th, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(tx, ty, tx + tw, ty + th, true);
        draw_text_ext_transformed(tx + 8 * sc, ty + 6 * sc, global.mp_watch_text, lh / sc, (tw - 16 * sc) / sc, sc, sc, 0);
    }

    // Notifications.
    var ny = gh - lh - (2 * sc);
    for (var n = ds_list_size(global.mp_notes) - 1; n >= 0; n--)
    {
        var age = current_time - ds_list_find_value(global.mp_note_time, n);
        if (age > 6000)
            continue;
        var a = clamp((6000 - age) / 1000, 0, 1);
        var txt = ds_list_find_value(global.mp_notes, n);
        mp_ui_backing(2 * sc, ny, string_width(txt) * sc, lh, sc, a * 0.6);
        draw_text_transformed_color(4 * sc + 1, ny + 1, txt, sc, sc, 0, c_black, c_black, c_black, c_black, a);
        draw_text_transformed_color(4 * sc, ny, txt, sc, sc, 0, c_white, c_white, c_white, c_white, a);
        ny -= lh;
    }

    // Fade out before / in after the mod moved me (like a door transition).
    var fade_out = variable_global_exists("mp_end_fade_a") ? global.mp_end_fade_a : 0;
    if (global.mp_fade > 0 || fade_out > 0)
    {
        draw_set_color(c_black);
        draw_set_alpha(max(global.mp_fade, fade_out));
        draw_rectangle(0, 0, gw, gh, false);
        draw_set_alpha(1);
        global.mp_fade = max(0, global.mp_fade - 0.06);
    }

    // My mic is on.
    if (global.mp_v_talking)
    {
        var mt = "MIC ON";
        var mw = string_width(mt) * sc;
        draw_set_color(c_black);
        draw_set_alpha(0.6);
        draw_rectangle(gw - mw - 10 * sc, 3 * sc, gw - 2 * sc, 5 * sc + lh, false);
        draw_set_alpha(1);
        draw_text_transformed_color(gw - mw - 6 * sc, 4 * sc, mt, sc, sc, 0, c_lime, c_lime, c_lime, c_lime, 1);
    }

    // Controls & info.
    if (global.mp_ui_open && global.mp_ui_page == 2)
    {
        var hb = 8 * sc;
        if (global.mp_font_small >= 0)
            draw_set_font(global.mp_font_small);
        var hl = mp_ui_help_wrap(gw - (2 * hb) - (16 * sc), sc);
        global.mp_ui_wrapped = hl;
        var hrows = floor((gh - (2 * hb) - (12 * sc) - lh) / lh);
        global.mp_ui_wrap_rows = hrows;
        draw_set_color(c_black);
        draw_rectangle(hb, hb, gw - hb, gh - hb, false);
        draw_set_color(c_white);
        draw_rectangle(hb, hb, gw - hb, gh - hb, true);
        for (var hi = 0; hi < hrows; hi++)
        {
            var hx = global.mp_ui_scroll + hi;
            if (hx >= array_length(hl))
                break;
            var ht = hl[hx];
            var hc = string_char_at(ht, 1) == "=" ? c_yellow : c_white;
            draw_text_transformed_color(hb + 8 * sc, hb + 6 * sc + (hi * lh), ht, sc, sc, 0, hc, hc, hc, hc, 1);
        }
        var hmax = max(0, array_length(hl) - hrows);
        var hh = "Up / Down: read more";
        if (global.mp_ui_scroll >= hmax)
            hh = "End of page";
        hh += "     X: back";
        draw_text_transformed_color(hb + 8 * sc, (gh - hb) - lh - 2 * sc, hh, sc, sc, 0, c_ltgray, c_ltgray, c_ltgray, c_ltgray, 1);
    }
    // F9 menu.
    else if (global.mp_ui_open)
    {
        var rows = mp_ui_rows();
        if (global.mp_font >= 0)
            draw_set_font(global.mp_font);
        var tw = 0;
        for (var r0 = 0; r0 < array_length(rows); r0++)
            tw = max(tw, string_width(mp_ui_rowtext(rows[r0])));
        var bw = min(max(300, tw + 40) * sc, gw - 8 * sc);
        var bh = (32 * sc) + (array_length(rows) * 22 * sc) + lh + (6 * sc);
        var bx = (gw - bw) / 2;
        var by = (gh - bh) / 2;
        draw_set_color(c_black);
        draw_rectangle(bx, by, bx + bw, by + bh, false);
        draw_set_color(c_white);
        draw_rectangle(bx, by, bx + bw, by + bh, true);
        draw_rectangle(bx + sc, by + sc, (bx + bw) - sc, (by + bh) - sc, true);
        if (global.mp_font >= 0)
            draw_set_font(global.mp_font);
        draw_text_transformed(bx + 12 * sc, by + 6 * sc, global.mp_ui_page == 1 ? "SETTINGS" : (global.mp_ui_page == 3 ? "STEAM FRIENDS" : "MULTIPLAYER"), sc, sc, 0);
        for (var r = 0; r < array_length(rows); r++)
        {
            var t = mp_ui_rowtext(rows[r]);
            if (global.mp_ui_edit == r)
                t = "> " + global.mp_ui_text + "_";
            var c2 = c_white;
            if (r == global.mp_ui_sel)
                c2 = c_yellow;
            draw_text_transformed_color(bx + 20 * sc, by + (32 + r * 22) * sc, t, sc, sc, 0, c2, c2, c2, c2, 1);
        }
        if (global.mp_font_small >= 0)
            draw_set_font(global.mp_font_small);
        var hint = global.mp_ui_page == 1 ? "Left / Right: change   X: back" : "Z: select   X: close   F9: toggle";
        if (global.mp_ui_edit >= 0)
            hint = "Type, then ENTER (empty keeps the old value, ESC cancels)";
        draw_text_transformed_color(bx + 12 * sc, (by + bh) - lh - 2 * sc, hint, sc, sc, 0, c_ltgray, c_ltgray, c_ltgray, c_ltgray, 1);
        // Mic test: how loud I am coming through.
        if (global.mp_ui_page == 1 && global.mp_v_test)
        {
            var lv = clamp(global.mp_v_level / 8000, 0, 1);
            var lx = (bx + bw) - 90 * sc;
            draw_set_color(c_dkgray);
            draw_rectangle(lx, by + 8 * sc, lx + 80 * sc, by + 18 * sc, false);
            draw_set_color(c_lime);
            draw_rectangle(lx, by + 8 * sc, lx + (80 * sc * lv), by + 18 * sc, false);
        }
    }
    else if (global.mp_role == 0 && global.mp_frame < 300)
    {
        draw_text_transformed_color(4 * sc, 4 * sc, "Multiplayer mod: press F9", sc, sc, 0, c_gray, c_gray, c_gray, c_gray, 1);
    }
    draw_set_font(oldfont);
    draw_set_color(oldcol);
    draw_set_alpha(oldalpha);
}

// Name tag drawn above a ghost (world coordinates).
function mp_draw_nametag(pid, cx, ty)
{
    var oldfont = draw_get_font();
    if (global.mp_font_small >= 0)
        draw_set_font(global.mp_font_small);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var col = mp_char_color(global.mp_pchar[pid]);
    var s = global.mp_pname[pid];
    if (mp_voice_speaking(pid))
        s = "(talking) " + s;
    if (!global.mp_cfg_tags && !(global.mp_open && (global.mp_pstate[pid] & 1)))
        return mp_draw_nametag_end(oldfont);
    if (global.mp_open && (global.mp_pstate[pid] & 1))
        s += " [FIGHTING]";
    cx = mp_label_x(cx, string_width(s));
    draw_set_color(c_black);
    draw_text(cx + 1, ty + 1, s);
    draw_set_color(col);
    draw_text(cx, ty, s);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(oldfont);
    draw_set_color(c_white);
}

// Keeps a label of width w, centred on cx, inside the view (world coordinates).
function mp_label_x(cx, w)
{
    var vx = camera_get_view_x(view_camera[0]);
    var vw = camera_get_view_width(view_camera[0]);
    return clamp(cx, vx + (w / 2) + 2, (vx + vw) - (w / 2) - 2);
}

// Above a friend's fight that I'm close enough to join (world coordinates).
function mp_draw_join_prompt(cx, ty)
{
    var oldfont = draw_get_font();
    if (global.mp_font >= 0)
        draw_set_font(global.mp_font);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var s = "Press Z to join!";
    var w = string_width(s) + 8;
    var h = string_height(s) + 2;
    cx = mp_label_x(cx, w);
    draw_set_alpha(0.75);
    draw_set_color(c_black);
    draw_rectangle(cx - (w / 2), ty - h, cx + (w / 2), ty + 1, false);
    draw_set_alpha(1);
    var col = merge_color(c_yellow, c_white, 0.5 + (0.5 * sin(current_time / 180)));
    draw_set_color(col);
    draw_text(cx, ty, s);
    mp_draw_nametag_end(oldfont);
}

function mp_draw_nametag_end(oldfont)
{
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(oldfont);
    draw_set_color(c_white);
}

// Accepts "host", "host:port" (and "[ipv6]:port"); an invalid port keeps the current one.
function mp_cfg_set_address(t)
{
    t = string_replace_all(t, " ", "");
    var c = string_last_pos(":", t);
    var b = string_pos("]", t);
    if (c > 0 && c > b && string_count(":", t) == 1 || (c > 0 && b > 0 && c > b))
    {
        var portstr = string_delete(t, 1, c);
        var host = string_copy(t, 1, c - 1);
        var pv = -1;
        if (portstr != "" && string_digits(portstr) == portstr)
            pv = real(portstr);
        if (pv >= 1 && pv <= 65535)
            global.mp_cfg_port = pv;
        else
            mp_notify("Invalid port '" + portstr + "' - keeping " + string(global.mp_cfg_port));
        t = host;
    }
    t = string_replace_all(string_replace_all(t, "[", ""), "]", "");
    if (t != "")
        global.mp_cfg_ip = t;
}

// Stops every sound and song that is playing (for when the music got out of step). The game
// starts a room's song again the next time it is entered, since rooms only start one when none plays.
function mp_stop_all_sound()
{
    audio_stop_all();
    mp_notify("Stopped all music and sounds.");
}

// The name the C menu's status / equipment page gives party member c: Kris's place is the one I play
// (my character walks in front, my character's follower is drawn as Kris), so the names swap too.
function mp_menu_charname(c)
{
    var me = 1;
    if (variable_global_exists("mp_inited") && mp_on() && mp_swaps_enabled())
        me = global.mp_cfg_char;
    var shown = c;
    if (me != 1 && c == 1)
        shown = me;
    else if (me != 1 && c == me)
        shown = 1;
    if (shown >= 0 && shown < array_length(global.charname) && is_string(global.charname[shown]) && global.charname[shown] != "")
        return global.charname[shown];
    return global.charname[c];
}

// F9 "Save logs for a bug report": this session's log, the one before (after a crash and a restart,
// that's the crashed one) and multiplayer_crash.txt, zipped onto the desktop (drm_steam.dll,
// drs_report_zip). out_dir "" = the desktop (tests pass a folder).
function mp_report_zip(out_dir)
{
    mp_log("bug report: saving the logs");
    mp_filelog_flush();
    var p = drs_report_zip(game_save_id, out_dir);
    if (p == "")
    {
        mp_notify("Couldn't save the logs: " + drs_error());
        mp_log("bug report: failed, " + drs_error());
        return "";
    }
    mp_notify("Logs saved " + (out_dir == "" ? "on your desktop" : "in " + out_dir) + ": " + filename_name(p) + ". Send it with your bug report (Discord b.001).");
    mp_log("bug report: saved " + p);
    return p;
}

// ---------------------------------------------------------------- quick messages

// F9 "Say": a few fixed messages (left/right to pick, Z to send). Only the number goes out
// (message 84); it shows as a note for everyone and for 4 s in a bubble over the sender's figure.
// (A fixed list, simplest: no typing, which the game would also see as key presses.)
function mp_chat_msgs()
{
    return ["Wait for me!", "Come here!", "I'm saving.", "Let's go!", "Yes", "No", "Thanks!", "Be right back", "Help!", "Over here!"];
}

function mp_chat_send(i)
{
    if (!mp_on() || current_time - global.mp_chat_t < 1000)
        return;
    var msgs = mp_chat_msgs();
    if (i < 0 || i >= array_length(msgs))
        return;
    global.mp_chat_t = current_time;
    mp_begin(84);
    mp_wu8(i);
    mp_send();
    mp_notify("You: " + msgs[i]);
}

function mp_chat_recv(sender, b)
{
    var i = buffer_read(b, buffer_u8);
    var msgs = mp_chat_msgs();
    if (sender < 0 || sender >= 8 || i >= array_length(msgs))
        return;
    global.mp_pchat[sender] = msgs[i];
    global.mp_pchat_t[sender] = current_time;
    mp_notify(global.mp_pname[sender] + ": " + msgs[i]);
}

// ---------------------------------------------------------------- map ping (F5)

// F5: "here I am". For 3 s everyone in my room sees an arrow bouncing over me (at the screen's edge,
// pointing my way, when I'm off their screen); someone in another room gets a note. (Message 85, the
// room; the arrow uses the position they already have for me.)
function mp_ping_send()
{
    if (current_time - global.mp_ping_sent < 1000)
        return;
    global.mp_ping_sent = current_time;
    global.mp_pping_t[global.mp_myid] = current_time;
    mp_begin(85);
    mp_wu16(room);
    mp_send();
    mp_notify("Ping! The others see where you are.");
}

function mp_ping_recv(sender, b)
{
    var rm = buffer_read(b, buffer_u16);
    if (sender < 0 || sender >= 8)
        return;
    global.mp_pping_t[sender] = current_time;
    if (rm == room)
        mp_notify(global.mp_pname[sender] + " pings: here!");
    else
        mp_notify(global.mp_pname[sender] + " pings from another room" + (room_exists(rm) ? " (" + room_get_name(rm) + ")" : "") + ".");
}

// Where player p is in my room: the point above their name tag (world coordinates), or -1. (The
// same top-centre the name tag uses: sprite origins differ between sprites.)
function mp_ping_where(p)
{
    var r = -1;
    if (p == global.mp_myid)
    {
        with (obj_mainchara)
            r = [x + (((sprite_get_width(sprite_index) / 2) - sprite_get_xoffset(sprite_index)) * image_xscale), y - (sprite_get_yoffset(sprite_index) * image_yscale) - 16];
        return r;
    }
    if (global.mp_proom[p] != room)
        return -1;
    with (obj_mp_ghost)
    {
        if (pid == p && fol < 0 && visible && sprite_exists(sprite_index))
            r = [x + (((sprite_get_width(sprite_index) / 2) - sprite_get_xoffset(sprite_index)) * image_xscale), y - (sprite_get_yoffset(sprite_index) * image_yscale) - 16];
    }
    return r;
}

// From mp_draw_gui: the arrows of the players who pinged in the last 3 s.
function mp_ping_draw(gw, gh, sc)
{
    if (!mp_on() || mp_in_battle_scene())
        return;
    var cam = view_camera[0];
    var cx = camera_get_view_x(cam);
    var cy = camera_get_view_y(cam);
    var cw = camera_get_view_width(cam);
    var ch = camera_get_view_height(cam);
    if (cw <= 0 || ch <= 0)
        return;
    for (var p = 0; p < 8; p++)
    {
        var age = current_time - global.mp_pping_t[p];
        // (Test token pinglong: the arrows stay 30 s, long enough for a screenshot.)
        if (global.mp_test != "" && mp_test_has("pinglong") && age <= 30000)
            age = min(age, 2000);
        if (age > 3000 || (p != global.mp_myid && !global.mp_pconn[p]))
            continue;
        var w = mp_ping_where(p);
        if (!is_array(w))
            continue;
        var gx = (w[0] - cx) * gw / cw;
        var gy = (w[1] - cy) * gh / ch;
        var col = mp_char_color(global.mp_pchar[p]);
        var m = 14 * sc;
        var a = (age < 2500) ? 1 : (3000 - age) / 500;
        draw_set_alpha(a);
        if (gx >= m && gx <= gw - m && gy >= m && gy <= gh - m)
        {
            // On screen: a bouncing arrow pointing down at them.
            var by = gy - (8 * sc) - abs(sin(age / 120)) * 10 * sc;
            mp_ping_arrow(gx, by, 270, col, sc);
        }
        else
        {
            // Off screen: at the edge, pointing towards them.
            var ex = clamp(gx, m, gw - m);
            var ey = clamp(gy, m, gh - m);
            // (Not under the player list in the top-left corner: just below it.)
            var nl = 1;
            for (var q = 0; q < 8; q++)
                nl += global.mp_pconn[q] ? 1 : 0;
            var hud_b = (12 + 16 * nl) * sc + m;
            if (ex < 140 * sc && ey < hud_b)
                ey = hud_b;
            mp_ping_arrow(ex, ey, point_direction(ex, ey, gx, gy), col, sc);
        }
        draw_set_alpha(1);
    }
}

// A filled arrow head at (xx, yy) pointing in direction dir (degrees, GameMaker's: 270 = down).
function mp_ping_arrow(xx, yy, dir, col, sc)
{
    var l = 18 * sc;
    var w = 11 * sc;
    var tx = xx + lengthdir_x(l / 2, dir);
    var ty = yy + lengthdir_y(l / 2, dir);
    var bx = xx - lengthdir_x(l / 2, dir);
    var by = yy - lengthdir_y(l / 2, dir);
    var x1 = bx + lengthdir_x(w, dir + 90);
    var y1 = by + lengthdir_y(w, dir + 90);
    var x2 = bx + lengthdir_x(w, dir - 90);
    var y2 = by + lengthdir_y(w, dir - 90);
    draw_set_color(c_black);
    draw_triangle(tx + sc, ty + sc, x1 + sc, y1 + sc, x2 + sc, y2 + sc, false);
    draw_set_color(col);
    draw_triangle(tx, ty, x1, y1, x2, y2, false);
    draw_set_color(c_white);
    draw_triangle(tx, ty, x1, y1, x2, y2, true);
}

// Player p is reading a text box: talking to someone on their own (the talk bubble's text), or, in the
// shared cutscene I'm in too, their copy of the current page hasn't finished typing / been read yet
// (mp_dlg_recv: what each game says about its box). Shown as "(reading)" in the player list.
function mp_player_reading(p)
{
    if (global.mp_ptalk[p] != "" && (current_time - global.mp_ptalk_t[p]) < 2500)
        return true;
    // (Same box: mp_dlg_counted, as the page turning uses.)
    return global.mp_sstate != 0 && mp_dlg_counted(p) && instance_exists(obj_writer) && !global.mp_pdlg_ready[p];
}
