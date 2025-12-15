package com.nosm.elearning.ariadne.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.beans.factory.annotation.Autowired;
import com.nosm.elearning.ariadne.service.NodeService;
import com.nosm.elearning.ariadne.AriadneMongoBackend;
import org.bson.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * REST Controller for Open-Labyrinth node traversal
 * Handles node retrieval, question answering, and asset delivery
 */
@RestController
@RequestMapping("/api/node")
@CrossOrigin(origins = "*")
public class NodeController {

    private static final Logger logger = LoggerFactory.getLogger(NodeController.class);

    @Autowired
    private NodeService nodeService;

    /**
     * Get a node with all questions and Ariadne assets
     * 
     * @param nodeId the node ID
     * @param sessionId the session ID
     * @return XML response with node data
     */
    @GetMapping("/{nodeId}")
    public ResponseEntity<String> getNode(
            @PathVariable int nodeId,
            @RequestParam(required = false, defaultValue = "anonymous") String sessionId) {
        
        logger.debug("Retrieving node {} for session {}", nodeId, sessionId);
        
        try {
            Document nodeDoc = nodeService.getNodeWithAssets(nodeId);
            if (nodeDoc == null) {
                logger.warn("Node {} not found", nodeId);
                return ResponseEntity.notFound().build();
            }
            
            String xml = nodeService.buildNodeXML(nodeDoc, sessionId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_XML);
            
            logger.debug("Returning node {} XML (length: {})", nodeId, xml.length());
            return ResponseEntity.ok()
                .headers(headers)
                .body(xml);
                
        } catch (Exception e) {
            logger.error("Error retrieving node {}: {}", nodeId, e.getMessage(), e);
            return ResponseEntity.status(500).body(
                "<?xml version=\"1.0\"?><error>Failed to retrieve node</error>");
        }
    }

    /**
     * Submit an answer to a question and get the next node
     * 
     * @param nodeId the current node ID
     * @param sessionId the session ID
     * @param questionId the question ID
     * @param answerValue the answer value
     * @return XML response with next node data
     */
    @PostMapping("/{nodeId}/answer")
    public ResponseEntity<String> submitAnswer(
            @PathVariable int nodeId,
            @RequestParam String sessionId,
            @RequestParam int questionId,
            @RequestParam String answerValue) {
        
        logger.debug("Submitting answer for node {}, question {}, session {}", 
            nodeId, questionId, sessionId);
        
        try {
            Document nextNode = nodeService.processAnswer(
                sessionId, nodeId, questionId, answerValue);
            
            if (nextNode == null) {
                logger.warn("No next node found for node {}", nodeId);
                return ResponseEntity.notFound().build();
            }
            
            String xml = nodeService.buildNodeXML(nextNode, sessionId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_XML);
            
            logger.debug("Returning next node XML (length: {})", xml.length());
            return ResponseEntity.ok()
                .headers(headers)
                .body(xml);
                
        } catch (Exception e) {
            logger.error("Error processing answer for node {}: {}", nodeId, e.getMessage(), e);
            return ResponseEntity.status(500).body(
                "<?xml version=\"1.0\"?><error>Failed to process answer</error>");
        }
    }

    /**
     * Get a case by ID
     * 
     * @param caseId the case ID
     * @return JSON response with case data
     */
    @GetMapping("/case/{caseId}")
    public ResponseEntity<?> getCase(@PathVariable int caseId) {
        logger.debug("Retrieving case {}", caseId);
        
        try {
            Document caseDoc = AriadneMongoBackend.getCase(caseId);
            if (caseDoc == null) {
                logger.warn("Case {} not found", caseId);
                return ResponseEntity.notFound().build();
            }
            
            return ResponseEntity.ok(caseDoc);
            
        } catch (Exception e) {
            logger.error("Error retrieving case {}: {}", caseId, e.getMessage(), e);
            return ResponseEntity.status(500).body("Failed to retrieve case");
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        logger.debug("Health check requested");
        return ResponseEntity.ok("Ariadne backend is running");
    }
}
