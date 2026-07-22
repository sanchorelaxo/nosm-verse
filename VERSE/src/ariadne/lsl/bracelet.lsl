// Ariadne Bracelet Script - OpenSimulator Edition
// Uses osAvatarPlayAnimation for reliable animation playback (no permission needed)
// Requires OSSL functions enabled in OpenSim.ini

float gSensorRange = 196.0;
float gSoundVolume = 0.8;

// Current animation tracking
string curr_anim = "";

assignSL(string type, string name, string val) {
    list valOpts = llParseString2List(val, ["|"], []);
    key owner = llGetOwner();

    if (type == "SLAnimation") {
        // Extract the animation name (first part before |)
        string animName = llList2String(valOpts, 0);
        llSay(0, "[BRACELET DEBUG] SLAnimation: name=" + name + ", animName=" + animName);
        
        // Stop current animation if playing
        if (curr_anim != "") {
            llSay(0, "[BRACELET DEBUG] Stopping previous animation: " + curr_anim);
            osAvatarStopAnimation(owner, curr_anim);
        }
        
        // Play new animation using OSSL function (no permission needed!)
        llSay(0, "[BRACELET DEBUG] Playing animation via osAvatarPlayAnimation: " + animName);
        osAvatarPlayAnimation(owner, animName);
        curr_anim = animName;
        jump out;
    }

    if (type == "SLBodypart") {
        llGiveInventory(owner, name);
        llInstantMessage(owner, name + " has been added to your inventory. "
            + "Drag it to appropriate area on your avatar to wear it.");
        jump out;
    }

    if (type == "SLSound") {
        llSetSoundQueueing(TRUE);
        llSetSoundRadius(gSensorRange);
        // val contains the sound UUID
        llSay(0, "[BRACELET DEBUG] Playing sound: " + name + " (UUID: " + val + ")");
        llTriggerSound(val, gSoundVolume);
        jump out;
    }

    if (type == "SLObject") {
        llGiveInventory(owner, name);
        llInstantMessage(owner, name + " has been added to your inventory. "
            + "Drag it to the ground to rez it");
        jump out;
    }

    if (type == "SLHud") {
        llGiveInventory(owner, "hud " + name);
        llInstantMessage(owner, "The " + name + " HUD has been added to your inventory. "
            + "Please attach it to the " + val + " of your display.");
        jump out;
    }

    if (type == "SLPackage") {
        llGiveInventory(owner, "crate " + name);
        llInstantMessage(owner, "The " + name + " crate has been added to your inventory. "
            + "Drag it to the ground to rez it, and right-click to open it.");
        jump out;
    }

    if (type == "SLAction") {
        vector dest = (vector)("<" + llList2String(llParseString2List(val, ["|"], []), 1) + ">");
        do {
            llPushObject(owner, (dest - llGetPos()) * (llVecDist(llGetPos(), dest)), ZERO_VECTOR, FALSE);
            llMoveToTarget(dest, 0.05);
        } while (llVecDist(dest, llGetPos()) > 40.0);
        llMoveToTarget(dest, 0.05);
        llSleep(0.25);
        llStopMoveToTarget();
        jump out;
    }

    if (type == "SLParticleSystem") {
        // Particle system handling - placeholder
        jump out;
    }

    if (type == "SLLandmark") {
        llGiveInventory(owner, name);
        llInstantMessage(owner, "The " + name + " landmark has been added to your inventory.");
        jump out;
    }

    if (type == "SLTexture") {
        llGiveInventory(owner, name);
        llInstantMessage(owner, "The " + name + " texture has been added to your inventory.");
        jump out;
    }

    if (type == "SLClothing") {
        llGiveInventory(owner, name);
        llInstantMessage(owner, "The " + name + " apparel item has been added to your inventory.");
        jump out;
    }

    @out;
}

default {
    attach(key id) {
        if (id == NULL_KEY && curr_anim != "") {
            // Detached - stop any running animation
            osAvatarStopAnimation(llGetOwner(), curr_anim);
            curr_anim = "";
        } else if (id != NULL_KEY) {
            llResetScript();
        }
    }

    state_entry() {
        llSay(0, "[BRACELET DEBUG] Bracelet initialized (OpenSimulator OSSL version)");
        llListen(603, "", NULL_KEY, "");  // Asset delivery channel
        llListen(0, "", llGetOwner(), ""); // Owner chat for commands
    }

    listen(integer ch, string name, key id, string msg) {
        if (ch == 603) {
            if (llSubStringIndex(msg, "~") > -1) {
                llSay(0, "[BRACELET DEBUG] Received on ch 603: " + msg);
                list parts = llParseString2List(msg, ["~"], []);
                string iKey = llList2String(parts, 0);
                string itype = llList2String(parts, 1);
                string iname = llList2String(parts, 2);
                string ival = llList2String(parts, 3);
                
                // Check if this message is for us (owner or "avatar" target)
                if ((string)llGetOwner() == iKey || iKey == llKey2Name(llGetOwner()) || iKey == "avatar") {
                    llSay(0, "[BRACELET DEBUG] Processing asset: type=" + itype + ", name=" + iname);
                    assignSL(itype, iname, ival);
                }
            } else if (llSubStringIndex(msg, "reset") > -1) {
                llSay(0, "[BRACELET DEBUG] Reset command received");
                if (curr_anim != "") {
                    osAvatarStopAnimation(llGetOwner(), curr_anim);
                    curr_anim = "";
                }
                llResetScript();
            }
        }
        
        if (ch == 0) {
            // Handle owner chat commands (e.g., "chose:XX")
            if (llSubStringIndex(msg, "chose:") == 0) {
                string thisOpt = llGetSubString(msg, 6, 7);
                llSay(0, thisOpt);
                llSay(687686, "option=" + thisOpt);
            }
        }
    }
}
