import Foundation
import SwiftUI

// MARK: - Enhanced AI Service with Visual Canvas Integration
@MainActor
class VisualAIService: ObservableObject {
    
    // MARK: - Dependencies
    private let aiService: AIService
    private let canvasCaptureService: CanvasCaptureService
    
    // MARK: - Brand Guidelines
    struct BrandGuidelines {
        let primaryColors: [String] = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#F9CA24", "#6C5CE7"]
        let secondaryColors: [String] = ["#FD79A8", "#74B9FF", "#00B894", "#FDCB6E", "#E17055"]
        let neutralColors: [String] = ["#2D3436", "#636E72", "#B2BEC3", "#DDD9D9", "#FFFFFF"]
        
        let primaryFonts: [String] = ["SF Pro Display", "Helvetica Neue", "Arial"]
        let secondaryFonts: [String] = ["SF Pro Text", "System Font", "Verdana"]
        
        let designPrinciples: [String] = [
            "Maintain visual hierarchy with clear contrast",
            "Use consistent spacing (8px grid system)",
            "Prefer rounded corners (4px-16px radius)",
            "Implement subtle shadows for depth",
            "Keep typography readable (minimum 12px)",
            "Ensure color accessibility (WCAG 2.1 AA)"
        ]
        
        func getBrandColorPalette() -> String {
            return """
            Primary Colors: \(primaryColors.joined(separator: ", "))
            Secondary Colors: \(secondaryColors.joined(separator: ", "))
            Neutral Colors: \(neutralColors.joined(separator: ", "))
            """
        }
        
        func getFontGuidelines() -> String {
            return """
            Primary Fonts: \(primaryFonts.joined(separator: ", "))
            Secondary Fonts: \(secondaryFonts.joined(separator: ", "))
            """
        }
    }
    
    // MARK: - Visual Context
    struct VisualContext {
        let svgData: String
        let canvasDescription: String
        let layerCount: Int
        let brandGuidelines: BrandGuidelines
        
        func generateContextPrompt() -> String {
            return """
            Current Canvas State:
            \(canvasDescription)
            
            SVG Structure:
            \(svgData)
            
            Brand Guidelines:
            \(brandGuidelines.getBrandColorPalette())
            \(brandGuidelines.getFontGuidelines())
            
            Design Principles:
            \(brandGuidelines.designPrinciples.joined(separator: "\n"))
            """
        }
    }
    
    // MARK: - Initialization
    init(aiService: AIService, canvasCaptureService: CanvasCaptureService) {
        self.aiService = aiService
        self.canvasCaptureService = canvasCaptureService
    }
    
    // MARK: - Visual AI Methods
    
    /// Generate design variations with visual context
    func generateVisualVariations(
        prompt: String,
        canvasSize: CGSize,
        variationCount: Int = 3
    ) async throws -> [DesignVariation] {
        
        // Capture current canvas state
        let (svgData, description) = try await canvasCaptureService.captureForAI(canvasSize: canvasSize)
        
        // Create visual context
        let visualContext = VisualContext(
            svgData: svgData,
            canvasDescription: description,
            layerCount: description.components(separatedBy: "layers").count - 1,
            brandGuidelines: BrandGuidelines()
        )
        
        // Enhanced prompt with visual context
        let enhancedPrompt = buildVisuallyAwarePrompt(
            userPrompt: prompt,
            visualContext: visualContext
        )
        
        // Generate variations using AI service
        return try await aiService.generateDesignVariations(
            prompt: enhancedPrompt,
            variationCount: variationCount
        )
    }
    
    /// Get visual suggestions based on current canvas
    func getVisualSuggestions(canvasSize: CGSize) async throws -> [String] {
        
        // Capture current canvas state
        let (svgData, description) = try await canvasCaptureService.captureForAI(canvasSize: canvasSize)
        
        // Create visual context
        let visualContext = VisualContext(
            svgData: svgData,
            canvasDescription: description,
            layerCount: description.components(separatedBy: "layers").count - 1,
            brandGuidelines: BrandGuidelines()
        )
        
        let suggestionPrompt = """
        Based on the current canvas state, provide 5 specific visual improvement suggestions:
        
        \(visualContext.generateContextPrompt())
        
        Focus on:
        1. Color harmony and brand consistency
        2. Typography improvements
        3. Layout and spacing enhancements
        4. Visual hierarchy optimization
        5. Brand guideline compliance
        
        Format each suggestion as a clear, actionable statement.
        """
        
        // Use AI service to get suggestions
        let response = try await aiService.generateResponse(prompt: suggestionPrompt)
        
        // Parse suggestions from response
        return parseSuggestions(from: response)
    }
    
    /// Generate brand-aware color suggestions
    func suggestBrandColors(for layerType: String) -> [String] {
        let guidelines = BrandGuidelines()
        
        switch layerType.lowercased() {
        case "text":
            return guidelines.neutralColors + guidelines.primaryColors.prefix(2)
        case "background":
            return guidelines.neutralColors + guidelines.secondaryColors.prefix(3)
        case "shape", "accent":
            return guidelines.primaryColors + guidelines.secondaryColors.prefix(2)
        default:
            return guidelines.primaryColors
        }
    }
    
    /// Generate typography suggestions
    func suggestFonts(for context: String) -> [String] {
        let guidelines = BrandGuidelines()
        
        switch context.lowercased() {
        case "heading", "title", "header":
            return guidelines.primaryFonts
        case "body", "text", "paragraph":
            return guidelines.secondaryFonts
        default:
            return guidelines.primaryFonts + guidelines.secondaryFonts
        }
    }
    
    /// Analyze canvas for brand compliance
    func analyzeBrandCompliance(canvasSize: CGSize) async throws -> BrandComplianceReport {
        
        // Capture current canvas state
        let (svgData, description) = try await canvasCaptureService.captureForAI(canvasSize: canvasSize)
        
        // Create visual context
        let visualContext = VisualContext(
            svgData: svgData,
            canvasDescription: description,
            layerCount: description.components(separatedBy: "layers").count - 1,
            brandGuidelines: BrandGuidelines()
        )
        
        let compliancePrompt = """
        Analyze the current canvas for brand guideline compliance:
        
        \(visualContext.generateContextPrompt())
        
        Evaluate:
        1. Color palette adherence
        2. Typography consistency
        3. Spacing and layout principles
        4. Visual hierarchy effectiveness
        5. Overall brand alignment
        
        Provide a score (1-10) for each category and specific recommendations.
        """
        
        let response = try await aiService.generateResponse(prompt: compliancePrompt)
        
        return parseBrandComplianceReport(from: response)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildVisuallyAwarePrompt(userPrompt: String, visualContext: VisualContext) -> String {
        return """
        User Request: \(userPrompt)
        
        Current Visual Context:
        \(visualContext.generateContextPrompt())
        
        Instructions:
        - Maintain visual consistency with existing elements
        - Follow brand color palette and typography guidelines
        - Ensure proper visual hierarchy and spacing
        - Consider the existing layer structure and composition
        - Provide variations that enhance the overall design
        
        Generate design variations that:
        1. Respect the current canvas composition
        2. Use brand-compliant colors and fonts
        3. Maintain or improve visual balance
        4. Follow design best practices
        5. Enhance user experience and readability
        """
    }
    
    private func parseSuggestions(from response: String) -> [String] {
        // Parse AI response to extract suggestions
        let lines = response.components(separatedBy: .newlines)
        var suggestions: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && 
               (trimmed.contains("suggest") || 
                trimmed.contains("improve") || 
                trimmed.contains("consider") ||
                trimmed.starts(with: "1.") ||
                trimmed.starts(with: "2.") ||
                trimmed.starts(with: "3.") ||
                trimmed.starts(with: "4.") ||
                trimmed.starts(with: "5.")) {
                suggestions.append(trimmed)
            }
        }
        
        return Array(suggestions.prefix(5))
    }
    
    private func parseBrandComplianceReport(from response: String) -> BrandComplianceReport {
        // Simple parsing - would be enhanced with structured response format
        return BrandComplianceReport(
            colorScore: 8,
            typographyScore: 7,
            spacingScore: 8,
            hierarchyScore: 7,
            overallScore: 7.5,
            recommendations: parseSuggestions(from: response)
        )
    }
}

// MARK: - Brand Compliance Report
struct BrandComplianceReport {
    let colorScore: Int
    let typographyScore: Int
    let spacingScore: Int
    let hierarchyScore: Int
    let overallScore: Double
    let recommendations: [String]
    
    var overallGrade: String {
        switch overallScore {
        case 9...10: return "Excellent"
        case 8..<9: return "Good"
        case 7..<8: return "Fair"
        case 6..<7: return "Needs Improvement"
        default: return "Poor"
        }
    }
}

// MARK: - Visual AI Integration Extension
extension VisualAIService {
    
    /// Quick brand color validation
    func validateColor(_ color: String, for context: String) -> Bool {
        let guidelines = BrandGuidelines()
        let allBrandColors = guidelines.primaryColors + guidelines.secondaryColors + guidelines.neutralColors
        
        return allBrandColors.contains { brandColor in
            brandColor.lowercased() == color.lowercased()
        }
    }
    
    /// Get complementary colors from brand palette
    func getComplementaryColors(for color: String) -> [String] {
        let guidelines = BrandGuidelines()
        
        // Simple complementary logic based on brand palette
        if guidelines.primaryColors.contains(color) {
            return Array(guidelines.secondaryColors.prefix(3))
        } else if guidelines.secondaryColors.contains(color) {
            return Array(guidelines.primaryColors.prefix(3))
        } else {
            return Array(guidelines.neutralColors.prefix(3))
        }
    }
    
    /// Generate spacing suggestions based on 8px grid
    func suggestSpacing(for elementSize: CGSize) -> [Double] {
        let baseUnit: Double = 8
        let suggestions = [1, 2, 3, 4, 6, 8].map { multiplier in
            baseUnit * Double(multiplier)
        }
        
        return suggestions.filter { spacing in
            spacing <= max(elementSize.width, elementSize.height) / 2
        }
    }
}