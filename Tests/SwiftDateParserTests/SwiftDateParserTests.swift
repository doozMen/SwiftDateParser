import Testing
@testable import SwiftDateParser
import Foundation

@Suite("SwiftDateParser API Tests")
struct SwiftDateParserTests {
    
    @Test("Convenience parse methods")
    func testConvenienceMethods() throws {
        // Test the convenience parse method
        let date1 = try SwiftDateParser.parse("2023-12-25")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date1)
        #expect(components.year == 2023)
        #expect(components.month == 12)
        #expect(components.day == 25)
        
        // Test relative date parsing
        _ = try SwiftDateParser.parse("tomorrow")
        _ = try SwiftDateParser.parse("3 days ago")
    }
    
    @Test("Date extraction from text")
    func testDateExtraction() {
        let text = "The meeting is on January 15, 2024 at 3 PM. Please confirm by tomorrow."
        let extracted = SwiftDateParser.extractDates(from: text)
        
        #expect(extracted.count > 0, "Should extract at least one date")
        
        // Print extracted dates for verification
        for date in extracted {
            print("Extracted: '\(date.text)' with confidence \(date.confidence)")
        }
    }
    
    @Test("Version string")
    func testVersionString() {
        #expect(SwiftDateParser.version == "1.0.1")
    }
    
    @Test("Create parser factory")
    func testCreateParser() {
        let parser = SwiftDateParser.createParser(
            dayfirst: true,
            yearfirst: false,
            fuzzy: true
        )
        
        // Parser is non-optional, so we validate it exists
        #expect(true, "Created parser instance successfully")
    }
    
    @Test("Create extractor factory")
    func testCreateExtractor() {
        let extractor = SwiftDateParser.createExtractor()
        // Extractor is non-optional, so we validate it exists
        #expect(true, "Created extractor instance successfully")
    }
    
    @Test("Integration example with email parsing")
    func testIntegrationExample() throws {
        // Example of using the library for a real-world scenario
        let emailText = """
        Hi team,
        
        Just a reminder that our quarterly review is scheduled for March 15, 2024.
        We had great results last month, and I'd like to discuss our plans for next quarter.
        
        Please submit your reports by end of day tomorrow. If you can't make it to the 
        meeting on Friday, let me know by Wednesday.
        
        Thanks!
        """
        
        // Extract all dates from the email
        let dates = SwiftDateParser.extractDates(from: emailText)
        
        print("\nFound \(dates.count) dates in the email:")
        for extractedDate in dates {
            print("- '\(extractedDate.text)' (confidence: \(extractedDate.confidence))")
        }
        
        #expect(dates.count > 2, "Should find multiple dates in the email")
    }
}