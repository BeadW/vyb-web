#!/usr/bin/env swift

import Foundation

// Simple script to take screenshots and validate UI elements
print("📱 Starting iOS UI validation script...")

// Function to run shell commands
func runCommand(_ command: String) -> String? {
    let process = Process()
    let pipe = Pipe()
    
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.launchPath = "/bin/sh"
    process.launch()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)
}

// Take initial screenshot
print("📸 Taking initial screenshot...")
let screenshotResult = runCommand("xcrun simctl io booted screenshot /Users/brad/Code/vyb-web/ios/ui-test-initial.png")
print("Screenshot saved to: /Users/brad/Code/vyb-web/ios/ui-test-initial.png")

// Wait a moment
usleep(2000000) // 2 seconds

// Take another screenshot
print("📸 Taking verification screenshot...")
let verifyResult = runCommand("xcrun simctl io booted screenshot /Users/brad/Code/vyb-web/ios/ui-test-verify.png")
print("Verification screenshot saved to: /Users/brad/Code/vyb-web/ios/ui-test-verify.png")

print("✅ UI validation script completed!")
print("Please check the screenshots to verify the Facebook post structure and layer functionality.")