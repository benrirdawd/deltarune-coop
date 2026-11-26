// @chapters 2
// Stand-ins: a mechanic that needs a hero who isn't in the fight (TODO "a stand-in when the hero a
// mechanic needs isn't there").
//
// Queen with Berdly plugged in: Kris's Throw (Susie throws Kris at Berdly's wires) needs Kris.
// Without Kris, Susie gets her own Throw in her ACT list: she throws Ralsei, the game's own second
// throw (the one ThrowX ends with: same sprites, same wire targets, same mercy). Kris's Throw is
// free; Susie's costs 20% TP, so playing with Kris stays the better way.

function mp_queen_standin_ok()
{
    if (!variable_global_exists("mp_inited") || !mp_on())
        return false;
    // Who is in this fight: the party's places (a missing Kris still has an invisible stand-in object).
    var has = [0, 0, 0, 0, 0];
    for (var s = 0; s < 3; s++)
    {
        if (global.char[s] >= 1 && global.char[s] <= 4)
            has[global.char[s]] = 1;
    }
    if (has[1] || !has[2] || !has[3])
        return false;
    if (global.hp[2] <= 0 || global.hp[3] <= 0)
        return false;
    if (!instance_exists(obj_berdlyplug_enemy))
        return false;
    return !instance_exists(obj_queenshield_enemy) || obj_queenshield_enemy.shieldhurt == 2;
}

// From obj_queen_enemy's ACT refresh (User Event 1), before the magic menu is rebuilt.
function mp_queen_standin_acts()
{
    // Susie's and Ralsei's own ACT (Loosen / Toast) is only set up when Berdly is already plugged in
    // as the fight is built (the story's scene 25); an entry that plugs him in from Queen's Create
    // (test entry: encounter 59 at an earlier plot) would leave them without it.
    if (variable_global_exists("mp_inited") && mp_on() && instance_exists(obj_berdlyplug_enemy))
    {
        global.canactsus[myself][0] = 1;
        global.canactral[myself][0] = 1;
    }
    var on = mp_queen_standin_ok();
    if (on != global.canactsus[myself][1])
        mp_log("stand-in: Susie's Improvise (Throw) " + (on ? "in" : "out of") + " her ACT list, tp " + string(global.tension) + " myfight " + string(global.myfight) + " bmenuno " + string(global.bmenuno));
    global.canactsus[myself][1] = on;
    global.actnamesus[myself][1] = on ? "Improvise" : "";
    global.actdescsus[myself][1] = on ? "Throw#Ralsei" : "";
    global.actcostsus[myself][1] = on ? 50 : 0;
}

// From the top of obj_queen_enemy's Step: Susie's Throw starts the game's own throw (Kris's
// Throw, acting 3) with Ralsei as the thrown one.
function mp_queen_standin_step()
{
    if (global.myfight == 3 && actingsus == 2 && actconsus == 1)
    {
        actingsus = 0;
        actconsus = 0;
        if (mp_queen_standin_ok())
        {
            mp_ralthrow = 1;
            acting = 3;
            actcon = 0;
            mp_log("stand-in: Susie throws Ralsei at the wires (wires cut so far " + string(wirescut) + ", Berdly mercy " + string(bardlymercy) + ")");
        }
        else
        {
            actcon = 1;
        }
    }
}

// Right after obj_queen_enemy makes the throw (obj_queen_throwkris): skip Kris, go straight to
// Ralsei landing on Susie's shoulders, then the aim.
function mp_queen_throw_made(t)
{
    if (!variable_instance_exists(id, "mp_ralthrow") || !mp_ralthrow)
        return;
    mp_ralthrow = 0;
    t.throwXcon = 2;
    t.throwcon = 0;
    t.mp_solo = 1;
    with (obj_heroralsei)
        visible = 0;
}

// The thrown Ralsei comes back to Kris's place; without Kris, to Susie's.
function mp_queen_kris_x()
{
    if (instance_exists(obj_herokris))
        return obj_herokris.x;
    return obj_herosusie.x;
}

function mp_queen_kris_depth()
{
    if (instance_exists(obj_herokris))
        return obj_herokris.depth;
    return obj_herosusie.depth;
}
