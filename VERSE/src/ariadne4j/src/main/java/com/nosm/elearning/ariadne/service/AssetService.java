package com.nosm.elearning.ariadne.service;

import org.springframework.stereotype.Service;
import org.bson.Document;
import com.nosm.elearning.ariadne.AriadneMongoBackend;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.*;

/**
 * Service layer for asset management
 * Handles asset types, asset retrieval, and asset metadata
 */
@Service
public class AssetService {

    private static final Logger logger = LoggerFactory.getLogger(AssetService.class);

    /**
     * Get all asset types
     */
    public List<Document> getAllAssetTypes() {
        logger.debug("Fetching all asset types");
        
        try {
            List<Document> assetTypes = AriadneMongoBackend.getAllAssetTypes();
            
            if (assetTypes == null || assetTypes.isEmpty()) {
                logger.warn("No asset types found");
                return new ArrayList<>();
            }
            
            logger.debug("Found {} asset types", assetTypes.size());
            return assetTypes;
            
        } catch (Exception e) {
            logger.error("Error fetching asset types: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Get asset type by name
     */
    public Document getAssetType(String assetTypeName) {
        logger.debug("Fetching asset type {}", assetTypeName);
        
        try {
            // Search through all asset types to find by name
            List<Document> allTypes = getAllAssetTypes();
            for (Document assetType : allTypes) {
                if (assetTypeName.equals(assetType.getString("name"))) {
                    validateAssetTypeStructure(assetType);
                    return assetType;
                }
            }
            
            logger.warn("Asset type {} not found", assetTypeName);
            return null;
            
        } catch (Exception e) {
            logger.error("Error fetching asset type {}: {}", assetTypeName, e.getMessage(), e);
            return null;
        }
    }

    /**
     * Get asset types by category
     */
    public List<Document> getAssetTypesByCategory(String category) {
        logger.debug("Fetching asset types in category: {}", category);
        
        try {
            List<Document> assetTypes = getAllAssetTypes();
            List<Document> filtered = new ArrayList<>();
            
            for (Document assetType : assetTypes) {
                String assetCategory = assetType.getString("category");
                if (category.equals(assetCategory)) {
                    filtered.add(assetType);
                }
            }
            
            logger.debug("Found {} asset types in category {}", filtered.size(), category);
            return filtered;
            
        } catch (Exception e) {
            logger.error("Error fetching asset types by category: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Get asset metadata
     */
    public Map<String, Object> getAssetTypeMetadata(String assetTypeId) {
        logger.debug("Fetching metadata for asset type {}", assetTypeId);
        
        try {
            Document assetType = getAssetType(assetTypeId);
            if (assetType == null) {
                logger.warn("Asset type {} not found", assetTypeId);
                return new HashMap<>();
            }
            
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("id", assetType.getString("_id"));
            metadata.put("name", assetType.getString("name"));
            metadata.put("category", assetType.getString("category"));
            metadata.put("description", assetType.getString("description"));
            metadata.put("handler", assetType.getString("handler"));
            
            return metadata;
            
        } catch (Exception e) {
            logger.error("Error fetching asset type metadata: {}", e.getMessage(), e);
            return new HashMap<>();
        }
    }

    /**
     * Check if asset type exists
     */
    public boolean assetTypeExists(String assetTypeId) {
        logger.debug("Checking if asset type {} exists", assetTypeId);
        
        try {
            Document assetType = getAssetType(assetTypeId);
            return assetType != null;
            
        } catch (Exception e) {
            logger.error("Error checking asset type existence: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Get asset type count
     */
    public int getAssetTypeCount() {
        logger.debug("Getting asset type count");
        
        try {
            List<Document> assetTypes = getAllAssetTypes();
            return assetTypes.size();
            
        } catch (Exception e) {
            logger.error("Error getting asset type count: {}", e.getMessage(), e);
            return 0;
        }
    }

    /**
     * Validate asset type structure
     */
    private void validateAssetTypeStructure(Document assetType) {
        if (assetType == null) {
            throw new IllegalArgumentException("Asset type cannot be null");
        }
        
        if (!assetType.containsKey("_id")) {
            logger.warn("Asset type missing _id field");
        }
        
        if (!assetType.containsKey("name")) {
            logger.warn("Asset type missing name field");
        }
        
        if (!assetType.containsKey("category")) {
            logger.warn("Asset type missing category field");
        }
    }
}
