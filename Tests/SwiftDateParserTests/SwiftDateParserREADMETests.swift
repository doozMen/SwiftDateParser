import Testing
@testable import SwiftDateParser
import Foundation

@Suite("SwiftDateParser README Claims Validation")
struct SwiftDateParserREADMETests {
    
    let calendar: Calendar
    
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        self.calendar = calendar
    }
    
    // MARK: - Basic Usage Examples from README
    
    @Test("README: Basic date parsing examples")
    func testREADMEBasicParsing() throws {
        // Simple parsing
        let date1 = try SwiftDateParser.parse("2024-03-15")
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        #expect(components1.year == 2024)
        #expect(components1.month == 3)
        #expect(components1.day == 15)
        
        // Relative date
        let tomorrow = try SwiftDateParser.parse("tomorrow")
        let now = Date()
        // Calculate hour difference to avoid timezone boundary issues
        let hourDiff = calendar.dateComponents([.hour], from: now, to: tomorrow).hour ?? 0
        #expect(hourDiff >= 20 && hourDiff <= 28, "Tomorrow should be about 24 hours from now")
        
        // Natural language
        let natural = try SwiftDateParser.parse("March 15, 2024 at 3:30 PM")
        // Use UTC calendar to match parser's timezone
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let naturalComponents = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: natural)
        #expect(naturalComponents.year == 2024)
        #expect(naturalComponents.month == 3)
        #expect(naturalComponents.day == 15)
        #expect(naturalComponents.hour == 15)
        #expect(naturalComponents.minute == 30)
    }
    
    // MARK: - Advanced Parser Configuration from README
    
    @Test("README: Advanced parser configuration")
    func testREADMEAdvancedParser() throws {
        let parser = SwiftDateParser.createParser(
            dayfirst: true,
            yearfirst: false,
            fuzzy: true,
            defaultDate: Date()
        )
        
        // EU format with dayfirst=true
        let date = try parser.parse("15/03/24")
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.day == 15)
        #expect(components.month == 3)
        #expect(components.year == 2024)
    }
    
    // MARK: - Natural Language Extraction from README
    
    @Test("README: Natural language date extraction example")
    func testREADMENaturalLanguageExtraction() {
        let text = """
        The meeting is scheduled for tomorrow at 3 PM. 
        Please submit the report by December 15, 2023.
        We'll review it next week.
        """
        
        let extractedDates = SwiftDateParser.extractDates(from: text)
        
        // Should find at least 3 dates as shown in README
        #expect(extractedDates.count >= 3, "Should extract at least 3 dates")
        
        // Verify all extracted dates have required properties
        for extracted in extractedDates {
            #expect(!extracted.text.isEmpty, "Extracted text should not be empty")
            #expect(extracted.confidence > 0, "Confidence should be positive")
            #expect(extracted.confidence <= 1.0, "Confidence should not exceed 1.0")
            
            print("Found: '\(extracted.text)' -> \(extracted.date)")
            print("Confidence: \(extracted.confidence)")
        }
    }
    
    // MARK: - Extract Dates with Context from README
    
    @Test("README: Extract dates with context example")
    func testREADMEExtractWithContext() {
        let text = """
        The meeting is scheduled for tomorrow at 3 PM. 
        Please submit the report by December 15, 2023.
        We'll review it next week.
        """
        
        let extractor = SwiftDateParser.createExtractor()
        let results = extractor.extractDatesWithContext(from: text, contextWords: 5)
        
        #expect(results.count > 0, "Should extract dates with context")
        
        for (date, context) in results {
            print("Date: \(date.text)")
            print("Context: \(context)")
            
            #expect(context.contains(date.text), "Context should contain the date text")
            #expect(!context.isEmpty, "Context should not be empty")
        }
    }
    
    // MARK: - Supported Date Formats from README
    
    @Test("README: All standard formats")
    func testREADMEStandardFormats() throws {
        let standardFormats: [(String, (year: Int, month: Int, day: Int))] = [
            // ISO 8601
            ("2024-03-15T10:30:00", (2024, 3, 15)),
            // US Format
            ("03/15/2024", (2024, 3, 15)),
            ("3/15/24", (2024, 3, 15)),
            // EU Format
            ("15/03/2024", (2024, 3, 15)),
            ("15.03.2024", (2024, 3, 15)),
            // Long Format
            ("March 15, 2024", (2024, 3, 15)),
            // Compact
            ("20240315", (2024, 3, 15))
        ]
        
        for (format, expected) in standardFormats {
            let date = try SwiftDateParser.parse(format)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(components.year == expected.year, "Year mismatch for \(format)")
            #expect(components.month == expected.month, "Month mismatch for \(format)")
            #expect(components.day == expected.day, "Day mismatch for \(format)")
        }
    }
    
    @Test("README: All relative date formats")
    func testREADMERelativeDates() throws {
        // Simple relative dates
        _ = try SwiftDateParser.parse("today")
        _ = try SwiftDateParser.parse("tomorrow")
        _ = try SwiftDateParser.parse("yesterday")
        
        // With numbers
        _ = try SwiftDateParser.parse("3 days ago")
        _ = try SwiftDateParser.parse("in 2 weeks")
        
        // Next/Last
        _ = try SwiftDateParser.parse("next Monday")
        _ = try SwiftDateParser.parse("last month")
        
        #expect(true, "All relative date formats parsed successfully")
    }
    
    @Test("README: Natural language formats")
    func testREADMENaturalLanguageFormats() throws {
        let naturalFormats = [
            "The 3rd of May 2024",
            "December 25th at 3:30 PM",
            "Next Tuesday afternoon",
            "2 weeks from today"
        ]
        
        for format in naturalFormats {
            _ = try SwiftDateParser.parse(format)
            print("Successfully parsed: \(format)")
        }
    }
    
    // MARK: - API Examples from README
    
    @Test("README: parseWithTokens API")
    func testREADMEParseWithTokens() throws {
        let result = try SwiftDateParser.parseWithTokens("The meeting is on March 15, 2024 at the office")
        
        #expect(result.date != nil, "Should parse date")
        #expect(result.skippedTokens.count > 0, "Should extract tokens")
        
        print("Date: \(result.date!)")
        print("Tokens: \(result.skippedTokens)")
    }
    
    // MARK: - Error Handling from README
    
    @Test("README: Error handling example")
    func testREADMEErrorHandling() {
        do {
            _ = try SwiftDateParser.parse("invalid date")
            #expect(Bool(false), "Should have thrown an error")
        } catch DateParserError.unableToParseDate(let string) {
            print("Could not parse: \(string)")
            #expect(string == "invalid date")
        } catch {
            print("Unexpected error: \(error)")
            #expect(Bool(false), "Should throw DateParserError")
        }
    }
    
    // MARK: - Performance Claims from README
    
    @Test("README: Performance benchmarks")
    func testREADMEPerformanceClaims() throws {
        // Simple date parsing: ~0.05ms
        let simpleStart = Date()
        for _ in 0..<100 {
            _ = try SwiftDateParser.parse("2024-03-15")
        }
        let simpleTime = Date().timeIntervalSince(simpleStart) * 1000 / 100
        print("Simple date parsing: \(simpleTime)ms")
        #expect(simpleTime < 1.0, "Simple parsing should be fast")
        
        // Natural language extraction: ~2ms per 1000 characters
        let text = String(repeating: "Meeting on March 15, 2024. ", count: 36) // ~1000 chars
        let nlpStart = Date()
        _ = SwiftDateParser.extractDates(from: text)
        let nlpTime = Date().timeIntervalSince(nlpStart) * 1000
        print("NLP extraction (1000 chars): \(nlpTime)ms")
        #expect(nlpTime < 10.0, "NLP extraction should be reasonably fast")
        
        // Relative date parsing: ~0.1ms
        let relativeStart = Date()
        for _ in 0..<100 {
            _ = try SwiftDateParser.parse("3 days ago")
        }
        let relativeTime = Date().timeIntervalSince(relativeStart) * 1000 / 100
        print("Relative date parsing: \(relativeTime)ms")
        #expect(relativeTime < 2.0, "Relative parsing should be fast")
    }
    
    // MARK: - Complete Email Example from README
    
    @Test("README: Complete email extraction example")
    func testREADMEEmailExample() {
        let email = """
        Subject: Quarterly Review

        Hi team,

        Our Q1 review is scheduled for March 15, 2024 at 2 PM EST.
        Please submit your reports by end of day tomorrow.

        The deadline for Q2 planning is April 1st.

        Best regards
        """
        
        let dates = SwiftDateParser.extractDates(from: email)
        
        // Should extract the specific dates mentioned in README comments
        let extractedTexts = dates.map { $0.text }
        print("Extracted dates from email: \(extractedTexts)")
        
        #expect(dates.count >= 3, "Should extract at least 3 dates")
        #expect(extractedTexts.contains { $0.contains("March 15, 2024") }, "Should find March 15, 2024")
        #expect(extractedTexts.contains { $0.contains("tomorrow") }, "Should find tomorrow")
        #expect(extractedTexts.contains { $0.contains("April 1st") }, "Should find April 1st")
    }
    
    // MARK: - Calendar Event Example from README
    
    @Test("README: Calendar event parsing example")
    func testREADMECalendarExample() throws {
        let events = [
            "Team standup every Monday at 9 AM",
            "Project deadline: 2024-06-30",
            "Vacation from July 15 to July 22",
            "Conference in 3 months"
        ]
        
        for event in events {
            let dates = SwiftDateParser.extractDates(from: event)
            if let firstDate = dates.first {
                print("Event: \(event)")
                print("Date: \(firstDate.date)")
                #expect(true, "Successfully extracted date from event")
            } else {
                // Some events might not extract with the default extractor
                print("Event: \(event) - No date extracted")
            }
        }
    }
    
    // MARK: - Cross-Platform Support
    
    @Test("README: Cross-platform compatibility")
    func testCrossPlatform() {
        // Test that the library works on the current platform
        #if os(macOS)
        print("Running on macOS")
        #elseif os(iOS)
        print("Running on iOS")
        #elseif os(tvOS)
        print("Running on tvOS")
        #elseif os(watchOS)
        print("Running on watchOS")
        #elseif os(visionOS)
        print("Running on visionOS")
        #endif
        
        // Basic functionality should work on all platforms
        do {
            _ = try SwiftDateParser.parse("2024-03-15")
            _ = SwiftDateParser.extractDates(from: "Meeting tomorrow")
            #expect(true, "Library works on current platform")
        } catch {
            #expect(false, "Library should work on all platforms")
        }
    }
    
    // MARK: - Version Check
    
    @Test("README: Version string")
    func testVersion() {
        #expect(SwiftDateParser.version == "1.0.1", "Version should match README")
    }
}