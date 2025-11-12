package com.nosm.elearning.ariadne.service;

import org.springframework.stereotype.Service;
import org.bson.Document;
import com.nosm.elearning.ariadne.AriadneMongoBackend;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

/**
 * Service layer for node traversal and asset delivery
 * Handles business logic for Open-Labyrinth node operations
 */
@Service
public class NodeService {

    private static final Logger logger = LoggerFactory.getLogger(NodeService.class);

    /**
     * Get a node with all questions and Ariadne assets
     */
    public Document getNodeWithAssets(int nodeId) {
        logger.debug("Fetching node {} with assets", nodeId);
        Document node = AriadneMongoBackend.getNode(nodeId);
        
        if (node == null) {
            logger.warn("Node {} not found", nodeId);
            return null;
        }
        
        // Validate node structure
        validateNodeStructure(node);
        return node;
    }

    /**
     * Process an answer and get the next node
     */
    public Document processAnswer(String sessionId, int nodeId, int questionId, Object answerValue) {
        logger.debug("Processing answer for node {}, question {}", nodeId, questionId);
        
        try {
            // Record the answer
            Document nextNode = AriadneMongoBackend.submitAnswer(sessionId, nodeId, questionId, answerValue);
            
            if (nextNode == null) {
                logger.warn("No next node found after answering question {} in node {}", questionId, nodeId);
                return null;
            }
            
            // Validate next node
            validateNodeStructure(nextNode);
            return nextNode;
            
        } catch (Exception e) {
            logger.error("Error processing answer: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get a case by ID
     */
    public Document getCase(int caseId) {
        logger.debug("Fetching case {}", caseId);
        Document caseDoc = AriadneMongoBackend.getCase(caseId);
        
        if (caseDoc == null) {
            logger.warn("Case {} not found", caseId);
            return null;
        }
        
        return caseDoc;
    }

    /**
     * Get the start node for a case
     */
    public Document getCaseStartNode(int caseId) {
        logger.debug("Fetching start node for case {}", caseId);
        Document startNode = AriadneMongoBackend.getCaseStartNode(caseId);
        
        if (startNode == null) {
            logger.warn("Start node not found for case {}", caseId);
            return null;
        }
        
        validateNodeStructure(startNode);
        return startNode;
    }

    /**
     * Create or get a session
     */
    public Document createOrGetSession(String sessionId, int nodeId, String playerKey, String playerName) {
        logger.debug("Creating/getting session {} for player {}", sessionId, playerName);
        
        try {
            Document session = AriadneMongoBackend.createOrGetSession(sessionId, nodeId, playerKey, playerName);
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
        logger.debug("Fetching session {}", sessionId);
        Document session = AriadneMongoBackend.getSession(sessionId);
        
        if (session == null) {
            logger.warn("Session {} not found or expired", sessionId);
            return null;
        }
        
        return session;
    }

    /**
     * Set a session variable
     */
    public void setSessionVariable(String sessionId, String varName, Object varValue) {
        logger.debug("Setting session variable {} = {}", varName, varValue);
        
        try {
            AriadneMongoBackend.setSessionVariable(sessionId, varName, varValue);
        } catch (Exception e) {
            logger.error("Error setting session variable: {}", e.getMessage(), e);
        }
    }

    /**
     * Get a session variable
     */
    public Object getSessionVariable(String sessionId, String varName) {
        logger.debug("Getting session variable {}", varName);
        
        try {
            return AriadneMongoBackend.getSessionVariable(sessionId, varName);
        } catch (Exception e) {
            logger.error("Error getting session variable: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get user by player key
     */
    public Document getUser(String playerKey) {
        logger.debug("Fetching user with player key {}", playerKey);
        Document user = AriadneMongoBackend.getUser(playerKey);
        
        if (user == null) {
            logger.warn("User with player key {} not found", playerKey);
            return null;
        }
        
        return user;
    }

    /**
     * Validate node structure
     */
    private void validateNodeStructure(Document node) {
        if (node == null) {
            throw new IllegalArgumentException("Node cannot be null");
        }
        
        if (!node.containsKey("_id")) {
            logger.warn("Node missing _id field");
        }
        
        if (!node.containsKey("title")) {
            logger.warn("Node missing title field");
        }
        
        if (!node.containsKey("content")) {
            logger.warn("Node missing content field");
        }
    }

    /**
     * Build XML response for node
     */
    public String buildNodeXML(Document nodeDoc, String sessionId) {
        logger.debug("Building XML for node with session {}", sessionId);
        
        try {
            return AriadneMongoBackend.buildNodeXML(nodeDoc, sessionId);
        } catch (Exception e) {
            logger.error("Error building node XML: {}", e.getMessage(), e);
            return "<?xml version=\"1.0\"?><error>Failed to build XML</error>";
        }
    }
}
