integer gUseNewParser = TRUE;
string cTestURL = "http://127.0.0.1:8080/ariadne/api/node";

string cRootNode= "ariadne";

string cSIDName = "session";
string cSSID = "id";
string cServerType = "type";

string cNodeName = "node";
string cNodeId = "id";
string cNodeLabel = "label";

string cAsset = "asset";
string cAssetType = "type";
string cAssetName = "name";
string cAssetTarget = "target";
string cAssetId = "iid";

string cLink = "link";
string cLinkLabel = "label";
string cLinkRef = "ref";

list knownItems = []; // make sure to reset these arrays!
list knownSets = [];

list gPlayerList;
list gPlayerRoleList;
list gPlayerAgentKeyList;

// END newParser constants

// ******** GLOBAL VARS ********

vector txtcol = <1,1,1>;
float txtalpha = 1.0;

integer gOffset;
integer gBlock = 5;
string gPage = "node";

integer lh;
integer lhd;
integer lhc;
//key mediakey;
//integer mediamode;
string localtext;

string gNodeLabel;
string gNodeDesc;
string gNodeImage;
string gNodeMedia;
string gNodeOptions;
string gSSID;
string gPIVOTEPrefix;

integer gQuickStart=FALSE;
integer gQuickOption=FALSE;

string gStartCommands;
string gEndCommands;
string gResetCommands;

//holodeck stuff
string gScene;
string gShell;

float gSensorRange = 196.0;
float gSoundVolume = 0.8;
string gCurrentSceneStatus;

integer gHolodeckChatChannel = 9993;
integer gHolodeckAPIChannel = -9993;

integer gSignupObjChannel = -8787;

integer gPIVOTEChannel = 687686; // different for each master within 20m - MUST CHANGE ALL OBJECTS
integer gMediaCh = -63342;
//integer gFauxIMChannel = -696969; // never gets used as channel, just a mask

integer gPlayerTrackingObjChannel = 603; // bracelet
//integer gQuizChannel = 555;

// newParser globals
string gServerType;
list assetTypes;
list assetNames;
list assetTargets;
list assetValues;
list assetIds;
list linkLabels;
list linkRefs;

list orderedAssets;

string gServiceUID = "";
string gServicePwd = "";

string gTutorGroupID="";
string gControllerName="";

// configs
integer gShowNodeLabel=FALSE;
string gFilter = "";

string gServiceURL;
string gServicePageURL;
string gHelpURL;
string gMenuURL;
//string gIdleURL;
string gUpdatingURL;
string gQSParserPageURL = "http://142.51.75.11/ariadne4j/show.html";
string gObjectBox = "PIVOTE Paramedic Equipment Box 1.0";
integer gShowHUD=TRUE;
integer gShowObjects=TRUE;
integer gShowSession=TRUE;

integer gAutoShow = FALSE;
integer gAutoShowTime = 5;
key gUserKey = NULL_KEY;

string gNode = "";
string oldNode = "";
string urlroot;

string gCase;
list gOptions;
string gExerciseList = "";

key Rq_getnode;
key Rq_getpage;

key Ds_getLine;
key XMLParser_getLine;
string gConfigCard = "pivotecontroller.cfg";
string gXMLConfigCard = "feedparserconstants.cfg";
integer gLine;
integer gXMLParserLine;

key prekey;
key PatientAgentKey;
key PlayerAgentKey;

//string Characters = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
string Letters= "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
string Numbers = "0123456789";

// ******** END GLOBAL VARS ********

// ******** FUNCTIONS ********

string str_replace(string src, string from, string to){
    return llDumpList2String(llParseStringKeepNulls((src = "") + src, [from], []), to);
}

string getAssetAttribValById(string assetId, string attrib){
    integer nAssets = llGetListLength(assetIds);
    integer i;
    for (i = 0; i < nAssets; i++) {
        if (assetId == llList2String(assetIds,i)){
            if (attrib == "target"){
                return llList2String(assetTargets,i);
            }else{
                if (attrib == "value"){
                    return llList2String(assetValues,i);
                }else{
                    if (attrib == "name"){
                        return llList2String(assetNames,i);
                    }else{
                        return llList2String(assetTypes,i);
                    }
                }
            }
        }
    }
    return "";
}

string xtraktSeq (string stream, string type, string attrib) {
    string param;
    integer sts = llSubStringIndex(stream, type);

    string chunk =  llGetSubString(stream,sts,-1);
    string attribChunk = llGetSubString(chunk,llStringLength(type),llSubStringIndex(chunk, "/>") - 1);// truncate to front of said caret...
    if (llSubStringIndex(attribChunk, attrib) > -1){
        string myAttribChunk = llGetSubString(attribChunk,llSubStringIndex(attribChunk, attrib + "=\"") + llStringLength(attrib + "=\""),-1);
        param = llGetSubString(myAttribChunk, 0, llSubStringIndex(myAttribChunk, "\"")- 1); // grab everything before the first double-quote
    }else{
        param = "";
    }

   // llWhisper(0, "XMLextractAttribByTag: p:"+param);
    return param;
}

key getKeyforPlayerName(string target){

    key response = NULL_KEY;
    integer nPlayers = llGetListLength(gPlayerList);
    integer j;
    for (j = 0; j < nPlayers; j++) {
        if (llList2String(gPlayerList,j) == target){
            response = (key)llList2String(gPlayerAgentKeyList,j);
        }
    }
    return response;
}

integer OnlyContains(string a, string b){
    integer len = llStringLength(a);
    integer result = FALSE;
    if(len != 0) {
        result = TRUE;
        integer index = 0;
        do {
            string chara = llGetSubString(a,index,index);
            integer posa = llSubStringIndex(b,chara);
            if(posa < 0){
                result = FALSE;
                index = len;
            }
            ++index;
        }
        while(index < len);
    }
    return result;
}

integer IsNumeric(string a){
    return OnlyContains(a,Numbers);
}

integer IsAlpha(string a){
    return OnlyContains(a,Letters);
}

integer IsAlphanumeric(string a){
    return OnlyContains(a,Letters + Numbers);
}

assignSL(string type, string target, string name, string val, integer duration){

    //  Show patient text , a dynamic chart, real-life map, Second Life region on parcel viewer(s)
     if (type == "SLAudio" || type == "VPDImage" || type == "VPDMedia"  || type == "SLGoogleAPIImage" || type == "SLGoogleAPIHTML" ||
       type == "SLAmazonMapImage"){
        sendChatCommand(gMediaCh, llList2String(llParseString2List(val, ["~"], []), 0));
        llSleep(4.0); // show this url for a while at least...
        jump out;
    }

    if (type == "VPDImage"){ //  Show an external patient image on parcel viewer(s)
        gNodeImage = llList2String(llParseString2List(val, ["~"], []), 0);
        option_media();
        llSleep(4.0); // show this url for a while at least...
        jump out;
    }

    if (type == "VPDMedia"){ //  Show an external patient movie on parcel viewer(s)
        gNodeMedia = llList2String(llParseString2List(val, ["~"], []), 0);
        option_media();
        llSleep(4.0); // show this url for a while at least...
        jump out;
    }

    if (type == "SLAnimation"){
        //target = "27811330-3bb6-447e-a2b7-dffd322279a3"; // hard coded key for openSim
        sendChatCommand(gPlayerTrackingObjChannel, target+"~"+type+"~"+name+"~"+ val + "|gla3");
        jump out;
    }

    if (type == "SLBodypart" || type == "SLHud" || type == "SLTexture" || type == "SLPackage"
            || type == "SLLandmark" || type == "SLNotecard" || type == "SLClothing"){

        sendChatCommand(gPlayerTrackingObjChannel, target+"~"+ type+"~"+name); // target=avatar, name should be llGetObjectName()
        jump out;
    }

    if (type == "SLSound" || type == "SLObject" || type == "SLExtFeedObject" || type == "SLParticleSystem"){
            sendChatCommand(gPlayerTrackingObjChannel,
                target +"~" + type +"~" + name + "~" +  val); // targets aren't nec avs, could be: vector<x,y,z>, objectName
        jump out;
    }

    if (type == "SLChat"){
       // llSay(0, "chatting this: "+ val);
        sendChatCommand((integer)target, llList2String(llParseString2List(val, ["~"], []), 0));
        jump out;
    }

    if (type == "SLIM"){
        list parts = llParseString2List(target+"~"+val, ["~"], []);
        llInstantMessage((key)llList2String(parts, 0), llList2String(parts, 1));
        jump out;
    }

    if (type == "RLAnimation"|| type == "RLObject"|| type == "RLChat"|| type == "RLAction"|| type == "RLNotecard"
    ||  type == "RLTexture"|| type == "RLClothing"|| type == "RLIM"|| type == "RLHud"|| type == "RLSys"){

       // sendChatCommand(gPlayerTrackingObjChannel, target+"~"+val);
       // sendChatCommand(gPlayerTrackingObjChannel, target+"~"+ type+"~"+name+"~"+ val); // targets aren't nec avs
       // sendChatCommand(gPlayerTrackingObjChannel, target+"~"+ type+"~"+name);

        sendChatCommand((integer)target, llList2String(llParseString2List(val, ["~"], []), 0));

    }

    @out;
}

resetParserConstants(){
    cNodeId= cSSID;
    cLinkLabel = cNodeLabel;
    knownItems = [cSSID, cNodeName];
    knownSets = [cAsset, cLink, cNodeName, cSIDName ];
}

resetElementsFull(){
    resetElements();
    linkLabels = [];
    linkRefs = [];
}


resetElements(){
    //gSSID = ""; // do we wanna do this?
    gServerType = "";

    gNode = "";
    gNodeLabel = "";
    gScene = "";
    gShell = "";

    //gOptions = [];

    assetTypes = [];
    assetNames = [];
    assetTargets = [];
    assetValues = [];
    assetIds = [];//cAssetId

    gNodeDesc= "";
    gNodeImage= "";
    gNodeMedia= "";
    gNodeOptions= "";

}

string ampSepChar = "&amp;";

parseFeed(string body){

    list lines = llParseString2List(body, ["\"/>", "/>", "<", ">", "\n"], []);
    // loop through elements
    integer n = llGetListLength(lines);
    integer i;
    for(i = 0; i < n; i++){

        //string line = llToLower(llList2String(lines, i));
        string line = llList2String(lines, i);
        /// if root - new feed
        if(llSubStringIndex(line,cRootNode + " xmlns:xsi") > -1){
            resetElementsFull();
            //return;
        }
        string element = llGetSubString(line, 0, llSubStringIndex(line, " ") - 1);
        line =llGetSubString(line, llStringLength(element) + 1, -1);

        list parts = llParseString2List(line, ["=\"", "\" "], []);
        integer n2 = llGetListLength(parts);
        integer i2;

        for(i2 = 0; i2 < n2; i2 += 2){
            string name = llList2String(parts, i2);
            string value = llList2String(parts, i2 + 1);
            // nodeSets attribs:
            if(element == cAsset){
                //stridedAssetsList  = (stridedAssetsList=[]) + stridedAssetsList + [value];
                //if(name == cAssetType) assetTypes = (assetTypes=[]) + assetTypes + [value];

                if(name == cAssetId) assetIds += [value];

                if(name == cAssetType) assetTypes += [value];

                //if(name == cAssetName) assetNames = (assetNames=[]) + assetNames + [value];
                if(name == cAssetName) assetNames += [value];

                //if(name == cAssetTarget)assetTargets = (assetTargets=[]) + assetTargets + [value];
                if(name == cAssetTarget) assetTargets += [value];

                //if(name == "value") {
                    // llSay(0, "there is a value!" + value );
                    // assetValues = (assetValues=[]) + assetValues + [value];
                    //}
                if(name == "value") assetValues += [value];
            }

            if(element == cLink){

                // if(name == cLinkLabel) linkLabels = (linkLabels=[]) + linkLabels + [value];

                if(name == cLinkLabel) linkLabels += [value];
                // if(name == cLinkRef) linkRefs = (linkRefs=[]) + linkRefs + [value];
                if(name == cLinkRef) linkRefs += [value];
                //llSay(0, "links: " + value);
            }

            // single nodes attribs:
            if(element == cSIDName){
                if(name == cSSID) {
                    if (gSSID == value){
                        llSay(0, "SSIDs match: "+gSSID+". Continuing session...");
                    }else{
                        if (gSSID != ""){ // first timer
                        //llSay(0, "1st request for this session");
                        // node must be == start
                             llSay(0, "SSID 1st set: "+gSSID);
                            gSSID = value;
                        }else{
                            //llSay(0,"gSSID"+gSSID);
                            llSay(0, "SSIDx present: "+value+","+ gSSID+", but does not match. What happened?");
                        }
                    }
                }
                if(name == cServerType) gServerType = value;
            }

            if(element == cNodeName){
                if(name == cNodeId){
                    if (gNode != "")oldNode = gNode;
                    gNode = value;
                }
                if(name == cNodeLabel) gNodeLabel = value;
            }
            // TODO: counters!!
        }

    }
   // llSay(0, "in linkLabels " + llList2CSV(linkLabels));
   // llSay(0, "in linkRefs " + llList2CSV(linkRefs));
   // llSay(0, "in assetTypes " + llList2CSV(assetTypes));
   // llSay(0, "in assetValues " + llList2CSV(assetValues));
   // llSay(0, "in assetTargets " + llList2CSV(assetTargets));
   // llSay(0, "in assetNames " + llList2CSV(assetNames));
}

sendChatCommand (integer channel, string cmd) {
    if (channel == -11674){
        llInstantMessage(llList2String(llParseString2List(cmd, ["~"], []), 0), llList2String(llParseString2List(cmd, ["~"], []), 1));
    }else{
        if (channel == gPIVOTEChannel && gPIVOTEPrefix != ""){
            cmd = gPIVOTEPrefix+":"+ cmd;
        }
    }
    llSay(channel, cmd);
}

parserConfig_load(string p, string v) {
    if (p == "xmllabel.RootNode") {
        cRootNode= v;
        jump out;
    }
    if (p == "xmllabel.SIDName") {
        cSIDName = v;
        jump out;
    }
    if (p == "xmlitem.SSID") {
        cSSID= v;
        jump out;
    }
    if (p == "xmllabel.ServerType") {
        cServerType = v;
        jump out;
    }
    if (p == "xmlitem.NodeName") {
        cNodeName = v;
        jump out;
    }
    if (p == "xmllabel.NodeLabel") {
        cNodeLabel = v;
        jump out;
    }
    if (p == "xmlset.Asset") {
        cAsset = v;
        jump out;
    }
    if (p == "xmllabel.AssetType") {
        cAssetType = v;
        jump out;
    }
    if (p == "xmllabel.AssetName") {
        cAssetName = v;
        jump out;
    }
    if (p == "xmllabel.AssetTarget") {
        cAssetTarget = v;
        jump out;
    }
    if (p == "xmlset.Link") {
        cLink = v;
        jump out;
    }
    if (p == "xmllabel.LinkRef") {
        cLinkRef = v;
    }
    @out;

}

config_load(string p, string v) {
    if (p == "gShowNodeLabel") {
        gShowNodeLabel = TRUE;
        if (v == "FALSE") {
            gShowNodeLabel = FALSE;
        }
        jump out;
    }
    if (p == "gShowHUD") {
        gShowHUD = TRUE;
        if (v == "FALSE") {
            gShowHUD = FALSE;
            set_button("hud", "hide");
        } else {
            set_button("hud", "show");
        }
        jump out;
    }
    if (p == "gShowObjects") {
        gShowObjects = TRUE;
        if (v == "FALSE") {
            gShowObjects = FALSE;
            set_button("objects", "hide");
        } else {
            set_button("objects", "show");
        }
        jump out;
    }
    if (p == "gShowSession") {
        gShowSession = FALSE;
        if (v == "TRUE") { gShowSession = TRUE;}
        jump out;
    }
    if (p == "gServiceURL") {
        gServiceURL = v;
        jump out;
    }
    if (p == "gServicePageURL") {
        gServicePageURL = v;
        jump out;
    }
    if (p == "gHelpURL") {
        gHelpURL = v;
        jump out;
    }
    if (p == "gMenuURL") {
        gMenuURL = v;
        jump out;
    }
    if (p == "gUpdatingURL") {
        gUpdatingURL = v;
        jump out;
    }
    if (p == "gFilter") {
        gFilter = llEscapeURL(v);
        jump out;
    }
    if (p == "gExerciseList") {
        gExerciseList = v;
        jump out;
    }
    if (p == "gPIVOTEChannel") {
        gPIVOTEChannel = (integer)v;
        jump out;
    }
    if (p == "gPIVOTEPrefix") {
        gPIVOTEPrefix = v;
        jump out;
    }
    if (p == "gMediaCh") {
        gMediaCh = (integer)v;
        jump out;
    }
    if (p == "gQuickStart") {
        gQuickStart=FALSE;
        if (v == "TRUE") { gQuickStart = TRUE;}
        jump out;
    }
    if (p == "gQuickOption") {
        gQuickOption=FALSE;
        if (v == "TRUE") { gQuickOption = TRUE;}
        jump out;
    }

    if (p == "gServiceUID") {
        gServiceUID = v;
        jump out;
    }
    if (p == "gServicePwd") {
        gServicePwd = v;
        jump out;
    }
    if (p == "gTutorGroupID") {
        gTutorGroupID = v;
        jump out;
    }
    if (p == "gControllerName") {
        gControllerName = v;
        jump out;
    }
    if (p == "gStartCommands") {
        gStartCommands = v;
        jump out;
    }
    if (p == "gEndCommands") {
        gEndCommands = v;
        jump out;
    }
    if (p == "gResetCommands") {
        gResetCommands = v;
        jump out;
    }

    if (p == "gHolodeckChatChannel") {
        gHolodeckChatChannel = (integer)v;
        jump out;
    }

    if (p == "gHolodeckAPIChannel") {
        gHolodeckAPIChannel = (integer)v;
    }
    @out;

}

option_start(key id) {
    sendChatCommand(gPlayerTrackingObjChannel, "reset");
    sendChatCommand(gPIVOTEChannel, gResetCommands);
    resetElementsFull();
    gSSID="";
    string url = cTestURL+"&mnodeid="; // /root/data/classic
  //  llSay(0, "start: "+ url);
    Rq_getpage = llHTTPRequest(url, [HTTP_METHOD,"GET"], "");
}

option_text() {
    sendChatCommand(gMediaCh, gQSParserPageURL + "?dtext="
    + llGetSubString(llEscapeURL(localtext), 0, 66)+"&doptions=" /// **** truncating text to display in opensim/SL
    + llEscapeURL(llList2CSV(gOptions))); // page with doc.write() JS, presents QS params
}

option_media() {
    string mediaurl = "";

    if (gNodeImage != "") {
        mediaurl = gNodeImage;
    } else {
        if (gNodeMedia != "") {
            mediaurl =gNodeMedia;
        }
    }
    sendChatCommand(gMediaCh, mediaurl);
}

option_back() {
    integer canGoBack = FALSE;
    if (gUseNewParser) urlroot = cTestURL;
    if (oldNode != ""){
        integer n = llGetListLength(linkLabels);
        integer i;

        for(i = 0; i < n; i++){

            if (oldNode == llList2String(linkRefs,i)){
                canGoBack = TRUE;
            }
        }
    }else{
        llSay(0, "There is no record of a previous node");
    }

    if (canGoBack){

        Rq_getnode = llHTTPRequest(urlroot+"&linkid="+oldNode+
        "&sessid="+gSSID, [HTTP_METHOD,"GET"], "");
    }else{
        llSay(0, "You cannot go back to the "+oldNode+" node from this one (" + gNode + " node)");
    }
}

option_help() {
    sendChatCommand(gMediaCh, gHelpURL);
}

option_menu() {
    sendChatCommand(gMediaCh, gMenuURL);
}

option_showbrowser(key id) {
    sendChatCommand(gMediaCh, (string)id + "~showbrowser");
}

option_options(key id) {
    integer l = llGetListLength(gOptions);
    //    integer i;
    if ((gQuickOption) && (l==1)) {
        option_option(0);
    } else {
        sendChatCommand(gMediaCh, gQSParserPageURL + "?options="+ llEscapeURL(llList2CSV(gOptions)));
    }
    //gOptions = [];
}

option_option(integer num) {
    //todo: must have a session id and oldNode by now!
    sendChatCommand(gPlayerTrackingObjChannel, "reset");
    list o = gOptions;
    integer l = llGetListLength(o);

    if (llList2String(o, 0) != "") {

        sendChatCommand(gMediaCh, gQSParserPageURL + "?options=Updating...");

        string nodeName = llList2String(o, 1);

        if (gUseNewParser) nodeName = llList2String(linkRefs, num); // is it that easy? must we subt by 1
        //llSay(0, "nodeName: "+nodeName + " - "+(string)llGetListLength(linkRefs) + " - "+ llList2CSV(linkRefs));

        if (gUseNewParser) urlroot = cTestURL;

        if (gPage == "node") {
            nodeName = llEscapeURL(nodeName);

         //   llSay(0, "sending URL"+urlroot+"&api=shownode&case="+gCase+
           // "&mnodeid="+nodeName+"&sessid="+gSSID);

            Rq_getnode = llHTTPRequest(urlroot+"&api=shownode&case="+gCase+
            "&mnodeid="+nodeName+"&sessid="+gSSID, [HTTP_METHOD,"GET"], "");
        }else{
            if (gPage == "case list") {
                if (nodeName == "_start") {
                    nodeName = "";
                    option_start(NULL_KEY);
                    nodeName = "";
                }else{
                    if (nodeName == "_more") {
                        gOffset += gBlock;
                        nodeName = "";
                        //if (gUseNewParser) urlroot = cTestURL + "1.xml";
                        Rq_getpage = llHTTPRequest(urlroot+"&api=list&offset="+(string)gOffset+
                        "&block="+(string)gBlock+"&filter="+gFilter+"&avail="+llEscapeURL(gExerciseList),
                        [HTTP_METHOD,"GET"], "");
                    }else{
                        if (nodeName != "") {
                            gCase = nodeName;
                            nodeName = llEscapeURL(nodeName);
                            //if (gUseNewParser) urlroot = cTestURL + "1.xml";
                            Rq_getnode = llHTTPRequest(urlroot+"&api=shownode&av="+llEscapeURL(llKey2Name(gUserKey))+
                            "&case="+nodeName, [HTTP_METHOD,"GET"], "");
                        }
                    }
                }
            }
        }
    }
    linkLabels = [];
    linkRefs = [];
    gOptions = [];
}

set_button(string btn, string cond) {
    //llMessageLinked(LINK_SET, 0, btn+"_"+cond, NULL_KEY);
}

// ******** END FUNCTIONS ********

default {
    state_entry()
    {
        state load_config;
    }
}

state findingPlayers {
    state_entry() {

        string obj2Scan = "nosm bracelet 2.0"; // should be in config notecard

        //llListenRemove(lh);
        lh = llListen(gSignupObjChannel, "", NULL_KEY, "");
        sendChatCommand(gSignupObjChannel, obj2Scan+"~10.0"); // object scan for, the radius

        // state active;

    }

    listen(integer channel, string name, key id, string msg) {
        // each person returned is wearing a nossum_bracelet, then you're sent an end of msg file (Signup machine not yet implemented: TODO):

        // TODO: bracelet must pass in owner key on wear/register
        gPlayerAgentKeyList =["phantomKey"] + gPlayerAgentKeyList;
        gPlayerList = [llKey2Name("phantomKey")] +gPlayerList;
        state active;

        if (channel==gSignupObjChannel){
            if (msg != "EOM"){
                gPlayerList = (gPlayerList=[]) + gPlayerList + [name];
                //gPlayerList += name;
                list parts = llParseString2List(msg, ["~"], []);
                gPlayerRoleList = [llList2String(parts, 0)] + gPlayerRoleList;
                gPlayerAgentKeyList = [(key)llList2String(parts, 1)]+gPlayerAgentKeyList;
            }else{
                state active;
            }
        }
    }

}

state sceneLocked   {
    state_entry() {

        integer sceneRezzed = FALSE;

        while (!sceneRezzed)
        {

            if (llSubStringIndex(gCurrentSceneStatus, "REZZED_SCENE") > -1)
            {
                sceneRezzed = TRUE;
                gCurrentSceneStatus = "";
            }
            else
            {
                llSleep(0.5);
            }
        }
        state active;

    }

    listen(integer channel, string name, key id, string msg) {

        if (channel==gHolodeckChatChannel){
            gCurrentSceneStatus = msg;
        }
    }

}

state load_config
{
    state_entry()
    {
        sendChatCommand(0, "Please wait, loading configuration data ...");
        sendChatCommand(gMediaCh, gQSParserPageURL + "?dtext
        =Updating...");
        sendChatCommand(gPIVOTEChannel, gResetCommands);

        if (llGetInventoryType(gXMLConfigCard) != INVENTORY_NOTECARD || llGetInventoryType(gConfigCard) != INVENTORY_NOTECARD)
        {
            //has no notecard!
            //blow a gasket here?
            sendChatCommand(0, "no configuration assigned to this controller!");
        }else{

            gXMLParserLine = 0;
            XMLParser_getLine = llGetNotecardLine(gXMLConfigCard, gXMLParserLine);
            resetParserConstants();

            gLine = 0;
            Ds_getLine = llGetNotecardLine(gConfigCard, gLine);
        }

        urlroot = gServiceURL+"?op=sl&wl=sl";
        urlroot += "&uid="+llEscapeURL(gServiceUID);
        urlroot += "&pwd="+llEscapeURL(gServicePwd);
        urlroot += "&controller="+llEscapeURL(gControllerName);
        urlroot += "&tutor="+llEscapeURL(gTutorGroupID);

        sendChatCommand(gMediaCh, gQSParserPageURL + "?dtext=Ready!");
    }

    dataserver(key query_id, string data) {
        if (query_id == Ds_getLine) {
            list l;
            string param;
            string value;
            if (data != EOF) {
                if ((llSubStringIndex(data, "//") == 0) || (llSubStringIndex(data, "=") == -1)) {
                    // comment or invalid
                } else {
                    // valid
                    l = llParseString2List(data, ["="], []);
                    param = llList2String(l, 0);
                    value = llList2String(l, 1);
                    config_load(param, value);
                }
                // next line
                Ds_getLine = llGetNotecardLine(gConfigCard, ++gLine);
            } else {
                sendChatCommand(0, "Config loaded. Scanning for registered players...");

                //state findingPlayers;
                state active;
            }
        } else {
            if (query_id == XMLParser_getLine){
                list l2;
                string param2;
                string value2;
                if (data != EOF) {
                    if ((llSubStringIndex(data, "//") == 0) || (llSubStringIndex(data, "=") == -1)) {
                        // comment or invalid
                    } else {
                        // valid
                        l2 = llParseString2List(data, ["="], []);
                        param2 = llList2String(l2, 0);
                        value2 = llList2String(l2, 1);
                        parserConfig_load(param2, value2);
                    }
                    // next line
                    XMLParser_getLine = llGetNotecardLine(gXMLConfigCard, ++gXMLParserLine);
                }
            }
        }
    }
}

state active
{
    state_entry() {

        // reset listener
        llListenRemove(lh);
        llListenRemove(lhd);
        // llListenRemove(lhc);

        // TODO: need to llListen on all the channels, poseball, bracelet, etc, not just pivote
        lh = llListen(gPIVOTEChannel, "", NULL_KEY, "");

        lhd = llListen(gHolodeckChatChannel, "", NULL_KEY, "");
        //  lhc = llListen(gCurrentContinuanceChannel, "", NULL_KEY, "");

    }

    listen(integer channel, string name, key id, string msg) {
        integer update = FALSE;
        gUserKey = id;
        if (llSubStringIndex(msg, "user=") == 0) {
            integer amp = llSubStringIndex(msg, "&");

            amp--;
            gUserKey = (key)llGetSubString(msg, 5, amp);
            id = gUserKey;
            amp += 2;
            msg = llGetSubString(msg, amp, -1);
            llOwnerSay((string)gUserKey+" = "+llKey2Name(id)+" leaving "+msg);
        }
        if (msg == "start") {
            option_start(NULL_KEY);
        }
        if (msg == "reset") {
            state load_config;
        }
        if (msg == "options") {
            option_options(id);
        }
        if (llSubStringIndex(msg, "option=") != -1) {
            //llSay(0, msg);
            integer num = (integer) llGetSubString(msg, 7, -1);
            option_option(num);
        }
        if (msg == "text") {
            option_text();
        }
        if (msg == "media") {
            option_media();
        }
        if (msg == "back") {
            option_back();
        }

        if (msg == "menu") {
            option_menu();
        }
        if (msg == "help") {
            option_help();
        }
        if (msg == "hardreset") {
            llResetScript();
        }
        if (llSubStringIndex(msg, "node=") == 0) {
            msg = llGetSubString(msg, 5, -1);
            //llSay(0, "heard "+msg);
            update = TRUE;
        }

        if (update) {
            // fetch next scene
            //llWhisper(0, "Fetching Node "+msg+" from web ...");

            sendChatCommand(gMediaCh, gUpdatingURL);
            msg = llEscapeURL(msg);

            if (gUseNewParser) urlroot = cTestURL;

            resetElementsFull();
            string stxt = "";
            if (gSSID != "" ) {
                stxt = "&sessid="+gSSID;
            }

            key thisowner = llGetOwner();
            string avname = llKey2Name(thisowner);
            Rq_getnode = llHTTPRequest(urlroot+"&mnodeid="+msg+"&av="+avname+stxt, [HTTP_METHOD,"GET"], "");
        }

        if (channel==gHolodeckChatChannel){
            gCurrentSceneStatus = msg;

        }

    }

    http_response(key request_id, integer status, list metadata, string body) {
        //llSay(0, body);
        string errorTXT = "";
        //gOptions = [];
        parseFeed(body);

        gPage = "node";
        gNodeMedia = "";
        gNodeImage = "";


        integer nAssets = llGetListLength(assetTypes);

        // first, get sequence
        string seq = xtraktSeq(body, "SLInnerSequence", "value");
        list parts = llParseString2List(seq , [","], []);
        integer n = llGetListLength(parts);
        integer i;

        orderedAssets = ["99999"]; // always add OL vpdText

        for(i = 0; i < n; i++){
            string thisAssetId = llList2String(parts, i);
            orderedAssets += [thisAssetId];
        }

        // run the assets in order
        n = llGetListLength(orderedAssets);
      //  llSay(0, "number of items to run: "+(string)n);
        for(i = 0; i < n; i++){
            string id = llList2String(orderedAssets, i);
          //   llSay(0, "name to run: "+name);
            string value = getAssetAttribValById(id, "value");
            string type = getAssetAttribValById(id, "type");

            string dtext = "";
            string device = "";

            if(llToLower(type)=="vpdtext"){
                //llSay(0,"******** IN VPDTEXT: "+value );

                dtext = value;
                // trims that id stuff off the front end...
                //dtext = llGetSubString(dtext, llSubStringIndex(dtext, "]]]]")+4, -1);
            }

            if(llToLower(type)=="slanimation"){
            //    llSay(0,"******** IN slanimation: "+value );
            }

            if (dtext != "") {
                // check device
                if (device == "") {
                   // llSay(0, "detex: "+dtext);
                    //localtext = localtext + dtext + ". ";
                    localtext = dtext;
                } else {
                    // assume at beginning
                    sendChatCommand(gPIVOTEChannel, "<device>"+device+"</device>"+dtext);
                }
            }

            integer done = FALSE;
            // todo: if image does not begin with http, add prefix
            if (llToLower(type) == "vpdimage") {
                gNodeImage =  value;
                dtext = "";
                //set_media(gNodeImage);
                done = TRUE;
                set_button("media", "show");
            }

            if (llToLower(type) == "vpdmedia") {
                gNodeMedia = value;
                dtext = "";
                //set_media(gNodeMedia);
                done = TRUE;
                set_button("media", "show");

            }

            if(llGetSubString( llToLower(type), 0, 1 ) == "sl"){
              //  llSay(0,"******** about to assign: "+type+value + name + getAssetAttribValByName(name, "target") );
                assignSL(type, getAssetAttribValById(id, "target"), getAssetAttribValById(id, "name"), value, 0 );
            }

            if (gNode == "finish") {
                sendChatCommand(gPIVOTEChannel, gEndCommands);
                if (gPIVOTEPrefix == "") {
                    sendChatCommand(gPIVOTEChannel, "<device>"+device+"</device>"+dtext);
                } else {
                    sendChatCommand(gPIVOTEChannel, gPIVOTEPrefix+":"+"<device>"+device+"</device>"+dtext);
                }
                if (gShowSession) {
                    llSay(0, "Please note that your Session ID was " + (string)gSSID +
                    ". Please make a note of it as you may need it for later assessment or review.");
                }

            }

        }
        set_button("options", "show");
        gOptions = linkLabels;

        option_text();

        @errorCatch;
        if (errorTXT != ""){
            sendChatCommand(gMediaCh, gQSParserPageURL + "?options="+errorTXT);
        }
        resetElements(); // does not reset links
        orderedAssets = [];
    }

    link_message(integer sender_num, integer num, string str, key id) {

        integer done = FALSE;
        gUserKey = id;

        if (str == "start") {
            done = TRUE;
            option_start(NULL_KEY);
        }
        if (str == "reset") {
            done = TRUE;
            state load_config;
        }

        if (str == "options") {
            done = TRUE;
            option_options(id);
        }
        if (str == "text") {
            done = TRUE;
            option_text();
        }

        if (str == "media") {
            option_media();
            done = TRUE;
        }
        if (str == "back") {
            option_back();
            done = TRUE;
        }

        if (str == "help") {
            done = TRUE;
            option_help();
        }
        if (str == "menu") {
            done = TRUE;
            option_menu();
        }

        if (str == "option") {
            option_option(num);
        }
        if (str == "hud") {
            llGiveInventory(id, "PIVOTE HUD Player 1.0");
        }
        if (str == "objects") {
            llGiveInventory(id, gObjectBox);

        }
        if (str == "showbrowser") {
            option_showbrowser(gUserKey);
        }
        if (str == "hardreset") {
            llResetScript();
        }

        if (str == "playerAgentKey"){
            PlayerAgentKey = id;
        }

        if (str == "patientAgentKey"){
            PatientAgentKey = id;
        }

    }

}