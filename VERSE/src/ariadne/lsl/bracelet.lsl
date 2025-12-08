float pulse = 0.1;//the time between each check, adjust it to your liking
//bigger == slower == low resources

//if a state isnt in the list its just ignored, you can add new overriding states here
list states = [];

//list of ther anims yo will use instead if the value == pass on, we let the anim play. One anim per state
list anims = [];

string anim_overrided= "";
string curr_anim= "";

float gSensorRange = 196.0;
float gSoundVolume = 0.8;

assignSL(string type, string name, string val){

list valOpts = llParseString2List(val,["|"],[]);


    if (type == "SLAnimation"){
        //val format: animation_name|duration|isLoop|loopCount|loopCtrls
        // Extract the animation name (first part before |)
        string animName = llList2String(valOpts, 0);

        llSay(0, "[BRACELET DEBUG] SLAnimation: name=" + name + ", animName=" + animName);

        integer foundstate = 0;
        integer n = llGetListLength(valOpts);
        integer i;
        for(i = 0; i < n; i++){
          if (i==4) { // any ctrls defined (index 4 in valOpts)
            list ctrl_val_list = llParseString2List(llList2String(valOpts, i),[","],[]);
            integer ll = llGetListLength(ctrl_val_list);
            integer j;
            for(j = 0; j < ll; j++){
                string curVal = llList2String(ctrl_val_list, j);
                if(llListFindList(ctrl_val_list,[curVal]) != -1){
                    // must add both, as array position must match... i think.
                    foundstate = 1;
                    anims += animName;
                    states += curVal;
                }
            }
          }
        }
        if (foundstate == 0){ // auto assign to default if no ctrls defined
            anims += animName;
            states += "Standing";
        }
        llSay(0, "[BRACELET DEBUG] Animation queued: " + animName + ", state: Standing");
        llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);//we ask for permissions
        jump out;
    }

    if (type == "SLBodypart"){
            llGiveInventory(llGetOwner(), name);
            llInstantMessage(llGetOwner(), name + " has been added to your inventory. "
                +"Drag it to appropriate area on your avatar to wear it. ");
        jump out;
    }

    if (type == "SLSound"){
        // llTriggerSound(name,gSoundVolume);
        // if duration > sound length
        //llLoopSound(name,gSoundVolume);
        llSetSoundQueueing(TRUE);
            //}

// TODO: bind to user controls
        llSetSoundRadius(gSensorRange);
        llTriggerSound(name, gSoundVolume);
        jump out;

    }

    if (type == "SLObject"){
            llGiveInventory(llGetOwner(),name);
            llInstantMessage(llGetOwner(), name + " has been added to your inventory. "
                +"Drag it to the ground to rez it");
        //llAttachToAvatar(integer);
        jump out;
    }

    if (type == "SLHud"){
            llGiveInventory(llGetOwner(), "hud "+name);
            llInstantMessage(llGetOwner(), "The "+ name +" HUD has been added to your inventory. "
                +"Please attach it to the " + val + "of your display.");
        jump out;
    }
    if (type == "SLPackage"){
            llGiveInventory(llGetOwner(), "crate "+name);
            llInstantMessage(llGetOwner(), "The " +name + " crate has been added to your inventory. "
                +"Drag it to the ground to rez it, and right-click to open it.");
        jump out;
    }
    if (type == "SLAction"){
        vector dest = (vector)("<"+llList2String(llParseString2List(val,["|"],[]),1)+">");
        do
        {
            llPushObject(llGetOwner(),(dest-llGetPos())*(llVecDist(llGetPos(),dest)),ZERO_VECTOR,FALSE); //Pushes the avatar to the position.
            llMoveToTarget(dest,0.05); //If your agent gets close to the avatar it will direct the path.
        }
        while(llVecDist(dest,llGetPos()) > 40.0);

        llMoveToTarget(dest,0.05);
        llSleep(0.25); //Prevents you from flying.
        llStopMoveToTarget();
        jump out;
    }
    if (type == "SLParticleSystem"){
       // llSay(0, "Particler sys str: :" +llDumpList2String(valOpts, ","));
        // if start run:
       // Particle_viewer_area_edition(valOpts);
       // if stop, run:
       // llParticleSystem ([]);
        jump out;
    }

    if (type == "SLLandmark"){
        llGiveInventory(llGetOwner(), name);
        llInstantMessage(llGetOwner(), "The " +name + " landmark has been added to your inventory.");
        jump out;
    }

    if (type == "SLTexture"){
        llGiveInventory(llGetOwner(), name);
        llInstantMessage(llGetOwner(), "The " +name + " texture has been added to your inventory.");
        jump out;
    }

    if (type == "SLClothing"){
        llGiveInventory(llGetOwner(), name);
       llInstantMessage(llGetOwner(), "The " +name + " apparel item has been added to your inventory.");
    }
     llResetScript();
    @out;
}



default
{
    attach(key id) {
        if(id == NULL_KEY && curr_anim != "")//IF detached and an animation is running
            llStopAnimation(curr_anim);
        else
            llResetScript();
    }
    state_entry(){
     llListen(603, "", NULL_KEY, "" );
     llListen(0, "", llGetOwner(), "" );
    }

    run_time_permissions(integer perms){
        if (perms & PERMISSION_TRIGGER_ANIMATION) {
            llSay(0, "[BRACELET DEBUG] Animation permission granted");
            // Start any queued animation immediately
            if (llGetListLength(anims) > 0) {
                string animToPlay = llList2String(anims, 0);
                llSay(0, "[BRACELET DEBUG] Playing queued animation: " + animToPlay);
                llStartAnimation(animToPlay);
                curr_anim = animToPlay;
            }
            llSetTimerEvent(pulse);
        }
    }

    timer(){
        string anim_state = llGetAnimation(llGetPermissionsKey());
        if(anim_state == "Turning Left" || anim_state == "Turning Right")//this is a little HACK to remove the turn left and right
            anim_state = "Standing";
        integer anim_index = llListFindList(states,[anim_state]);
        if((anim_index != -1) && (anim_overrided != anim_state))//IF we havent specified this anim must be ignored
        {
            anim_overrided = anim_state;
            //llSetText("",<1,1,1>,1.0);//DEBUG displaying the state
            if(llList2String(anims,anim_index) == "PASS_ON")
            {
                if(curr_anim != "")
                    llStopAnimation(curr_anim);
                curr_anim = "";
            } else {
                string stop_anim = curr_anim;
                curr_anim = llList2String(anims,anim_index);
                if(stop_anim != "")
                    llStopAnimation(stop_anim);

                if(curr_anim != stop_anim) { //if its the same anim we already play no need to change it
                    llSay(0, "[BRACELET DEBUG] Starting animation: " + curr_anim);
                    llStartAnimation(curr_anim);
                }

                if(anim_state == "Walking")//another lil hack so the av turn itself 180 when walking backward
                    llStopAnimation("walk");//comment these 2 lines if you have a real backward animation
            }
        }
    }

     listen (integer ch, string s, key k, string msg) {
        if (ch == 603){
            if( llSubStringIndex(msg, "~") > -1){
                llSay(0, "bracelet heard ya: "+ msg);
                list parts = llParseString2List(msg, ["~"], []);
                string iKey = llList2String(parts, 0);
                string itype =  llList2String(parts, 1);
                string iname = llList2String(parts, 2);
                string ival = llList2String(parts, 3);
                llSay(0, msg);
                if ( (string)llGetOwner() == iKey || iKey == llKey2Name(llGetOwner()) || iKey == "avatar" ){
                    llSay(0,"ya?");
                    assignSL(itype, iname, ival);
                }else{
                   //  llSay(0, "Doesn't apply to me: "+ iKey);
                }
            }else{
                if( llSubStringIndex(msg, "reset") > -1){
                    llSay(0, "resetting");
                   // llSetTimerEvent(0.0);
                    //llStopAnimation(curr_anim);
                    //curr_anim = "";
                    // states = [];
                    // anims = [];
                   llResetScript();
                   // llListen( -1, "", NULL_KEY, "" );
                    //llListen(0, "", llGetOwner(), "" );
                   llSleep(1);
                }
            }
        }
        if (ch == 0){
            if( llSubStringIndex(msg, "chose:") == 0){
                string thisOpt = llGetSubString(msg, 6, 7);
                llSay(0, thisOpt);
                llSay(687686, "option=" + thisOpt);
            }
        }
    }
} // END //