package com.nosm.elearning.ariadne;

import com.mongodb.client.*;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.Updates;
import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.*;

/**
 * MongoDB Backend for Ariadne Open-Labyrinth Integration
 * Handles node traversal, session management, and asset delivery
 */
public class AriadneMongoBackend {
    private static MongoClient mongoClient;
    private static MongoDatabase database;
    private static final String DB_NAME = "ariadne";
    private static final String MONGODB_URI = "mongodb://localhost:27017";

    // Collections
    private static final String CASES_COLLECTION = "cases";
    private static final String NODES_COLLECTION = "nodes";
    private static final String SESSIONS_COLLECTION = "sessions";
    private static final String USERS_COLLECTION = "users";
    private static final String ASSET_TYPES_COLLECTION = "assetTypes";

    /**
     * Initialize MongoDB connection (call once at startup)
     */
    public static void initialize() {
        if (mongoClient == null) {
            mongoClient = MongoClients.create(MONGODB_URI);
            database = mongoClient.getDatabase(DB_NAME);
            System.out.println("[Ariadne] MongoDB connected: " + MONGODB_URI + "/" + DB_NAME);
        }
    }

    /**
     * Shutdown MongoDB connection (call on application shutdown)
     */
    public static void shutdown() {
        if (mongoClient != null) {
            mongoClient.close();
            mongoClient = null;
            System.out.println("[Ariadne] MongoDB connection closed");
        }
    }

    /**
     * Get a node by ID with all questions and assets
     */
    public static Document getNode(int nodeId) {
        MongoCollection<Document> nodes = database.getCollection(NODES_COLLECTION);
        return nodes.find(Filters.eq("_id", nodeId)).first();
    }

    /**
     * Get a case by ID
     */
    public static Document getCase(int caseId) {
        MongoCollection<Document> cases = database.getCollection(CASES_COLLECTION);
        return cases.find(Filters.eq("_id", caseId)).first();
    }

    /**
     * Get start node for a case
     */
    public static Document getCaseStartNode(int caseId) {
        MongoCollection<Document> cases = database.getCollection(CASES_COLLECTION);
        Document caseDoc = cases.find(Filters.eq("_id", caseId)).first();
        if (caseDoc != null) {
            int startNodeId = caseDoc.getInteger("start_node_id");
            return getNode(startNodeId);
        }
        return null;
    }

    /**
     * Create or get a session for a player
     */
    public static Document createOrGetSession(String sessionId, int nodeId, String playerKey, String playerName) {
        MongoCollection<Document> sessions = database.getCollection(SESSIONS_COLLECTION);
        
        // Try to find existing session
        Document existingSession = sessions.find(Filters.eq("_id", sessionId)).first();
        if (existingSession != null) {
            return existingSession;
        }
        
        // Create new session with 1-hour TTL
        Document newSession = new Document()
            .append("_id", sessionId)
            .append("node_id", nodeId)
            .append("player_key", playerKey)
            .append("player_name", playerName)
            .append("variables", new Document())
            .append("answers", new ArrayList<>())
            .append("created_at", new Date())
            .append("expires_at", new Date(System.currentTimeMillis() + 3600000)); // 1 hour
        
        sessions.insertOne(newSession);
        return newSession;
    }

    /**
     * Get session by ID
     */
    public static Document getSession(String sessionId) {
        MongoCollection<Document> sessions = database.getCollection(SESSIONS_COLLECTION);
        return sessions.find(Filters.eq("_id", sessionId)).first();
    }

    /**
     * Submit an answer and get next node
     */
    public static Document submitAnswer(String sessionId, int nodeId, int questionId, Object answerValue) {
        MongoCollection<Document> sessions = database.getCollection(SESSIONS_COLLECTION);
        
        // Record the answer
        Document answer = new Document()
            .append("node_id", nodeId)
            .append("question_id", questionId)
            .append("answer_value", answerValue)
            .append("timestamp", new Date());
        
        sessions.updateOne(
            Filters.eq("_id", sessionId),
            Updates.push("answers", answer)
        );
        
        // Get current node to find next node
        Document currentNode = getNode(nodeId);
        if (currentNode != null) {
            List<Document> questions = (List<Document>) currentNode.get("questions");
            if (questions != null) {
                for (Document q : questions) {
                    if (q.getInteger("id") == questionId) {
                        int nextNodeId = q.getInteger("next_node_id");
                        return getNode(nextNodeId);
                    }
                }
            }
        }
        
        return currentNode; // Return same node if no next node found
    }

    /**
     * Update session variable
     */
    public static void setSessionVariable(String sessionId, String varName, Object varValue) {
        MongoCollection<Document> sessions = database.getCollection(SESSIONS_COLLECTION);
        sessions.updateOne(
            Filters.eq("_id", sessionId),
            Updates.set("variables." + varName, varValue)
        );
    }

    /**
     * Get session variable
     */
    public static Object getSessionVariable(String sessionId, String varName) {
        Document session = getSession(sessionId);
        if (session != null) {
            Document variables = (Document) session.get("variables");
            if (variables != null) {
                return variables.get(varName);
            }
        }
        return null;
    }

    /**
     * Get user by player key
     */
    public static Document getUser(String playerKey) {
        MongoCollection<Document> users = database.getCollection(USERS_COLLECTION);
        return users.find(Filters.eq("sl_player_key", playerKey)).first();
    }

    /**
     * Get all asset types
     */
    public static List<Document> getAllAssetTypes() {
        MongoCollection<Document> assetTypes = database.getCollection(ASSET_TYPES_COLLECTION);
        return assetTypes.find().into(new ArrayList<>());
    }

    /**
     * Get asset type by ID
     */
    public static Document getAssetType(int assetTypeId) {
        MongoCollection<Document> assetTypes = database.getCollection(ASSET_TYPES_COLLECTION);
        return assetTypes.find(Filters.eq("_id", assetTypeId)).first();
    }

    /**
     * Build XML response for node (for LSL parsing)
     */
    public static String buildNodeXML(Document nodeDoc, String sessionId) {
        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<node>\n");
        
        if (nodeDoc != null) {
            xml.append("  <id>").append(nodeDoc.getInteger("_id")).append("</id>\n");
            xml.append("  <title>").append(escapeXml(nodeDoc.getString("title"))).append("</title>\n");
            xml.append("  <content>").append(escapeXml(nodeDoc.getString("content"))).append("</content>\n");
            
            // Add questions
            xml.append("  <questions>\n");
            List<Document> questions = (List<Document>) nodeDoc.get("questions");
            if (questions != null) {
                for (Document q : questions) {
                    xml.append("    <question>\n");
                    xml.append("      <id>").append(q.getInteger("id")).append("</id>\n");
                    xml.append("      <type>").append(q.getString("type")).append("</type>\n");
                    xml.append("      <text>").append(escapeXml(q.getString("text"))).append("</text>\n");
                    
                    List<String> options = (List<String>) q.get("options");
                    if (options != null) {
                        xml.append("      <options>\n");
                        for (int i = 0; i < options.size(); i++) {
                            xml.append("        <option index=\"").append(i).append("\">")
                               .append(escapeXml(options.get(i))).append("</option>\n");
                        }
                        xml.append("      </options>\n");
                    }
                    xml.append("    </question>\n");
                }
            }
            xml.append("  </questions>\n");
            
            // Add Ariadne assets
            xml.append("  <assets>\n");
            List<Document> assets = (List<Document>) nodeDoc.get("ariadne_assets");
            if (assets != null) {
                for (Document asset : assets) {
                    xml.append("    <asset>\n");
                    xml.append("      <id>").append(asset.getInteger("id")).append("</id>\n");
                    xml.append("      <type>").append(asset.getString("type")).append("</type>\n");
                    xml.append("      <name>").append(escapeXml(asset.getString("name"))).append("</name>\n");
                    xml.append("      <value>").append(escapeXml(asset.getString("value"))).append("</value>\n");
                    xml.append("      <target>").append(escapeXml(asset.getString("target"))).append("</target>\n");
                    xml.append("    </asset>\n");
                }
            }
            xml.append("  </assets>\n");
        }
        
        xml.append("  <sessionId>").append(sessionId).append("</sessionId>\n");
        xml.append("</node>\n");
        
        return xml.toString();
    }

    /**
     * Escape XML special characters
     */
    private static String escapeXml(String input) {
        if (input == null) return "";
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;");
    }

    /**
     * Generate a session ID
     */
    public static String generateSessionId() {
        return UUID.randomUUID().toString();
    }
}
