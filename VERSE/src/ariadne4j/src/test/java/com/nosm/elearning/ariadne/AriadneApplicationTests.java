package com.nosm.elearning.ariadne;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

/**
 * Integration tests for Ariadne REST API
 * Tests XML response format, node retrieval, and session management
 */
@SpringBootTest
@AutoConfigureMockMvc
public class AriadneApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    /**
     * Test health check endpoint
     */
    @Test
    public void testHealthCheck() throws Exception {
        mockMvc.perform(get("/ariadne/api/node/health"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("Ariadne backend is running")));
    }

    /**
     * Test node retrieval with XML response format
     */
    @Test
    public void testGetNodeXMLFormat() throws Exception {
        MvcResult result = mockMvc.perform(get("/ariadne/api/node/1")
                .param("sessionId", "test-session-123"))
            .andExpect(status().isOk())
            .andExpect(content().contentType("application/xml;charset=UTF-8"))
            .andReturn();

        String xmlContent = result.getResponse().getContentAsString();
        
        // Verify XML structure
        assert xmlContent.contains("<?xml version=\"1.0\"");
        assert xmlContent.contains("<node>");
        assert xmlContent.contains("</node>");
        assert xmlContent.contains("<id>");
        assert xmlContent.contains("<title>");
        assert xmlContent.contains("<content>");
        assert xmlContent.contains("<questions>");
        assert xmlContent.contains("<assets>");
        assert xmlContent.contains("<sessionId>");
    }

    /**
     * Test XML character encoding (UTF-8)
     */
    @Test
    public void testXMLCharacterEncoding() throws Exception {
        MvcResult result = mockMvc.perform(get("/ariadne/api/node/1")
                .param("sessionId", "test-session-123"))
            .andExpect(status().isOk())
            .andReturn();

        String contentType = result.getResponse().getContentType();
        assert contentType.contains("UTF-8") || contentType.contains("utf-8");
    }

    /**
     * Test node not found returns 404
     */
    @Test
    public void testNodeNotFound() throws Exception {
        mockMvc.perform(get("/ariadne/api/node/99999")
                .param("sessionId", "test-session-123"))
            .andExpect(status().isNotFound());
    }

    /**
     * Test missing session ID parameter
     */
    @Test
    public void testMissingSessionId() throws Exception {
        mockMvc.perform(get("/ariadne/api/node/1"))
            .andExpect(status().isBadRequest());
    }

    /**
     * Test XML escaping for special characters
     */
    @Test
    public void testXMLEscaping() throws Exception {
        MvcResult result = mockMvc.perform(get("/ariadne/api/node/1")
                .param("sessionId", "test-session-123"))
            .andExpect(status().isOk())
            .andReturn();

        String xmlContent = result.getResponse().getContentAsString();
        
        // Verify special characters are properly escaped
        // & should be &amp;
        // < should be &lt;
        // > should be &gt;
        // " should be &quot;
        // ' should be &apos;
        
        // Check for proper XML structure (no unescaped special chars in content)
        assert !xmlContent.matches(".*>.*[&<>].*<.*");
    }

    /**
     * Test answer submission returns valid XML
     */
    @Test
    public void testSubmitAnswerXMLFormat() throws Exception {
        MvcResult result = mockMvc.perform(get("/ariadne/api/node/1/answer")
                .param("sessionId", "test-session-123")
                .param("questionId", "1")
                .param("answerValue", "option1"))
            .andExpect(status().isOk())
            .andExpect(content().contentType("application/xml;charset=UTF-8"))
            .andReturn();

        String xmlContent = result.getResponse().getContentAsString();
        
        // Verify XML structure for answer response
        assert xmlContent.contains("<?xml version=\"1.0\"");
        assert xmlContent.contains("<node>");
        assert xmlContent.contains("</node>");
    }

    /**
     * Test case retrieval returns JSON
     */
    @Test
    public void testGetCaseJSON() throws Exception {
        mockMvc.perform(get("/ariadne/api/node/case/1"))
            .andExpect(status().isOk());
    }

    /**
     * Test CORS headers are present
     */
    @Test
    public void testCORSHeaders() throws Exception {
        mockMvc.perform(get("/ariadne/api/node/health"))
            .andExpect(status().isOk())
            .andExpect(header().exists("Access-Control-Allow-Origin"));
    }
}
