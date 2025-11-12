package com.nosm.elearning.ariadne.service;

import org.springframework.stereotype.Service;
import org.bson.Document;
import com.nosm.elearning.ariadne.AriadneMongoBackend;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.*;

/**
 * Service layer for case management
 * Handles case retrieval, node traversal, and case metadata
 */
@Service
public class CaseService {

    private static final Logger logger = LoggerFactory.getLogger(CaseService.class);

    /**
     * Get a case by ID
     */
    public Document getCase(int caseId) {
        logger.debug("Fetching case {}", caseId);
        
        try {
            Document caseDoc = AriadneMongoBackend.getCase(caseId);
            
            if (caseDoc == null) {
                logger.warn("Case {} not found", caseId);
                return null;
            }
            
            validateCaseStructure(caseDoc);
            return caseDoc;
            
        } catch (Exception e) {
            logger.error("Error fetching case {}: {}", caseId, e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get the start node for a case
     */
    public Document getCaseStartNode(int caseId) {
        logger.debug("Fetching start node for case {}", caseId);
        
        try {
            Document startNode = AriadneMongoBackend.getCaseStartNode(caseId);
            
            if (startNode == null) {
                logger.warn("Start node not found for case {}", caseId);
                return null;
            }
            
            return startNode;
            
        } catch (Exception e) {
            logger.error("Error fetching start node for case {}: {}", caseId, e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get all cases (for case list)
     */
    public List<Document> getAllCases() {
        logger.debug("Fetching all cases");
        
        try {
            List<Document> cases = new ArrayList<>();
            // This would need to be implemented in AriadneMongoBackend
            // For now, return empty list as placeholder
            return cases;
            
        } catch (Exception e) {
            logger.error("Error fetching all cases: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Get cases by filter (title, description, etc.)
     */
    public List<Document> getCasesByFilter(String filter) {
        logger.debug("Fetching cases with filter: {}", filter);
        
        try {
            List<Document> cases = new ArrayList<>();
            // This would need to be implemented in AriadneMongoBackend
            // For now, return empty list as placeholder
            return cases;
            
        } catch (Exception e) {
            logger.error("Error fetching cases by filter: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Get case metadata
     */
    public Map<String, Object> getCaseMetadata(int caseId) {
        logger.debug("Fetching metadata for case {}", caseId);
        
        try {
            Document caseDoc = getCase(caseId);
            if (caseDoc == null) {
                logger.warn("Case {} not found", caseId);
                return new HashMap<>();
            }
            
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("caseId", caseDoc.getInteger("_id"));
            metadata.put("title", caseDoc.getString("title"));
            metadata.put("description", caseDoc.getString("description"));
            metadata.put("startNodeId", caseDoc.getInteger("start_node_id"));
            metadata.put("nodeCount", caseDoc.getInteger("node_count"));
            metadata.put("createdAt", caseDoc.getDate("created_at"));
            
            return metadata;
            
        } catch (Exception e) {
            logger.error("Error fetching case metadata: {}", e.getMessage(), e);
            return new HashMap<>();
        }
    }

    /**
     * Validate case structure
     */
    private void validateCaseStructure(Document caseDoc) {
        if (caseDoc == null) {
            throw new IllegalArgumentException("Case cannot be null");
        }
        
        if (!caseDoc.containsKey("_id")) {
            logger.warn("Case missing _id field");
        }
        
        if (!caseDoc.containsKey("title")) {
            logger.warn("Case missing title field");
        }
        
        if (!caseDoc.containsKey("start_node_id")) {
            logger.warn("Case missing start_node_id field");
        }
    }
}
