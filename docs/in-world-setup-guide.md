# Ariadne In-World Object Setup Guide

This guide explains how to create and configure objects in OpenSimulator to host
the Ariadne LSL scripts. Follow these steps in order using your viewer (Singularity,
Firestorm, or any OpenSim-compatible viewer).

## Prerequisites

Before building in-world objects, ensure these services are running:

1. MongoDB on port 27017
2. Ariadne4j on port 8080 (context path /ariadne)
3. OpenSimulator on port 9000/9001 with region "Ariadne Test Region" online

Quick start:
```
cd /home/rjodouin/Documents/git/nosm-verse
./scripts/start-ariadne.sh
```

Log into the region with your viewer. You need build permissions on the parcel
(right-click ground > About Land > check "Edit, Move, Delete" is allowed for you).

## LSL Scripts Overview

Six scripts live in `VERSE/src/ariadne/lsl/`. Each goes into a specific type of
object:

| Script | Object Type | Purpose |
|--------|------------|---------|
| controller.lsl | Controller prim (main object) | Starts node traversal, fetches nodes from Ariadne4j API, dispatches assets |
| bracelet.lsl | Wearable bracelet (attached to avatar) | Receives assets on channel 603, plays animations/sounds, gives inventory items |
| media_relay.lsl | Media display prim | Shows images/videos/web pages on parcel media, listens on channel -63342 |
| regbooth.lsl | Registration kiosk | Registers new users with Ariadne4j, gives bracelet to avatar |
| buildHelper.lsl | Helper prim (optional) | HTTP database save/load helper for builder workflows |
| ariadne_link_assign.lsl | Link assignment prim | Assigns node IDs to objects via channel -9898 |

## Communication Channels

The scripts talk to each other on specific channels. Do not change these unless
you also update all scripts:

| Channel | Constant | Direction |
|---------|----------|-----------|
| 687686 | gPIVOTEChannel | Controller <-> linked objects (options, node selections) |
| -63342 | gMediaCh | Controller -> media relay (media URLs) |
| 603 | gPlayerTrackingObjChannel | Controller -> bracelet (asset delivery) |
| -8787 | gSignupObjChannel | Registration booth -> controller (player signup) |
| 9993 | gHolodeckChatChannel | Holodeck scene commands |
| -9993 | gHolodeckAPIChannel | Holodeck API |
| -9898 | mvpch | Link assignment messages |
| 8793 | button_channel | Registration dialog buttons |

## Step 1: Create the Controller Prim

The controller is the central object. Touching it starts a node traversal session.

1. Rez a prim on the ground:
   - Right-click the ground > Create (or Build)
   - Click on the ground to rez a default cube
   - Name it "Ariadne Controller"

2. Add the controller script:
   - Right-click the prim > Edit
   - Go to the Content tab
   - Click "New Script" (do not use this default script)
   - Delete the default script contents
   - Open `controller.lsl` from `VERSE/src/ariadne/lsl/controller.lsl`
   - Copy all contents and paste into the script editor
   - Save the script (Ctrl+S or click Save)

3. Add the config notecard named "pivotecontroller.cfg":
   - In the Content tab, click "New Notecard"
   - Name it exactly: pivotecontroller.cfg
   - Add these lines (adjust URL if Ariadne4j runs elsewhere):

```
gServiceURL=http://127.0.0.1:8080/ariadne/api/
gQSParserPageURL=http://127.0.0.1:8080/ariadne/show.html
gPIVOTEChannel=687686
gMediaCh=-63342
gPlayerTrackingObjChannel=603
gQuickStart=TRUE
gQuickOption=TRUE
gShowHUD=TRUE
gShowObjects=TRUE
gShowSession=TRUE
```

4. Add the XML parser notecard named "feedparserconstants.cfg":
   - In the Content tab, click "New Notecard"
   - Name it exactly: feedparserconstants.cfg
   - This notecard defines XML tag names used for parsing API responses.
     If you are using the default Ariadne4j API, it can be empty or contain:

```
cNodeName=node
cNodeId=id
cNodeLabel=label
cAsset=asset
cAssetType=type
cAssetName=name
cAssetTarget=target
cAssetId=id
cLink=link
cLinkLabel=label
cLinkRef=ref
```

5. The controller prim is now configured. When touched, it will:
   - Generate a session ID (MD5 of timestamp + owner key)
   - Request node 1 from http://127.0.0.1:8080/ariadne/api/node/1?sessionId=<id>
   - Parse the XML response for assets and questions
   - Dispatch assets to bracelet (channel 603) and media relay (channel -63342)
   - Display question options via MOAP (Media on a Prim) on face 0

## Step 2: Create the Bracelet (Wearable)

The bracelet is worn by the avatar and receives animation, sound, and inventory
assets from the controller.

1. Rez a small prim:
   - Create a small cylinder or torus
   - Name it "Ariadne Bracelet"
   - Size it to look like a bracelet (approximately 0.05m diameter)

2. Add the bracelet script:
   - Content tab > New Script
   - Delete default contents
   - Paste contents of `bracelet.lsl`
   - Save

3. Add any inventory items the bracelet might give:
   - If your cases include SLObject, SLClothing, SLBodypart, or SLHud assets,
     drag those items from your inventory into the bracelet prim's Content tab
   - The bracelet gives these to the avatar when the controller sends the
     corresponding asset type

4. Set the bracelet as attachable:
   - Right-click the prim > Edit > General tab
   - Check "Allow anyone to move" = off
   - The prim is now ready for attachment

5. To wear: right-click the bracelet > Attach > Left Hand (or right hand).
   The bracelet listens on channel 603 for asset commands.

6. OSSL requirement: The bracelet uses osAvatarPlayAnimation and
   osAvatarStopAnimation. These must be enabled in:
   `/home/rjodouin/opensimulator/bin/config-include/osslDefaultEnable.ini`

```
[OSSL]
  Allow_osAvatarPlayAnimation = true
  Allow_osAvatarStopAnimation = true
```

Restart OpenSimulator after changing OSSL settings.

## Step 3: Create the Media Relay Prim

The media relay displays images, videos, and web pages on parcel media.

1. Rez a flat prim (like a screen):
   - Create a cube, flatten it to look like a screen
   - Name it "Ariadne Media Relay"
   - Size approximately 2m x 1.5m x 0.1m

2. Add the media relay script:
   - Content tab > New Script
   - Delete default contents
   - Paste contents of `media_relay.lsl`
   - Save

3. Position the screen facing the area where avatars will view it.

4. The media relay listens on channel -63342 for URLs from the controller.
   When it receives a URL, it auto-detects the media type:
   - .jpg/.jpeg -> image/jpeg
   - .png -> image/png
   - .gif -> image/gif
   - .bmp -> image/bmp
   - .mp4 -> video/mp4
   - .webm -> video/webm
   - .ogv/.ogg -> video/ogg
   - .html/.htm -> text/html

5. Parcel ownership requirement: The media relay prim must be owned by the
   parcel owner for llParcelMediaCommandList to work. If you own the parcel
   and the prim, you are fine.

## Step 4: Create the Registration Booth

The registration booth registers new users with the Ariadne4j backend and gives
them a bracelet.

1. Rez a prim shaped like a kiosk or sign:
   - Name it "Ariadne Registration"

2. Add the registration script:
   - Content tab > New Script
   - Delete default contents
   - Paste contents of `regbooth.lsl`
   - Save

3. Update the backend URL in the script:
   - The script has hardcoded URL: http://142.51.75.11/ariadne4j/
   - Change both occurrences to your backend URL:
     http://127.0.0.1:8080/ariadne/

4. Add a bracelet to the booth's inventory:
   - Drag your "Ariadne Bracelet" object from the ground into the booth's
     Content tab
   - The booth gives this bracelet to avatars who register
   - The bracelet object name in the script is
     "nossum regional hospital bracelet 0.4" -- either name your bracelet
     exactly this or update the llGiveInventory line in the script

5. How it works:
   - Avatar touches the booth
   - Booth sends registration request to Ariadne4j
   - If server responds "ENLISTED", the booth gives the bracelet
   - If server responds "REJECTED", the booth informs the avatar

## Step 5: Create Link Assignment Prims (Optional)

Link assignment prims are objects that can be assigned to specific nodes. When
touched, they tell the controller to jump to that node.

1. Rez a prim for each node you want to link:
   - Name each prim uniquely (e.g., "Node 2 Trigger", "Node 3 Trigger")

2. Add the link assignment script:
   - Content tab > New Script
   - Delete default contents
   - Paste contents of `ariadne_link_assign.lsl`
   - Save

3. How it works:
   - The controller sends "set <primName>:<nodeId>" on channel -9898
   - The matching prim switches to active state
   - When touched, it sends "node=<nodeId>" on channel 687686 to the controller
   - The controller fetches that node from the API

4. To assign a node to a prim, send a chat command:
   - Type in local chat: /-9898 set Node 2 Trigger:2
   - This assigns "Node 2 Trigger" prim to node ID 2

## Step 6: Create the Build Helper Prim (Optional)

The build helper provides HTTP database save/load functionality for builder
workflows. This is a legacy script and may not be needed for standard operation.

1. Rez a prim and name it "Build Helper"
2. Add the `buildHelper.lsl` script to its Content tab
3. Update the HTTPDB_URL constant in the script to point to your backend
4. The script listens for link_message events with codes:
   - 1000 (HTTPDB_SAVE): Save data to backend
   - 1100 (HTTPDB_LOAD): Load data from backend
   - 1200 (HTTPDB_DELETE): Delete data from backend

## Step 7: Configure MOAP on the Controller Prim

The controller displays question options via Media on a Prim (MOAP). To
configure:

1. Right-click the controller prim > Edit > General tab
2. Click the "Texture" tab
3. Select face 0 (the front face)
4. Click the texture picker and set it to "Blank" (no texture)
5. Check "Media" checkbox to enable MOAP on this face
6. The controller script sets the MOAP URL dynamically to:
   http://127.0.0.1:8080/ariadne/show.html?dtext=<text>&doptions=<options>

The show.html page uses JavaScript document.write() to display the question
text and clickable option buttons. When an option is clicked, it sends
"option=<n>" on channel 687686 to the controller.

## Step 8: Configure OpenSimulator for LSL HTTP Requests

The controller makes HTTP requests to Ariadne4j. OpenSimulator restricts
outbound HTTP from scripts by default.

1. Edit `/home/rjodouin/opensimulator/bin/OpenSim.ini`
2. Find the `[Network]` section
3. Set:
   ```
   OutboundDisallowForUserScriptsExcept = 127.0.0.1:8080
   ```
4. Restart OpenSimulator

This allows LSL scripts to make HTTP requests only to localhost:8080 (your
Ariadne4j instance) for security.

## Step 9: Test the Setup

1. Log in with your viewer to "Ariadne Test Region"
2. Wear the bracelet (attach to left hand)
3. Touch the controller prim
4. You should see in local chat:
   ```
   [CONTROLLER DEBUG] Touch detected from <your avatar name>
   [CONTROLLER DEBUG] Touch authorized, starting node traversal
   [CONTROLLER DEBUG] Requesting node from: http://127.0.0.1:8080/ariadne/api/node/1?sessionId=<id>
   [CONTROLLER DEBUG] HTTP Response received - Status: 200, Body length: <n>
   [CONTROLLER DEBUG] Parsed asset: id=1, type=SLChat, name=welcome_message
   [CONTROLLER DEBUG] Parsed asset: id=2, type=SLAnimation, name=welcome_animation
   ```
5. The SLChat message appears in local chat
6. The SLAnimation triggers on your avatar (bracelet receives it on channel 603)
7. The MOAP face shows question options
8. Click an option to advance to the next node

## Troubleshooting

### Controller says "no configuration assigned to this controller!"

The notecards are missing or misnamed. The controller looks for exactly:
- pivotecontroller.cfg
- feedparserconstants.cfg

Check spelling and case. Notecard names are case-sensitive.

### Controller says "ERROR: llHTTPRequest returned NULL_KEY!"

OpenSimulator is blocking the outbound HTTP request. Check:
1. OpenSim.ini OutboundDisallowForUserScriptsExcept includes 127.0.0.1:8080
2. Ariadne4j is running: curl http://localhost:8080/ariadne/api/node/1?sessionId=test
3. OpenSimulator was restarted after changing OpenSim.ini

### Bracelet says "Playing animation" but avatar does not animate

1. Verify OSSL functions are enabled in osslDefaultEnable.ini
2. Restart OpenSimulator after enabling OSSL
3. Use valid built-in animation names (clap, bow, wave, dance1, etc.)
4. Check that the bracelet is actually attached to your avatar

### MOAP shows "400 Bad Request" or blank

1. Verify Ariadne4j is serving show.html: curl http://localhost:8080/ariadne/show.html
2. Check that gQSParserPageURL in pivotecontroller.cfg points to:
   http://127.0.0.1:8080/ariadne/show.html
3. Ensure the controller prim face 0 has Media enabled

### Media relay does not display images

1. The media relay prim must be owned by the parcel owner
2. Check that the URL is reachable from OpenSimulator
3. Touch the media relay to see its listening status
4. Verify the controller is sending URLs on channel -63342

### Registration booth says "REJECTED"

1. Check that Ariadne4j is running
2. Update the hardcoded URL in regbooth.lsl from 142.51.75.11 to 127.0.0.1
3. Verify the Users endpoint: curl http://localhost:8080/ariadne/Users?action=register

## File Locations

- LSL scripts: /home/rjodouin/Documents/git/nosm-verse/VERSE/src/ariadne/lsl/
- Config notecards (create these in-world, names must match exactly):
  - pivotecontroller.cfg (goes in controller prim)
  - feedparserconstants.cfg (goes in controller prim)
- OpenSim config: /home/rjodouin/opensimulator/bin/OpenSim.ini
- OSSL config: /home/rjodouin/opensimulator/bin/config-include/osslDefaultEnable.ini
- Region config: /home/rjodouin/opensimulator/bin/Regions/Regions.ini

## LSL/OSSL Reference

- OpenSimulator LSL functions: http://opensimulator.org/wiki/LSL_Status/Functions
- OSSL functions: https://www.ossl.wiki/
- Second Life LSL wiki (most functions work in OpenSim):
  https://wiki.secondlife.com/wiki/LSL_Portal
- Key OSSL functions used by Ariadne:
  - osAvatarPlayAnimation(key avatar, string anim) -- plays animation without
    permission request
  - osAvatarStopAnimation(key avatar, string anim) -- stops animation
- Key LSL functions used by Ariadne:
  - llHTTPRequest(url, [HTTP_METHOD, "GET"], "") -- makes HTTP request
  - llParcelMediaCommandList([...]) -- sets parcel media URL and type
  - llGetNotecardLine(name, line) -- reads config notecards
  - llListen(channel, "", NULL_KEY, "") -- listens on a channel
  - llSay(channel, message) -- sends on a channel
  - llGiveInventory(avatar, item) -- gives inventory item to avatar
  - llTriggerSound(uuid, volume) -- plays a sound
