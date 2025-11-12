package com.nosm.elearning.ariadne.service;

import org.springframework.stereotype.Service;
import org.bson.Document;
import com.nosm.elearning.ariadne.AriadneMongoBackend;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.*;

/**
 * Service layer for session management
 * Handles session creation, persistence, and TTL management
 */
@Service
public class SessionService {

    private static final Logger logger = LoggerFactory.getLogger(SessionService.class);

    /**
     * Create a new session or get existing one
     */
    public Document createOrGetSession(String sessionId, int nodeId, String playerKey, String playerName) {
        logger.debug("Creating/getting session {} for player {} at node {}", sessionId, playerName, nodeId);
        
        try {
            Document session = AriadneMongoBackend.createOrGetSession(sessionId, nodeId, playerKey, playerName);
            
            if (session == null) {
                logger.error("Failed to create session {}", sessionId);
                return null;
            }
            
            logger.info("Session {} created/retrieved for player {}", sessionId, playerName);
            return session;
            
        } catch (Exception e) {
            logger.error("Error creating session: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get session by ID
     */
    public Document getSession(String sessionId) {
        logger.debug("Retrieving session {}", sessionId);
        
        try {
            Document session = AriadneMongoBackend.getSession(sessionId);
            
            if (session == null) {
                logger.warn("Session {} not found or expired", sessionId);
                return null;
            }
            
            // Check if session is expired
            if (isSessionExpired(session)) {
                logger.warn("Session {} has expired", sessionId);
                return null;
            }
            
            return session;
            
        } catch (Exception e) {
            logger.error("Error retrieving session: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Validate session exists and is not expired
     */
    public boolean isSessionValid(String sessionId) {
        logger.debug("Validating session {}", sessionId);
        
        try {
            Document session = getSession(sessionId);
            return session != null && !isSessionExpired(session);
        } catch (Exception e) {
            logger.error("Error validating session: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Check if session has expired
     */
    private boolean isSessionExpired(Document session) {
        if (session == null || !session.containsKey("expires_at")) {
            return true;
        }
        
        Date expiresAt = session.getDate("expires_at");
        if (expiresAt == null) {
            return true;
        }
        
        return expiresAt.before(new Date());
    }

    /**
     * Get session variable
     */
    public Object getSessionVariable(String sessionId, String varName) {
        logger.debug("Getting session variable {} from session {}", varName, sessionId);
        
        try {
            if (!isSessionValid(sessionId)) {
                logger.warn("Cannot get variable from invalid/expired session {}", sessionId);
                return null;
            }
            
            return AriadneMongoBackend.getSessionVariable(sessionId, varName);
            
        } catch (Exception e) {
            logger.error("Error getting session variable: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Set session variable
     */
    public void setSessionVariable(String sessionId, String varName, Object varValue) {
        logger.debug("Setting session variable {} = {} in session {}", varName, varValue, sessionId);
        
        try {
            if (!isSessionValid(sessionId)) {
                logger.warn("Cannot set variable in invalid/expired session {}", sessionId);
                return;
            }
            
            AriadneMongoBackend.setSessionVariable(sessionId, varName, varValue);
            logger.debug("Session variable {} set successfully", varName);
            
        } catch (Exception e) {
            logger.error("Error setting session variable: {}", e.getMessage(), e);
        }
    }

    /**
     * Get all session variables
     */
    public Map<String, Object> getSessionVariables(String sessionId) {
        logger.debug("Getting all variables from session {}", sessionId);
        
        try {
            Document session = getSession(sessionId);
            if (session == null) {
                logger.warn("Session {} not found", sessionId);
                return new HashMap<>();
            }
            
            Document variables = (Document) session.get("variables");
            if (variables == null) {
                return new HashMap<>();
            }
            
            return new HashMap<>(variables);
            
        } catch (Exception e) {
            logger.error("Error getting session variables: {}", e.getMessage(), e);
            return new HashMap<>();
        }
    }

    /**
     * Get session answers
     */
    public List<Document> getSessionAnswers(String sessionId) {
        logger.debug("Getting answers from session {}", sessionId);
        
        try {
            Document session = getSession(sessionId);
            if (session == null) {
                logger.warn("Session {} not found", sessionId);
                return new ArrayList<>();
            }
            
            @SuppressWarnings("unchecked")
            List<Document> answers = (List<Document>) session.get("answers");
            if (answers == null) {
                return new ArrayList<>();
            }
            
            return new ArrayList<>(answers);
            
        } catch (Exception e) {
            logger.error("Error getting session answers: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Get session metadata
     */
    public Map<String, Object> getSessionMetadata(String sessionId) {
        logger.debug("Getting metadata from session {}", sessionId);
        
        try {
            Document session = getSession(sessionId);
            if (session == null) {
                logger.warn("Session {} not found", sessionId);
                return new HashMap<>();
            }
            
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("sessionId", session.getString("_id"));
            metadata.put("nodeId", session.getInteger("node_id"));
            metadata.put("playerKey", session.getString("player_key"));
            metadata.put("playerName", session.getString("player_name"));
            metadata.put("createdAt", session.getDate("created_at"));
            metadata.put("expiresAt", session.getDate("expires_at"));
            
            return metadata;
            
        } catch (Exception e) {
            logger.error("Error getting session metadata: {}", e.getMessage(), e);
            return new HashMap<>();
        }
    }

    /**
     * Generate a unique session ID
     */
    public String generateSessionId() {
        String sessionId = UUID.randomUUID().toString();
        logger.debug("Generated session ID: {}", sessionId);
        return sessionId;
    }

    /**
     * Validate session ID format
     */
    public boolean isValidSessionId(String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return false;
        }
        
        // UUID format validation
        try {
            UUID.fromString(sessionId);
            return true;
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid session ID format: {}", sessionId);
            return false;
        }
    }
}
