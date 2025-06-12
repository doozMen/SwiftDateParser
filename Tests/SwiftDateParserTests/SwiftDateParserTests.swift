import XCTest
@testable import SwiftDateParser

final class SwiftDateParserTests: XCTestCase {
    
    func testConvenienceMethods() throws {
        // Test the convenience parse method
        let date1 = try SwiftDateParser.parse("2023-12-25")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date1)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
        
        // Test relative date parsing
        let _ = try SwiftDateParser.parse("tomorrow")
        let _ = try SwiftDateParser.parse("3 days ago")
    }
    
    func testDateExtraction() {
        let text = "The meeting is on January 15, 2024 at 3 PM. Please confirm by tomorrow."
        let extracted = SwiftDateParser.extractDates(from: text)
        
        XCTAssertGreaterThan(extracted.count, 0, "Should extract at least one date")
        
        // Print extracted dates for verification
        for date in extracted {
            print("Extracted: '\(date.text)' with confidence \(date.confidence)")
        }
    }
    
    func testVersionString() {
        XCTAssertEqual(SwiftDateParser.version, "1.0.0")
    }
    
    func testCreateParser() {
        let parser = SwiftDateParser.createParser(
            dayfirst: true,
            yearfirst: false,
            fuzzy: true
        )
        
        XCTAssertNotNil(parser, "Should create a parser instance")
    }
    
    func testCreateExtractor() {
        let extractor = SwiftDateParser.createExtractor()
        XCTAssertNotNil(extractor, "Should create an extractor instance")
    }
    
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
        
        XCTAssertGreaterThan(dates.count, 2, "Should find multiple dates in the email")
    }
}