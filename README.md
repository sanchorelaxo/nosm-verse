# nosm-verse

Ariadne educational game engine ported from Second Life to OpenSimulator with
a MongoDB backend. Originally built as PIVOTE/Ariadne for Second Life, this
project modernizes the stack: Spring Boot 3 + Java 21 replaces the legacy
servlet/JSP backend, MongoDB replaces MySQL + Redis, and OpenSimulator
replaces the Second Life grid.

## Architecture

```
 +-------------------+     HTTP/XML      +-------------------+
 |  OpenSimulator    | <--------------> |   Ariadne4j       |
 |  (Region server)  |   LSL llHTTPRequest|  (Spring Boot 3)  |
 |                   |                   |                   |
 |  LSL scripts:     |  -63342 (media)   |  REST API:        |
 |  - controller.lsl |  603 (bracelet)   |  /ariadne/api/    |
 |  - bracelet.lsl   |  687686 (PIVOTE)  |  node/{id}        |
 |  - media_relay.lsl|  -8787 (signup)   |  Users             |
 |  - regbooth.lsl   |                   |                   |
 |  - link_assign.lsl|                   +--------+----------+
 |  - buildHelper.lsl|                            |
 +-------------------+                            | MongoDB
                                                   v
                                          +-------------------+
                                          |  MongoDB          |
                                          |  Database: ariadne|
                                          |                   |
                                          |  Collections:     |
                                          |  - cases          |
                                          |  - nodes          |
                                          |  - sessions (TTL) |
                                          |  - assetTypes (26)|
                                          |  - assetMappings  |
                                          |  - users          |
                                          +-------------------+
```

Three services work together:

1. **MongoDB** (port 27017) -- stores cases, nodes, sessions, asset types,
   asset mappings, and users. The sessions collection has a TTL index that
   auto-expires session documents after 1 hour.

2. **Ariadne4j** (port 8080, context path /ariadne) -- Spring Boot 3
   application serving the REST API that LSL scripts call via
   llHTTPRequest. Also serves static web assets (show.html, jQuery
   libraries) used for MOAP (Media on a Prim) display.

3. **OpenSimulator** (port 9000 HTTP, 9001 region) -- hosts the 3D virtual
   world where avatars interact with scripted objects. LSL scripts in prims
   make outbound HTTP calls to Ariadne4j to fetch nodes and deliver assets
   (chat messages, animations, sounds, inventory items, media URLs).

## Repository Structure

```
nosm-verse/
  plan.md                          # Full project plan (Phases 0-7)
  docs/
    in-world-setup-guide.md        # How to create OpenSim objects for LSL scripts
  scripts/
    start-ariadne.sh               # Start MongoDB, Ariadne4j, OpenSim
    stop-ariadne.sh                # Stop Ariadne4j and OpenSim
    backup-mongodb.sh              # MongoDB backup with 7-day retention
  VERSE/
    src/
      ariadne/
        lsl/                       # 6 LSL scripts + config notecards
          controller.lsl           # Main controller (node traversal, asset dispatch)
          bracelet.lsl             # Wearable (animations, sounds, inventory)
          media_relay.lsl          # Parcel media display (images, video, web)
          regbooth.lsl             # Registration kiosk (user signup + bracelet giver)
          ariadne_link_assign.lsl  # Node-to-prim link assignment
          buildHelper.lsl          # HTTP database helper (legacy/builder)
          AriadneConfig.txt        # Sample pivotecontroller.cfg notecard contents
          AriadneXMLConfig.txt     # Sample feedparserconstants.cfg notecard contents
          ARIADNE_CONFIG.notecard  # OpenSim-specific backend config notecard
        server/                    # Static web assets served by Ariadne4j
          show.html                # MOAP display page (question text + options)
          *.js                     # jQuery, Google Maps, SL Map, XML parsers
          *.html                   # Asset editor, index pages
        db/
          ariadne_2009-11-09.sql    # Original SQL dump (26 asset types, source of truth)
          create.sql                # Original schema
      ariadne4j/
        pom.xml                    # Maven build (Spring Boot 3, Java 21, MongoDB driver)
        src/
          main/
            java/com/nosm/elearning/ariadne/
              AriadneApplication.java       # Spring Boot entry point
              AriadneMongoBackend.java      # MongoDB connection + data access
              controller/
                NodeController.java         # REST: /api/node/{id} -- returns XML node data
              service/
                NodeService.java            # Node fetching logic
                CaseService.java             # Case management
                AssetService.java            # Asset type lookup + mapping
                SessionService.java          # Session creation + TTL management
            resources/
              application.yml                # Server port, MongoDB URI, logging config
          test/
            java/com/nosm/elearning/ariadne/
              AriadneApplicationTests.java    # Spring Boot integration test
        target/
          ariadne4j-2.0.0.jar                 # Built JAR (gitignored)
        logs/
          ariadne-console.log                # Runtime log (gitignored)
      sl_dispatch/                            # Legacy ASP.NET dispatch handler (reference only)
```

## Prerequisites

- **Java 21** (OpenJDK or Temurin)
- **Maven 3.8+** (for building Ariadne4j)
- **MongoDB 6.0+** (running on localhost:27017)
- **OpenSimulator** (installed at ~/opensimulator/bin/)
- **.NET 8 SDK** (required by OpenSimulator)
- **OpenSim-compatible viewer** (Singularity, Firestorm, or Cool VL Viewer)

## Quick Start

1. Clone the repository:
   ```
   git clone https://github.com/sanchorelaxo/nosm-verse.git
   cd nosm-verse
   ```

2. Build Ariadne4j:
   ```
   cd VERSE/src/ariadne4j
   mvn clean package -DskipTests
   cd ../../..
   ```

3. Import the database (first time only):
   ```
   mongosh mongodb://localhost:27017/ariadne VERSE/src/ariadne/db/ariadne_2009-11-09.sql
   ```
   Or use mongorestore from a backup:
   ```
   mongorestore --db ariadne /backups/ariadne/<timestamp>/
   ```

4. Configure OpenSimulator:
   - Edit ~/opensimulator/bin/OpenSim.ini:
     ```
     [Network]
       OutboundDisallowForUserScriptsExcept = 127.0.0.1:8080
     ```
   - Edit ~/opensimulator/bin/config-include/osslDefaultEnable.ini:
     ```
     [OSSL]
       Allow_osAvatarPlayAnimation = true
       Allow_osAvatarStopAnimation = true
     ```

5. Start all services:
   ```
   ./scripts/start-ariadne.sh
   ```
   This starts MongoDB (if needed), Ariadne4j, and OpenSimulator.

6. Verify services are running:
   ```
   curl http://localhost:8080/ariadne/api/node/1?sessionId=test
   curl http://localhost:9000/simstatus/
   ```

7. Log into OpenSimulator with your viewer and create in-world objects.
   See docs/in-world-setup-guide.md for step-by-step instructions.

## Stopping Services

```
./scripts/stop-ariadne.sh
```

## MongoDB Backup

```
./scripts/backup-mongodb.sh
```

Backups are stored in /backups/ariadne/ with timestamps. The script uses
mongodump --gzip and retains 7 days of backups. Old backups are pruned
automatically.

Restore from backup:
```
mongorestore --gzip --db ariadne /backups/ariadne/<timestamp>/
```

## LSL Scripts

All scripts live in VERSE/src/ariadne/lsl/. See docs/in-world-setup-guide.md
for complete setup instructions.

### controller.lsl

The main controller script. Goes in a prim that avatars touch to start a
node traversal session. Reads two notecards from its inventory:

- **pivotecontroller.cfg** -- configuration parameters (backend URL, channels,
  display options). See AriadneConfig.txt for a sample.
- **feedparserconstants.cfg** -- XML tag name mappings for parsing API
  responses. See AriadneXMLConfig.txt for a sample.

When touched, the controller:
1. Generates a session ID (MD5 of timestamp + owner key)
2. Requests node 1 from the Ariadne4j API
3. Parses the XML response for assets and question options
4. Dispatches assets to the bracelet (channel 603) and media relay
   (channel -63342)
5. Displays question options via MOAP on face 0 using show.html

### bracelet.lsl

Worn by the avatar (attach to left hand). Listens on channel 603 for asset
commands from the controller. Handles:
- SLAnimation: plays/stops animations via osAvatarPlayAnimation (OSSL)
- SLSound: plays sound by UUID via llTriggerSound
- SLObject/SLClothing/SLBodypart/SLHud/SLPackage/SLLandmark/SLTexture:
  gives inventory items to the avatar via llGiveInventory
- SLAction: moves the avatar to a target position

Requires OSSL functions osAvatarPlayAnimation and osAvatarStopAnimation
to be enabled in osslDefaultEnable.ini.

### media_relay.lsl

Displays images, videos, and web pages on parcel media. Listens on channel
-63342 for URLs from the controller. Auto-detects media type from the URL
extension and sets parcel media via llParcelMediaCommandList. The prim must
be owned by the parcel owner for parcel media commands to work.

### regbooth.lsl

Registration kiosk. When touched, sends a registration request to
Ariadne4j's Users endpoint. If the server responds "ENLISTED", gives the
toucher a bracelet object from its inventory. Requires a bracelet object
named "nossum regional hospital bracelet 0.4" in its Content tab (or update
the name in the script's llGiveInventory call).

### ariadne_link_assign.lsl

Assigns node IDs to prims via channel -9898. When the controller sends
"set <primName>:<nodeId>", the matching prim switches to active state.
When touched, it sends "node=<nodeId>" on channel 687686 to trigger the
controller to fetch that node.

### buildHelper.lsl

Legacy HTTP database helper. Provides save/load/delete operations via
link messages. Uses an external HTTP endpoint (HTTPDB_URL). Not required
for standard operation but useful for builder workflows.

## Configuration

### Ariadne4j (application.yml)

| Setting | Default | Description |
|---------|---------|-------------|
| server.port | 8080 | HTTP port for the REST API |
| server.servlet.context-path | /ariadne | URL context path |
| mongodb.uri | mongodb://localhost:27017 | MongoDB connection string |
| mongodb.database | ariadne | Database name |
| ariadne.session.ttl-hours | 1 | Session expiration (hours) |
| ariadne.session.max-concurrent | 1000 | Max concurrent sessions |
| spring.web.resources.static-locations | file:.../VERSE/src/ariadne/server/ | Static web assets |

### OpenSimulator

| File | Setting | Value |
|------|---------|-------|
| OpenSim.ini | OutboundDisallowForUserScriptsExcept | 127.0.0.1:8080 |
| osslDefaultEnable.ini | Allow_osAvatarPlayAnimation | true |
| osslDefaultEnable.ini | Allow_osAvatarStopAnimation | true |
| Regions.ini | Region name | Ariadne Test Region |

### In-World Notecards

The controller prim requires two notecards in its Content tab:

**pivotecontroller.cfg** (see AriadneConfig.txt for full sample):
```
gServiceURL=http://127.0.0.1:8080/ariadne/api/node
gQSParserPageURL=http://127.0.0.1:8080/ariadne/show.html
gPIVOTEChannel=687686
gMediaCh=-63342
gQuickStart=TRUE
gShowHUD=TRUE
gShowObjects=TRUE
```

**feedparserconstants.cfg** (see AriadneXMLConfig.txt for full sample):
```
xmlset.Node=node
xmllabel.NodeId=id
xmllabel.NodeTitle=title
xmllabel.NodeContent=content
xmlset.Asset=asset
xmllabel.AssetType=type
xmllabel.AssetName=name
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /ariadne/api/node/{id} | Fetch node by ID (returns XML with title, content, questions, assets) |
| GET | /ariadne/api/node/{id}?sessionId={id} | Fetch node with session tracking |
| POST | /ariadne/Users?action=register&aKey={key}&av={name} | Register a new user |
| GET | /ariadne/show.html | MOAP display page (static, serves question UI) |

### Example API Response (Node 1)

```
curl "http://localhost:8080/ariadne/api/node/1?sessionId=test123"
```

Returns XML:
```xml
<node>
  <id>1</id>
  <title>Welcome to Ariadne</title>
  <content>This is the start of your journey through the Ariadne system.</content>
  <questions>
    <question>
      <text>What would you like to do?</text>
      <option>Continue</option>
      <option>Exit</option>
    </question>
  </questions>
  <assets>
    <asset>
      <type>SLChat</type>
      <name>welcome_message</name>
      <value>Welcome to Ariadne! You are now in the test region.</value>
    </asset>
    <asset>
      <type>SLAnimation</type>
      <name>welcome_animation</name>
      <value>clap</value>
    </asset>
    <asset>
      <type>SLSound</type>
      <name>test_sound</name>
      <value>ed124764-705d-d497-167a-182cd9fa2e6c</value>
    </asset>
  </assets>
</node>
```

## Asset Types

26 asset types are defined in the database, carried over from the original
SQL dump. Each type maps to a specific LSL handling behavior:

| Type | Handled By | Behavior |
|------|-----------|----------|
| SLChat | Controller | Displays message in local chat |
| SLAnimation | Bracelet | Plays animation via osAvatarPlayAnimation |
| SLSound | Bracelet | Plays sound via llTriggerSound (UUID) |
| SLObject | Bracelet | Gives inventory object via llGiveInventory |
| SLClothing | Bracelet | Gives clothing item to avatar |
| SLBodypart | Bracelet | Gives body part to avatar |
| SLHud | Bracelet | Gives HUD attachment to avatar |
| SLPackage | Bracelet | Gives crate/package to avatar |
| SLLandmark | Bracelet | Gives landmark to avatar |
| SLTexture | Bracelet | Gives texture to avatar |
| SLNotecard | Bracelet | Gives notecard to avatar |
| SLIM | Controller | Sends instant message to avatar |
| SLAction | Bracelet | Moves avatar to target position |
| VPDImage | Media Relay | Displays image on parcel media |
| VPDMedia | Media Relay | Displays video on parcel media |
| SLAudio | Media Relay | Plays audio on parcel media |
| SLParticleSystem | Bracelet | Triggers particle effect |
| SLGoogleAPIImage | Media Relay | Displays Google Maps image |
| SLGoogleAPIHTML | Media Relay | Displays Google Maps HTML |
| SLAmazonMapImage | Media Relay | Displays Amazon map image |
| VPDText | Controller | Displays text content |
| VPMannequin | -- | Mannequin display (not yet implemented) |
| SLMove | Bracelet | Movement command |
| SLExtFeedObject | Bracelet | External feed object |
| SLInnerSequence | -- | Inner sequence (not yet implemented) |
| SLSnapshot | -- | Snapshot display (not yet implemented) |

## Communication Channels

| Channel | Constant | Scripts | Purpose |
|---------|----------|---------|---------|
| 687686 | gPIVOTEChannel | Controller, Link Assign | Options, node selections |
| -63342 | gMediaCh | Controller, Media Relay | Media URLs |
| 603 | gPlayerTrackingObjChannel | Controller, Bracelet | Asset delivery |
| -8787 | gSignupObjChannel | Reg Booth, Controller | Player signup |
| 9993 | gHolodeckChatChannel | Controller | Holodeck scene status |
| -9993 | gHolodeckAPIChannel | Controller | Holodeck API |
| -9898 | mvpch | Link Assign | Link assignment messages |
| 8793 | button_channel | Reg Booth | Registration dialog buttons |

## Testing

Integration tests verify the full stack:

```
# Verify Ariadne4j API
curl http://localhost:8080/ariadne/api/node/1?sessionId=test
curl http://localhost:8080/ariadne/api/node/2?sessionId=test
curl http://localhost:8080/ariadne/api/node/3?sessionId=test
curl -o /dev/null -w "%{http_code}" http://localhost:8080/ariadne/api/node/9999
# Should return 404 for non-existent node

# Verify MongoDB
mongosh mongodb://localhost:27017/ariadne --quiet --eval \
  "JSON.stringify({collections: db.getCollectionNames().sort(), counts: {assetTypes: db.assetTypes.countDocuments(), nodes: db.nodes.countDocuments(), cases: db.cases.countDocuments(), users: db.users.countDocuments(), assetMappings: db.assetMappings.countDocuments()}})"

# Verify OpenSimulator
curl http://localhost:9000/simstatus/
# Should return "OK"
```

## Logs

| Service | Log File |
|---------|----------|
| Ariadne4j | VERSE/src/ariadne4j/logs/ariadne-console.log |
| OpenSimulator | ~/opensimulator/bin/opensim-console.log |
| MongoDB | /var/log/mongodb/mongod.log |

## Project History

This project originated as PIVOTE (Personal Interactive Virtual Training
Environment), an educational game engine built for Second Life by the
Northern Ontario School of Medicine. The original stack used:

- MySQL for structured data (cases, nodes, asset types)
- Redis for session caching
- JSP/Servlet backend on Tomcat
- Second Life as the virtual world platform

The OpenSim migration (this branch) replaces all of those with:

- MongoDB (replaces MySQL + Redis with a single unified database)
- Spring Boot 3 + Java 21 (replaces JSP/Servlet on Tomcat)
- OpenSimulator (replaces Second Life, self-hosted)

## License

This project is based on the Ariadne/PIVOTE educational game engine.
See the original project for licensing details.

## Further Reading

- [In-World Setup Guide](docs/in-world-setup-guide.md) -- How to create
  OpenSim objects and configure LSL scripts
- [Project Plan](plan.md) -- Full implementation plan (Phases 0-7)
- [OpenSimulator LSL Reference](http://opensimulator.org/wiki/LSL_Status/Functions)
- [OSSL Wiki](https://www.ossl.wiki/)
- [Second Life LSL Portal](https://wiki.secondlife.com/wiki/LSL_Portal)
