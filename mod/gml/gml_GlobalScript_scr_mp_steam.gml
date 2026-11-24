// Playing over Steam (drm_steam.dll, steam/drm_steam.c): the host opens a Steam lobby with a short
// code; others join it by typing the code or picking a friend who is in one (or with Steam's own
// "Join game"). Messages then go through Steam's relays instead of UDP: no port forwarding.
//
// The rest of the multiplayer code doesn't change: a Steam player is a peer whose "address" is
// "steam" and whose "port" is its number in the DLL (mp_pkt_send, mp_net_packet).

function mp_steam_globals()
{
    if (variable_global_exists("mp_steam_ok"))
        return;
    global.mp_steam_ok = 0;
    global.mp_steam_code = "";      // my lobby's code while I host on Steam
    global.mp_steam_buf = buffer_create(65536, buffer_fixed, 1);
    global.mp_steam_frname = [];
    global.mp_steam_frlobby = [];
    global.mp_steam_want = "";      // host with this code instead of a new one (next chapter)
    global.mp_steam_joined = "";    // the code of the lobby I joined
    global.mp_steam_retries = 0;    // look for the code again when it isn't found (next chapter)
    global.mp_steam_retry_at = 0;
    global.mp_steam_retry_code = "";
    global.mp_steam_want_mig = 0;   // (after a host change) only a lobby with this count or newer
}

// Starts Steam the first time it is needed; false (and says why) when it can't.
function mp_steam_start()
{
    mp_steam_globals();
    if (global.mp_steam_ok)
        return true;
    global.mp_steam_ok = drs_init() > 0;
    if (!global.mp_steam_ok)
        mp_notify("Steam: " + drs_error() + ". Open Steam and try again.");
    else
        mp_log("steam: up as " + drs_my_name());
    return global.mp_steam_ok;
}

function mp_steam_on()
{
    return variable_global_exists("mp_steam_ok") && global.mp_steam_ok;
}

function mp_steam_new_code()
{
    // (No 0/O, 1/I: easy to read out loud.)
    var abc = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    var s = "";
    for (var i = 0; i < 6; i++)
        s += string_char_at(abc, irandom(string_length(abc) - 1) + 1);
    return s;
}

function mp_steam_host()
{
    if (!mp_steam_start())
        return;
    mp_config_save();
    if (!mp_host_start(global.mp_cfg_port, true))
        return;
    global.mp_steam_code = mp_steam_new_code();
    if (global.mp_steam_want != "")
        global.mp_steam_code = global.mp_steam_want;
    global.mp_steam_want = "";
    if (global.mp_test != "" && mp_test_has("steamcode"))
        global.mp_steam_code = mp_test_arg("steamcode");
    if (drs_host(global.mp_steam_code, 8) <= 0)
    {
        global.mp_steam_code = "";
        mp_notify("Steam: could not open a lobby.");
        return;
    }
    mp_notify("Opening a Steam lobby...");
}

function mp_steam_join_code(code)
{
    if (!mp_steam_start())
        return;
    code = string_upper(string_replace_all(code, " ", ""));
    if (string_length(code) < 4)
    {
        mp_notify("That code is too short.");
        return;
    }
    mp_disconnect("");
    global.mp_steam_code = "";
    global.mp_steam_retry_code = code;
    drs_join_code(code);
    mp_notify("Looking for the Steam game " + code + "...");
}

function mp_steam_join_lobby(lobby, who)
{
    if (!mp_steam_start())
        return;
    mp_disconnect("");
    global.mp_steam_code = "";
    global.mp_steam_want_mig = 0;
    drs_join_lobby(lobby);
    mp_notify("Joining " + who + " on Steam...");
}

// Friends who are in a Steam lobby of this game right now (for the F9 list).
function mp_steam_friends_refresh()
{
    global.mp_steam_frname = [];
    global.mp_steam_frlobby = [];
    if (!mp_steam_start())
        return;
    var n = drs_friends_refresh();
    for (var i = 0; i < n; i++)
    {
        array_push(global.mp_steam_frname, drs_friend_name(i));
        array_push(global.mp_steam_frlobby, drs_friend_lobby(i));
    }
}

// Every frame (mp_net_tick): Steam's callbacks, its events, then the messages that came in.
function mp_steam_tick()
{
    if (!mp_steam_on())
        return;
    drs_tick();
    for (var guard = 0; guard < 16; guard++)
    {
        var ev = drs_event();
        if (ev == "")
            break;
        mp_log("steam: " + ev);
        var sp = string_pos(" ", ev);
        var what = sp > 0 ? string_copy(ev, 1, sp - 1) : ev;
        var arg = sp > 0 ? string_delete(ev, 1, sp) : "";
        switch (what)
        {
            case "hosting":
                if (global.mp_steam_code == "")
                {
                    // Joined a lobby I own: my own game, from a second copy on the same Steam account.
                    drs_leave();
                    mp_notify("That is your own Steam game: the other player needs another Steam account.");
                    break;
                }
                drs_lobby_set("drm_online", "1");
                drs_lobby_set("drm_code", global.mp_steam_code);
                drs_lobby_set("drm_chapter", string(global.mp_chapter));
                drs_lobby_set("drm_mig", string(global.mp_mig));
                mp_notify("Hosting on Steam. Code: " + global.mp_steam_code + "  (friends can also join from the F9 menu)");
                break;
            case "host_failed":
                global.mp_steam_code = "";
                mp_notify("Steam: could not open a lobby (" + arg + ").");
                break;
            case "joined":
                // In the host's lobby: now the game's own join, to the host's Steam peer.
                // (After a host change: the old host's lobby, still there with the same code, is
                // left again, and the code looked for once more.)
                var lm = string_digits(drs_lobby_get("drm_mig"));
                if (global.mp_steam_want_mig > 0 && (lm == "" ? 0 : real(lm)) < global.mp_steam_want_mig)
                {
                    mp_log("steam: old lobby (host change " + lm + "), looking again");
                    drs_leave();
                    if (global.mp_steam_retries > 0)
                    {
                        global.mp_steam_retries -= 1;
                        global.mp_steam_retry_at = current_time + 3000;
                    }
                    else
                    {
                        global.mp_steam_want_mig = 0;
                        mp_notify("The new host's Steam game wasn't found: ask them for the code (F9).");
                    }
                    break;
                }
                global.mp_steam_want_mig = 0;
                global.mp_steam_retries = 0;
                global.mp_steam_joined = drs_lobby_get("drm_code");
                global.mp_join_retries = 0;
                mp_join("steam", real(arg));
                break;
            case "join_failed":
                mp_notify("Steam: could not join that game (" + arg + ").");
                break;
            case "code_not_found":
                if (global.mp_steam_retries > 0)
                {
                    global.mp_steam_retries -= 1;
                    global.mp_steam_retry_at = current_time + 3000;
                    break;
                }
                global.mp_steam_want_mig = 0;
                mp_notify("No Steam game with that code. Check it, and that the host is still hosting.");
                break;
            case "join_request":
                // A friend's "Join game" in Steam.
                if (global.mp_role == 0)
                    mp_steam_join_lobby(arg, "your friend");
                else
                    mp_notify("Steam join request ignored: leave this session first (F9).");
                break;
            case "session_failed":
                mp_log("steam: a connection failed");
                break;
        }
    }
    if (global.mp_steam_retry_at > 0 && current_time >= global.mp_steam_retry_at)
    {
        global.mp_steam_retry_at = 0;
        if (global.mp_role == 0)
            drs_join_code(global.mp_steam_retry_code);
    }
    if (global.mp_usock < 0)
        return;
    var addr = buffer_get_address(global.mp_steam_buf);
    for (var k = 0; k < 256; k++)
    {
        var n = drs_recv(addr, 65536);
        if (n <= 0)
            break;
        mp_net_packet(global.mp_steam_buf, n, "steam", drs_recv_peer());
    }
}

// Leaving a session that was on Steam: out of the lobby too.
function mp_steam_leave()
{
    if (!mp_steam_on())
        return;
    drs_leave();
    global.mp_steam_code = "";
}
