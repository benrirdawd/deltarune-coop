// The host as referee for shared cutscenes.
//
// A cutscene that every player gets pulled into used to be started by whoever's game started it,
// so two players could start two at once (each pulling the others), or one could start while
// someone else was in a fight. Now only one shared cutscene runs at a time, and the host decides
// which: a game that recognises a story cutscene of its own (mp_classify_step) asks the host for
// the lock (message 62) and holds the scene at its next text box until the host grants it
// (message 63, sent to everyone with a number that grows on every change). Only the holder's
// pulls are followed. The lock is given back at the end of the scene (message 64), or taken back
// when its holder leaves or hasn't been in a cutscene for 3 s.
//
// (The scene itself still plays in each game: only its start is decided by the host. Same
// pattern as the coop-anything playbook's "intents" and its lesson 41: sync the start, the skip
// and the end of a scripted scene, not the scene.)

function mp_lock_init()
{
    global.mp_lock_pid = -1;      // who holds the shared-cutscene lock (-1 nobody)
    global.mp_lock_ep = 0;        // grows on every change; stale announcements are ignored
    global.mp_lock_t = 0;         // when it was granted (host)
    global.mp_lock_free_n = 0;    // frames the holder hasn't been in a cutscene (host)
    global.mp_lock_q = [];        // players waiting for it, first come first (host)
    global.mp_lock_waiting = 0;   // my scene waits for the lock
    global.mp_lock_req_t = 0;     // last request sent
    global.mp_lock_bcast_t = 0;   // last announcement (host)
    global.mp_lock_log = "";
}

function mp_lock_reset()
{
    global.mp_lock_pid = -1;
    global.mp_lock_q = [];
    global.mp_lock_waiting = 0;
}

// Someone (other than me) is in a fight of their own (separate fights only).
function mp_lock_fighting(except)
{
    if (!global.mp_open)
        return -1;
    for (var i = 0; i < 8; i++)
    {
        if (i == except || !global.mp_pconn[i])
            continue;
        var f = i == global.mp_myid ? mp_in_battle_scene() : ((global.mp_pstate[i] & 1) != 0);
        if (f)
            return i;
    }
    return -1;
}

function mp_lock_note(t)
{
    if (t != global.mp_lock_log)
    {
        global.mp_lock_log = t;
        mp_log("scene lock: " + t);
    }
}

// May my game lead the shared cutscene that just started in it? (Asks if not.)
function mp_lock_ok()
{
    if (global.mp_lock_pid == global.mp_myid)
        return true;
    if (global.mp_role == 1)
    {
        mp_lock_host_req(global.mp_myid);
        mp_lock_host_tick();
        if (global.mp_lock_pid == global.mp_myid)
            return true;
        global.mp_lock_waiting = 1;
        return false;
    }
    mp_lock_request();
    return false;
}

function mp_lock_request()
{
    global.mp_lock_waiting = 1;
    if (global.mp_role == 1)
    {
        mp_lock_host_req(global.mp_myid);
        return;
    }
    if ((current_time - global.mp_lock_req_t) < 1000)
        return;
    global.mp_lock_req_t = current_time;
    mp_lock_note("asked the host");
    mp_begin(62);
    mp_wu16(room);
    mp_send();
}

// My scene is over (or I stopped waiting): give the lock back / leave the queue.
function mp_lock_done()
{
    var had = global.mp_lock_pid == global.mp_myid || global.mp_lock_waiting;
    global.mp_lock_waiting = 0;
    if (!had)
        return;
    if (global.mp_role == 1)
    {
        mp_lock_host_drop(global.mp_myid);
        return;
    }
    mp_lock_note("given back");
    mp_begin(64);
    mp_send();
}

// ---- host

function mp_lock_host_req(pid)
{
    if (global.mp_lock_pid == pid)
    {
        global.mp_lock_bcast_t = 0;   // (they missed the announcement: send it again)
        return;
    }
    for (var i = 0; i < array_length(global.mp_lock_q); i++)
        if (global.mp_lock_q[i] == pid)
            return;
    array_push(global.mp_lock_q, pid);
    mp_log("scene lock: " + global.mp_pname[pid] + " asks (holder " + string(global.mp_lock_pid) + ")");
}

function mp_lock_host_drop(pid)
{
    for (var i = array_length(global.mp_lock_q) - 1; i >= 0; i--)
        if (global.mp_lock_q[i] == pid)
            array_delete(global.mp_lock_q, i, 1);
    if (global.mp_lock_pid == pid)
        mp_lock_set(-1, "released by " + global.mp_pname[pid]);
}

function mp_lock_set(pid, why)
{
    global.mp_lock_pid = pid;
    global.mp_lock_ep += 1;
    global.mp_lock_t = current_time;
    global.mp_lock_free_n = 0;
    global.mp_lock_bcast_t = 0;
    mp_log("scene lock: " + (pid >= 0 ? "granted to " + global.mp_pname[pid] : "free") + " (" + why + ", ep " + string(global.mp_lock_ep) + ")");
}

function mp_lock_host_tick()
{
    if (global.mp_role != 1)
        return;
    var h = global.mp_lock_pid;
    if (h >= 0)
    {
        if (!global.mp_pconn[h])
            mp_lock_set(-1, "holder left");
        else
        {
            var inscene = h == global.mp_myid ? global.mp_sstate == 1 : (global.mp_pstate[h] & 2) != 0;
            if (inscene || (current_time - global.mp_lock_t) < 3000)
                global.mp_lock_free_n = 0;
            else if (++global.mp_lock_free_n > 90)
                mp_lock_set(-1, "holder no longer in a cutscene");
        }
    }
    for (var i = array_length(global.mp_lock_q) - 1; i >= 0; i--)
        if (!global.mp_pconn[global.mp_lock_q[i]])
            array_delete(global.mp_lock_q, i, 1);
    if (global.mp_lock_pid < 0 && array_length(global.mp_lock_q) > 0)
    {
        var want = global.mp_lock_q[0];
        var f = mp_lock_fighting(want);
        // (Waiting for someone's fight has a limit, like waiting for text: after 5 minutes the
        // scene goes on anyway.)
        if (!variable_global_exists("mp_lock_fw_pid") || global.mp_lock_fw_pid != want)
        {
            global.mp_lock_fw_pid = want;
            global.mp_lock_fw_t = current_time;
        }
        if (f < 0 || (current_time - global.mp_lock_fw_t) > 300000)
        {
            array_delete(global.mp_lock_q, 0, 1);
            global.mp_lock_fw_pid = -1;
            mp_lock_set(want, f < 0 ? "first in line" : "waited 5 minutes for " + global.mp_pname[f] + "'s fight");
        }
        else
            mp_lock_note(global.mp_pname[want] + " waits: " + global.mp_pname[f] + " is fighting");
    }
    if (global.mp_lock_bcast_t == 0 || (current_time - global.mp_lock_bcast_t) > 2000)
    {
        global.mp_lock_bcast_t = current_time;
        mp_begin(63);
        mp_ws8(global.mp_lock_pid);
        mp_wu16(global.mp_lock_ep);
        mp_send();
    }
}

function mp_lock_recv(type, from, b)
{
    if (type == 62)
    {
        buffer_read(b, buffer_u16);
        if (global.mp_role == 1)
            mp_lock_host_req(from);
        return;
    }
    if (type == 63)
    {
        var pid = buffer_read(b, buffer_s8);
        var ep = buffer_read(b, buffer_u16);
        if (global.mp_role == 1 || from != 0)
            return;
        if (pid != global.mp_lock_pid || ep != global.mp_lock_ep)
        {
            global.mp_lock_pid = pid;
            global.mp_lock_ep = ep;
            mp_lock_note(pid >= 0 ? "held by " + global.mp_pname[pid] : "free");
        }
        return;
    }
    if (type == 64)
    {
        if (global.mp_role == 1)
            mp_lock_host_drop(from);
        return;
    }
}

// Status line while my scene waits for the lock ("" when it doesn't).
function mp_lock_status()
{
    if (!global.mp_lock_waiting)
        return "";
    var h = global.mp_lock_pid;
    if (h >= 0 && h != global.mp_myid && h < 8)
        return global.mp_pname[h] + "'s scene is on: yours goes on after it";
    var f = mp_lock_fighting(global.mp_myid);
    if (f >= 0)
        return global.mp_pname[f] + " is in a fight: the scene goes on when it's over";
    return "";
}
