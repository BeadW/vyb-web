#!/usr/bin/env swift

import Foundation

// Mock the Foundation Models availability check for testing
var mockFoundationModelsAvailable = false

// Test the strict provider selection logic
func testStrictProviderSelection() {
    print("🔍 Testing Strict Provider Selection Logic")
    print("==========================================")
    
    // Test Case 1: Foundation Models available - should ONLY use Apple Intelligence
    print("\n📱 Test Case 1: Foundation Models Available")
    mockFoundationModelsAvailable = true
    
    let provider1 = getBestProviderForTest()
    let info1 = getProviderSelectionInfoForTest()
    
    print("   Provider Selected: \(provider1)")
    print("   UI Reason: \(info1.reason)")
    
    if provider1 == "Apple Intelligence" && info1.reason.contains("ONLY") {
        print("   ✅ PASS: Correctly selected Apple Intelligence ONLY")
    } else {
        print("   ❌ FAIL: Should select Apple Intelligence ONLY when Foundation Models available")
    }
    
    // Test Case 2: Foundation Models NOT available - should ONLY use Gemini
    print("\n📱 Test Case 2: Foundation Models NOT Available")
    mockFoundationModelsAvailable = false
    
    let provider2 = getBestProviderForTest()
    let info2 = getProviderSelectionInfoForTest()
    
    print("   Provider Selected: \(provider2)")
    print("   UI Reason: \(info2.reason)")
    
    if provider2 == "Gemini" && info2.reason.contains("ONLY") {
        print("   ✅ PASS: Correctly selected Gemini ONLY")
    } else {
        print("   ❌ FAIL: Should select Gemini ONLY when Foundation Models NOT available")
    }
    
    // Summary
    print("\n🎯 Summary")
    print("==========")
    print("This test validates the strict protocol pattern:")
    print("• Foundation Models capable devices → Apple Intelligence ONLY")
    print("• Foundation Models incapable devices → Gemini ONLY")
    print("• NO fallback mixing between providers")
}

// Mock implementation of the provider selection logic from AIProviderProtocol.swift
func getBestProviderForTest() -> String {
    if #available(iOS 26.0, *) {
        // Mock Foundation Models asset availability check
        if mockFoundationModelsAvailable {
            return "Apple Intelligence"
        }
    }
    return "Gemini"
}

func getProviderSelectionInfoForTest() -> (current: String, available: [String], reason: String) {
    let currentProvider = getBestProviderForTest()
    let availableProviders = ["Apple Intelligence", "Gemini"]
    
    let reason: String
    if currentProvider == "Apple Intelligence" {
        reason = "Device supports Foundation Models - using Apple Intelligence ONLY"
    } else if currentProvider == "Gemini" {
        reason = "Device does NOT support Foundation Models - using Gemini ONLY"
    } else {
        reason = "No AI provider available"
    }
    
    return (current: currentProvider, available: availableProviders, reason: reason)
}

// Run the test
testStrictProviderSelection()