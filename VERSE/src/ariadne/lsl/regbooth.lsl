integer gSignupObjChannel = -8787;
integer button_channel = 8793;
integer quickPlay = 1; // where just showing up makes you eligible
string Rq_register;
string Rq_signup;
key currentSignupUserKey;

vector getObjectPositionVector(string objName){
    return <0,0,0>;
}

default
{
    state_entry()
    {
        llListen(button_channel, "", NULL_KEY, "");
        llListen(gSignupObjChannel, "", NULL_KEY, "");
    }

    touch_start(integer total_number)
    {
        currentSignupUserKey= llDetectedKey(0);

        if (!quickPlay){
            llSay(0, "sending plyr="+ llKey2Name(currentSignupUserKey)+"&plyrK="+(string)currentSignupUserKey);

            // add user to gPlayerList in Controller script
            llSay(gSignupObjChannel, "plyr=" + llKey2Name(currentSignupUserKey) + "&plyrK=" + (string)currentSignupUserKey );

            list buttons = ["signup","unsubscribe"];
            llDialog(currentSignupUserKey, "Sign-up?", buttons, button_channel);
        }else{
             llSay(0, "key: "+(string)currentSignupUserKey );
            Rq_register = llHTTPRequest("http://127.0.0.1:8080/ariadne/Users?action=register&aKey=" + (string)currentSignupUserKey + "&av="
            +llEscapeURL(llKey2Name(currentSignupUserKey)), [HTTP_METHOD,"POST"], "");
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {

        if (Rq_signup == request_id || request_id == Rq_register){
            if (llSubStringIndex(body, "ENLISTED") > -1){
                // give id?
                // give bracelet from inventory

                llGiveInventory(currentSignupUserKey, "nossum regional hospital bracelet 0.4");
                llInstantMessage(currentSignupUserKey, "nossum regional hospital bracelet 0.4 has been added to your inventory. "
                +"Attach it to your LEFT hand to enable it. Note: you must has RestrainedLife enabled. The bracelet only works on nossum island!");
            }

            if (llSubStringIndex(body,"REJECTED") > -1){
                llSay(0, "Sorry, we've either exceeded maximum capacity for this game, have shut "
                +"down the server or have found your avatar name on our banned list.");
            }
            // done with key
            currentSignupUserKey = NULL_KEY;
        }
    }

    listen(integer channel, string name, key id, string msg) {

        if (channel == button_channel){ // buttons from llDialog
            Rq_signup = llHTTPRequest("http://127.0.0.1:8080/ariadne/Users?api=" + msg+"&av="+llEscapeURL(llKey2Name(currentSignupUserKey)), [HTTP_METHOD,"POST"], "");
        }

        if (channel == gSignupObjChannel){
            //sendChatCommand(gSignupObjChannel, "nossum regional hospital bracelet 0.2~10.0"); // object scan for, the radius
            list parts = llParseString2List(msg, ["~"], []);
            if (llSubStringIndex((string)llList2String(parts, 0), "bracelet") > -1){
                //llSensor(llList2String(parts, 0), "","", (float)llList2String(parts, 1), TWO_PI);
            }
        }

    }

}