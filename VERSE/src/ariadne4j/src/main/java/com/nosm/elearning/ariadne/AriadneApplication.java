package com.nosm.elearning.ariadne;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Spring Boot Application for Ariadne - OpenSimulator Edition
 * Educational game engine with MongoDB backend and Open-Labyrinth integration
 */
@SpringBootApplication
public class AriadneApplication {

    private static final Logger logger = LoggerFactory.getLogger(AriadneApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(AriadneApplication.class, args);
        logger.info("Ariadne Application started successfully");
    }

    /**
     * MongoDB client bean for dependency injection
     */
    @Bean
    public MongoClient mongoClient() {
        String mongoUri = System.getenv("MONGODB_URI");
        if (mongoUri == null) {
            mongoUri = "mongodb://localhost:27017";
        }
        logger.info("Connecting to MongoDB: {}", mongoUri);
        MongoClient client = MongoClients.create(mongoUri);
        
        // Initialize backend with MongoDB client
        AriadneMongoBackend.initialize();
        
        return client;
    }
}
