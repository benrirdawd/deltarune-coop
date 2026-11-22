// Money and the bag (items, weapons, armour) are shared differently from the rest of the story
// state: two players shopping at the same time must both get what they paid for.
//
// Money goes out as changes ("-50"), never as a total, so changes made at the same time add up.
// The bag goes out as what came in and what went out of it ("+ Dark Candy, - Tension Bit"): the
// host applies those in the order they arrive (taking each item into the first empty slot, so two
// players never fill the same one) and sends everyone its bag back as it stands. A client puts its
// own changes the host hasn't taken yet back on top of that.
//
// Messages: 22 money change (f64), 23 bag changes (client -> host: u16 seq, then per list u8 list,
// u8 n out + values, u8 n in + values, ending with 255), 24 the host's bag (u16 the seq it has taken
// from that client, then per list u8 list, u8 n + values, ending with 255).

function mp_inv_lists()
{
    return ["item", "weapon", "armor", "litem"];
}

// Is this shared-state variable handled here (and not by mp_vars_send_changes)?
function mp_inv_owns(nm)
{
    return nm == "gold" || nm == "item" || nm == "weapon" || nm == "armor" || nm == "litem";
}

function mp_inv_init()
{
    global.mp_inv_sh = array_create(4, -1);   // the bag as last sent / taken, per list
    global.mp_inv_seq = 0;
    global.mp_inv_pending = [];               // my changes the host hasn't taken yet: [seq, ops]
    global.mp_inv_host_state = -1;            // the host's bag, to take when I can
    global.mp_inv_hostq = ds_list_create();   // host: clients' changes to take, [pid, seq, ops]
    global.mp_inv_acked = array_create(8, 0); // host: last seq taken from each player
    global.mp_inv_needreset = true;
    global.mp_gold_sh = 0;
    global.mp_gold_pending = 0;
}

// After a full snapshot or a load: what I have now is the starting point.
function mp_inv_reset()
{
    var L = mp_inv_lists();
    for (var k = 0; k < array_length(L); k++)
        global.mp_inv_sh[k] = mp_inv_copy(L[k]);
    global.mp_inv_pending = [];
    global.mp_inv_host_state = -1;
    global.mp_gold_sh = variable_global_exists("gold") ? global.gold : 0;
    global.mp_gold_pending = 0;
}

function mp_inv_copy(nm)
{
    if (!variable_global_exists(nm))
        return -1;
    var a = variable_global_get(nm);
    if (!is_array(a))
        return -1;
    var c = array_create(array_length(a), 0);
    array_copy(c, 0, a, 0, array_length(a));
    return c;
}

// What went out of / came into list a since sh, as [outs, ins] (each item once per copy).
function mp_inv_diff(sh, a)
{
    var left = [];
    for (var i = 0; i < array_length(sh); i++)
    {
        if (sh[i] != 0)
            array_push(left, sh[i]);
    }
    var ins = [];
    for (var j = 0; j < array_length(a); j++)
    {
        if (a[j] == 0)
            continue;
        var found = false;
        for (var k = 0; k < array_length(left); k++)
        {
            if (left[k] == a[j])
            {
                array_delete(left, k, 1);
                found = true;
                break;
            }
        }
        if (!found)
            array_push(ins, a[j]);
    }
    return [left, ins];
}

// Applies [outs, ins] to the game's list nm: each item out leaves its slot and the rest move up
// (as using an item does); each item in takes the first empty slot (dropped if the bag is full).
function mp_inv_apply_ops(nm, outs, ins)
{
    if (!variable_global_exists(nm))
        return;
    var a = variable_global_get(nm);
    if (!is_array(a))
        return;
    var n = array_length(a);
    for (var u = 0; u < array_length(outs); u++)
    {
        for (var i = 0; i < n; i++)
        {
            if (a[i] == outs[u])
            {
                for (var k = i; k < (n - 1); k++)
                    mp_var_array_write(nm, k, a[k + 1]);
                mp_var_array_write(nm, n - 1, 0);
                break;
            }
        }
    }
    for (var g = 0; g < array_length(ins); g++)
    {
        for (var j = 0; j < n; j++)
        {
            if (a[j] == 0)
            {
                mp_var_array_write(nm, j, ins[g]);
                break;
            }
        }
    }
}

// Every shared-state tick (mp_vars_tick, only when nothing is in the way).
function mp_inv_tick()
{
    if (global.mp_inv_needreset)
    {
        global.mp_inv_needreset = false;
        mp_inv_reset();
        return;
    }
    mp_gold_tick();
    var L = mp_inv_lists();
    // My own changes first.
    var ops = [];
    var changed = false;
    var reordered = false;
    for (var k = 0; k < array_length(L); k++)
    {
        var cur = mp_inv_copy(L[k]);
        var sh = global.mp_inv_sh[k];
        if (!is_array(cur) || !is_array(sh) || array_length(cur) != array_length(sh))
        {
            global.mp_inv_sh[k] = cur;
            array_push(ops, -1);
            continue;
        }
        var d = mp_inv_diff(sh, cur);
        array_push(ops, d);
        if (array_length(d[0]) > 0 || array_length(d[1]) > 0)
            changed = true;
        if (!array_equals(sh, cur))
            reordered = true;
        global.mp_inv_sh[k] = cur;
    }
    if (global.mp_role == 1)
    {
        // Host: take the clients' changes in the order they came, then tell everyone.
        var took = false;
        while (ds_list_size(global.mp_inv_hostq) > 0)
        {
            var e = ds_list_find_value(global.mp_inv_hostq, 0);
            ds_list_delete(global.mp_inv_hostq, 0);
            var eops = e[2];
            for (var k2 = 0; k2 < array_length(L) && k2 < array_length(eops); k2++)
            {
                if (is_array(eops[k2]))
                    mp_inv_apply_ops(L[k2], eops[k2][0], eops[k2][1]);
            }
            global.mp_inv_acked[e[0]] = e[1];
            took = true;
        }
        if (took || reordered)
        {
            for (var k3 = 0; k3 < array_length(L); k3++)
                global.mp_inv_sh[k3] = mp_inv_copy(L[k3]);
            mp_inv_send_state();
        }
        return;
    }
    if (changed)
    {
        global.mp_inv_seq += 1;
        array_push(global.mp_inv_pending, [global.mp_inv_seq, ops]);
        mp_begin(23);
        mp_wu16(global.mp_inv_seq);
        for (var k4 = 0; k4 < array_length(ops); k4++)
        {
            if (!is_array(ops[k4]))
                continue;
            mp_wu8(k4);
            mp_inv_wlist(ops[k4][0]);
            mp_inv_wlist(ops[k4][1]);
        }
        mp_wu8(255);
        mp_send();
        mp_log("bag: sent changes " + string(global.mp_inv_seq));
    }
    // Client: the host's bag, with my changes it hasn't taken yet put back on top.
    var hs = global.mp_inv_host_state;
    if (is_array(hs))
    {
        global.mp_inv_host_state = -1;
        var ack = hs[0];
        var lists = hs[1];
        for (var k5 = 0; k5 < array_length(L) && k5 < array_length(lists); k5++)
        {
            var hl = lists[k5];
            if (!is_array(hl) || !variable_global_exists(L[k5]))
                continue;
            var mine = variable_global_get(L[k5]);
            if (!is_array(mine))
                continue;
            for (var i = 0; i < array_length(mine); i++)
                mp_var_array_write(L[k5], i, i < array_length(hl) ? hl[i] : 0);
        }
        var keep = [];
        for (var p = 0; p < array_length(global.mp_inv_pending); p++)
        {
            var pe = global.mp_inv_pending[p];
            if (pe[0] <= ack)
                continue;
            array_push(keep, pe);
            for (var k6 = 0; k6 < array_length(L) && k6 < array_length(pe[1]); k6++)
            {
                if (is_array(pe[1][k6]))
                    mp_inv_apply_ops(L[k6], pe[1][k6][0], pe[1][k6][1]);
            }
        }
        global.mp_inv_pending = keep;
        for (var k7 = 0; k7 < array_length(L); k7++)
            global.mp_inv_sh[k7] = mp_inv_copy(L[k7]);
    }
}

function mp_inv_wlist(a)
{
    var n = min(array_length(a), 60);
    mp_wu8(n);
    for (var i = 0; i < n; i++)
        mp_wval(a[i]);
}

function mp_inv_rlist(b)
{
    var n = buffer_read(b, buffer_u8);
    var a = array_create(n, 0);
    for (var i = 0; i < n; i++)
        a[i] = mp_rval(b);
    return a;
}

// Host: everyone gets my bag, with the last change of theirs it includes.
function mp_inv_send_state()
{
    var L = mp_inv_lists();
    var k = ds_map_find_first(global.mp_peers);
    while (!is_undefined(k))
    {
        var p = ds_map_find_value(global.mp_peers, k);
        k = ds_map_find_next(global.mp_peers, k);
        if (!is_struct(p) || !variable_struct_exists(p, "pid"))
            continue;
        mp_begin(24);
        mp_wu16(global.mp_inv_acked[p.pid]);
        for (var j = 0; j < array_length(L); j++)
        {
            var a = mp_inv_copy(L[j]);
            if (!is_array(a))
                continue;
            mp_wu8(j);
            mp_inv_wlist(a);
        }
        mp_wu8(255);
        mp_send_to(p);
    }
}

// Money: my change since the last one went out.
function mp_gold_tick()
{
    if (!variable_global_exists("gold"))
        return;
    if (global.mp_gold_pending != 0)
    {
        global.gold += global.mp_gold_pending;
        global.mp_gold_sh += global.mp_gold_pending;
        global.mp_gold_pending = 0;
    }
    var d = global.gold - global.mp_gold_sh;
    if (d == 0)
        return;
    global.mp_gold_sh = global.gold;
    mp_begin(22);
    mp_wu8(global.mp_myid);
    mp_wf64(d);
    mp_send();
}

function mp_inv_recv(type, from, b)
{
    if (type == 22)
    {
        var who = buffer_read(b, buffer_u8);
        var d = buffer_read(b, buffer_f64);
        // (Taken at the next tick, when nothing is in the way: a fight puts money back at its end.)
        global.mp_gold_pending += d;
        if (global.mp_role == 1)
            mp_inv_forward(from, who, d);
        return;
    }
    if (type == 23)
    {
        if (global.mp_role != 1 || from < 0 || from >= 8)
            return;
        var seq = buffer_read(b, buffer_u16);
        var ops = array_create(4, -1);
        var k = buffer_read(b, buffer_u8);
        while (k != 255)
        {
            var outs = mp_inv_rlist(b);
            var ins = mp_inv_rlist(b);
            if (k < 4)
                ops[k] = [outs, ins];
            k = buffer_read(b, buffer_u8);
        }
        ds_list_add(global.mp_inv_hostq, [from, seq, ops]);
        return;
    }
    if (type == 24)
    {
        if (global.mp_role != 2)
            return;
        var ack = buffer_read(b, buffer_u16);
        var lists = array_create(4, -1);
        var k2 = buffer_read(b, buffer_u8);
        while (k2 != 255)
        {
            var a = mp_inv_rlist(b);
            if (k2 < 4)
                lists[k2] = a;
            k2 = buffer_read(b, buffer_u8);
        }
        global.mp_inv_host_state = [ack, lists];
    }
}

// Host: a player's money change goes on to everyone else.
function mp_inv_forward(from, who, d)
{
    var k = ds_map_find_first(global.mp_peers);
    while (!is_undefined(k))
    {
        var p = ds_map_find_value(global.mp_peers, k);
        k = ds_map_find_next(global.mp_peers, k);
        if (!is_struct(p) || !variable_struct_exists(p, "pid") || p.pid == from)
            continue;
        mp_begin(22);
        mp_wu8(who);
        mp_wf64(d);
        mp_send_to(p);
    }
}
