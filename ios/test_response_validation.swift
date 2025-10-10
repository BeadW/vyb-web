#!/usr/bin/env swift

import Foundation

// MARK: - Test Validation Functions

/// Validates if an API response appears to be complete and well-formed
private func isValidAPIResponse(_ response: String) -> Bool {
    // Check if response appears to be valid JSON structure
    guard !response.isEmpty else { return false }
    
    // Look for expected Gemini API response structure
    let hasExpectedStructure = response.contains("\"candidates\"") && 
                              response.contains("\"content\"") && 
                              response.contains("\"parts\"")
    
    // Check if response ends properly (not truncated)
    let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
    let endsWithValidJSON = trimmed.hasSuffix("}") || trimmed.hasSuffix("]")
    
    return hasExpectedStructure && endsWithValidJSON
}

/// Validates if JSON content appears complete for design variations
private func isCompleteJSONResponse(_ content: String) -> Bool {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove any markdown formatting
    let cleanedContent = trimmed
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check for expected structure
    let hasVariationsArray = cleanedContent.contains("\"variations\"") && 
                            cleanedContent.contains("[") && 
                            cleanedContent.contains("]")
    
    // Check if JSON appears complete
    let endsWithValidJSON = cleanedContent.hasSuffix("}") || cleanedContent.hasSuffix("]")
    
    // Basic bracket/brace matching check
    let openBraces = cleanedContent.filter { $0 == "{" }.count
    let closeBraces = cleanedContent.filter { $0 == "}" }.count
    let openBrackets = cleanedContent.filter { $0 == "[" }.count
    let closeBrackets = cleanedContent.filter { $0 == "]" }.count
    
    let bracketsMatch = openBraces == closeBraces && openBrackets == closeBrackets
    
    return hasVariationsArray && endsWithValidJSON && bracketsMatch
}

// MARK: - Test Cases

func testValidationFunctions() {
    print("🧪 Testing Response Validation Functions\n")
    
    // Test 1: Valid complete API response
    let validAPIResponse = """
    {
      "candidates": [
        {
          "content": {
            "parts": [
              {
                "text": "{\\"variations\\": []}"
              }
            ]
          }
        }
      ]
    }
    """
    
    print("Test 1 - Valid API Response:")
    print("Result: \(isValidAPIResponse(validAPIResponse) ? "✅ PASS" : "❌ FAIL")")
    print()
    
    // Test 2: Truncated API response (user's issue)
    let truncatedAPIResponse = """
    {
      "candidates": [
        {
          "content": {
            "parts": [
              {
                "text": "{\\"variations\\": ["
    """
    
    print("Test 2 - Truncated API Response:")
    print("Result: \(isValidAPIResponse(truncatedAPIResponse) ? "❌ FAIL (should detect truncation)" : "✅ PASS (correctly detected truncation)")")
    print()
    
    // Test 3: Valid complete JSON content
    let validJSONContent = """
    {
      "variations": [
        {
          "title": "Modern Minimalist",
          "description": "Clean lines and subtle colors",
          "layers": []
        }
      ]
    }
    """
    
    print("Test 3 - Valid JSON Content:")
    print("Result: \(isCompleteJSONResponse(validJSONContent) ? "✅ PASS" : "❌ FAIL")")
    print()
    
    // Test 4: Truncated JSON content (the actual parsing issue)
    let truncatedJSONContent = """
    {
      "variations": [
        {
          "title": "Modern Minimalist",
          "description": "Clean lines and
    """
    
    print("Test 4 - Truncated JSON Content:")
    print("Result: \(isCompleteJSONResponse(truncatedJSONContent) ? "❌ FAIL (should detect truncation)" : "✅ PASS (correctly detected truncation)")")
    print()
    
    // Test 5: JSON with markdown formatting
    let markdownJSONContent = """
    ```json
    {
      "variations": [
        {
          "title": "Test",
          "description": "Test",
          "layers": []
        }
      ]
    }
    ```
    """
    
    print("Test 5 - JSON with Markdown:")
    print("Result: \(isCompleteJSONResponse(markdownJSONContent) ? "✅ PASS" : "❌ FAIL")")
    print()
    
    // Test 6: Unbalanced brackets (incomplete)
    let unbalancedJSONContent = """
    {
      "variations": [
        {
          "title": "Test",
          "description": "Test"
        }
      }
    """
    // Missing closing brace for the outer object
    
    print("Test 6 - Unbalanced JSON:")
    print("Result: \(isCompleteJSONResponse(unbalancedJSONContent) ? "❌ FAIL (should detect imbalance)" : "✅ PASS (correctly detected imbalance)")")
    print()
    
    print("🎯 Test Summary:")
    print("- Valid responses should PASS validation")
    print("- Truncated/incomplete responses should FAIL validation")
    print("- This prevents JSON parsing errors by catching issues early")
}

// Run the tests
testValidationFunctions()