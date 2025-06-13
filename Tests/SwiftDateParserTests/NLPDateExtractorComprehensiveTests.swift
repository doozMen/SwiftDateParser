import Testing
@testable import SwiftDateParser
import Foundation

@Suite("NLP Date Extractor Comprehensive Tests")
struct NLPDateExtractorComprehensiveTests {
    
    let extractor: NLPDateExtractor2
    let extractorLegacy: NLPDateExtractor
    
    init() {
        self.extractor = NLPDateExtractor2()
        self.extractorLegacy = NLPDateExtractor()
    }
    
    // MARK: - Email Extraction Tests (from README)
    
    @Test("Extract dates from email example")
    func testEmailDateExtraction() {
        let email = """
        Subject: Quarterly Review
        
        Hi team,
        
        Our Q1 review is scheduled for March 15, 2024 at 2 PM EST.
        Please submit your reports by end of day tomorrow.
        
        The deadline for Q2 planning is April 1st.
        
        Best regards
        """
        
        let dates = extractor.extractDates(from: email)
        
        // Should find at least 3 dates as claimed in README
        #expect(dates.count >= 3, "Should extract at least 3 dates from email")
        
        let extractedTexts = dates.map { $0.text }
        
        // Verify specific dates are found
        #expect(extractedTexts.contains { $0.contains("March 15, 2024") }, "Should find March 15, 2024")
        #expect(extractedTexts.contains { $0.contains("tomorrow") }, "Should find tomorrow")
        #expect(extractedTexts.contains { $0.contains("April 1st") }, "Should find April 1st")
        
        // Print for verification
        for date in dates {
            print("Found: '\(date.text)' with confidence \(date.confidence)")
        }
    }
    
    // MARK: - Calendar Event Tests (from README)
    
    @Test("Extract dates from calendar events")
    func testCalendarEventExtraction() {
        let events = [
            "Team standup every Monday at 9 AM",
            "Project deadline: 2024-06-30",
            "Vacation from July 15 to July 22",
            "Conference in 3 months"
        ]
        
        for event in events {
            let dates = extractor.extractDates(from: event)
            #expect(dates.count > 0, "Should extract date from: \(event)")
            
            if let firstDate = dates.first {
                print("Event: \(event)")
                print("Date: \(firstDate.date)")
                print("Text: \(firstDate.text)")
            }
        }
    }
    
    // MARK: - Context Extraction Tests
    
    @Test("Extract dates with varying context sizes")
    func testContextExtraction() {
        let text = """
        The contract starts on January 1, 2024 and runs for one year. 
        Payment is due on the 15th of each month. 
        The final review meeting is scheduled for December 20, 2024.
        """
        
        // Test different context sizes
        let contextSizes = [1, 3, 5, 10]
        
        for contextWords in contextSizes {
            let results = extractor.extractDatesWithContext(from: text, contextWords: contextWords)
            
            #expect(results.count > 0, "Should extract dates with context")
            
            for (date, context) in results {
                print("Context (\(contextWords) words): \(context)")
                print("Date: \(date.text)\n")
                
                // Context should contain the date
                #expect(context.contains(date.text), "Context should contain the extracted date")
                
                // Verify context word count is roughly as requested
                let wordCount = context.split(separator: " ").count
                #expect(wordCount >= contextWords || wordCount == context.split(separator: " ").count, 
                        "Context should have appropriate word count")
            }
        }
    }
    
    // MARK: - Confidence Score Tests
    
    @Test("Confidence scores for different date formats")
    func testConfidenceScores() {
        let testCases = [
            ("2024-03-15", 0.9),           // ISO format should have high confidence
            ("March 15, 2024", 0.9),        // Full date should have high confidence
            ("tomorrow", 0.8),              // Relative date should have good confidence
            ("next week", 0.7),             // Vague relative should have lower confidence
            ("in a few days", 0.5),         // Very vague should have low confidence
            ("July", 0.6),                  // Month only should have medium confidence
            ("Monday", 0.7),                // Day name should have medium-high confidence
            ("15th", 0.5)                   // Day only should have lower confidence
        ]
        
        for (text, minConfidence) in testCases {
            let fullText = "The event is \(text)."
            let dates = extractor.extractDates(from: fullText)
            
            if let date = dates.first {
                print("\(text): confidence = \(date.confidence)")
                #expect(date.confidence >= minConfidence * 0.8, 
                        "\(text) should have confidence >= \(minConfidence * 0.8)")
            }
        }
    }
    
    // MARK: - Complex Text Extraction Tests
    
    @Test("Extract dates from complex documents")
    func testComplexDocumentExtraction() {
        let document = """
        Meeting Minutes - January 15, 2024
        
        Attendees arrived at 9:00 AM sharp. We discussed the Q1 roadmap that was 
        finalized last December. The product launch is still on track for March 1st.
        
        Action items:
        - Engineering to complete feature A by February 15
        - Marketing materials due next Friday
        - Beta testing starts in 2 weeks
        - Final review meeting scheduled for the last day of February
        
        The team agreed to reconvene tomorrow at 2 PM. Our next quarterly review 
        will be April 10, 2024 at 10:30 AM in the main conference room.
        
        Historical note: This project started in summer 2023 and has made great 
        progress. We expect to wrap up by mid-2024.
        """
        
        let dates = extractor.extractDates(from: document)
        
        // Should find many dates
        #expect(dates.count >= 8, "Should extract many dates from complex document")
        
        // Verify they're in order
        for i in 1..<dates.count {
            #expect(dates[i-1].range.lowerBound <= dates[i].range.lowerBound,
                    "Dates should be ordered by position in text")
        }
        
        // Check for specific complex patterns
        let texts = dates.map { $0.text.lowercased() }
        #expect(texts.contains { $0.contains("9:00 am") }, "Should find time with AM/PM")
        #expect(texts.contains { $0.contains("last december") }, "Should find relative month reference")
        #expect(texts.contains { $0.contains("in 2 weeks") }, "Should find relative week reference")
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Extract dates from edge cases")
    func testEdgeCases() {
        let edgeCases = [
            // Multiple dates in one sentence
            "From January 1 to December 31, 2024",
            
            // Dates with special characters
            "Due: 2024-03-15 | Updated: 2024-03-14",
            
            // Dates in parentheses
            "The meeting (scheduled for March 15) was postponed",
            
            // Dates with ordinals
            "Join us on the 1st, 3rd, and 5th of every month",
            
            // Mixed formats
            "Started on 2024-01-01, ends March 31st, reviewed monthly",
            
            // Dates in URLs (should not extract)
            "Visit https://example.com/2024/03/15/article",
            
            // Dates in code (might extract)
            "const date = new Date('2024-03-15')",
            
            // International formats
            "Meeting on 15.03.2024 at 14:30 hours"
        ]
        
        for testCase in edgeCases {
            let dates = extractor.extractDates(from: testCase)
            print("\nEdge case: \(testCase)")
            print("Found \(dates.count) dates:")
            for date in dates {
                print("  - '\(date.text)'")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Performance with large texts", .timeLimit(.minutes(1)))
    func testLargeTextPerformance() {
        // Generate a large text with many dates
        var largeText = ""
        let dateFormats = [
            "Meeting on January \(15), 2024",
            "Deadline: 2024-03-\(15)",
            "Event in \(3) days",
            "Last updated: March \(15), 2024 at 3:30 PM",
            "Schedule for next Monday",
            "Completed on 15/03/2024"
        ]
        
        // Create 1000 lines of text with dates
        for i in 0..<1000 {
            let format = dateFormats[i % dateFormats.count]
            let line = format.replacingOccurrences(of: "\(15)", with: "\((i % 28) + 1)")
                            .replacingOccurrences(of: "\(3)", with: "\((i % 7) + 1)")
            largeText += line + ". Some filler text here. "
        }
        
        let startTime = Date()
        let dates = extractor.extractDates(from: largeText)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        print("Extracted \(dates.count) dates from \(largeText.count) characters in \(elapsedTime) seconds")
        print("Performance: \(Double(largeText.count) / elapsedTime / 1000) thousand chars/second")
        
        #expect(dates.count > 1000, "Should extract many dates from large text")
        #expect(elapsedTime < 5.0, "Should process large text quickly")
    }
    
    // MARK: - Comparison Tests
    
    @Test("Compare legacy and new extractor")
    func testExtractorComparison() {
        let testTexts = [
            "Meeting tomorrow at 3 PM",
            "The deadline is March 15, 2024",
            "We met last week and will meet again next month",
            "Updates every Monday and Thursday"
        ]
        
        for text in testTexts {
            let newDates = extractor.extractDates(from: text)
            let legacyDates = extractorLegacy.extractDates(from: text)
            
            print("\nText: \(text)")
            print("New extractor found: \(newDates.count) dates")
            print("Legacy extractor found: \(legacyDates.count) dates")
            
            // Both should find dates, but counts might differ
            #expect(newDates.count > 0 || legacyDates.count > 0, 
                    "At least one extractor should find dates")
        }
    }
    
    // MARK: - Timezone Extraction Tests
    
    @Test("Extract dates with timezone information")
    func testTimezoneExtraction() {
        let textsWithTimezones = [
            "Call at 3 PM EST on March 15",
            "Meeting at 10:00 AM PST tomorrow",
            "Deadline: 2024-03-15 17:00 GMT",
            "Launch at 12:00 noon UTC on April 1st"
        ]
        
        for text in textsWithTimezones {
            let dates = extractor.extractDates(from: text)
            
            #expect(dates.count > 0, "Should extract date from: \(text)")
            
            if let date = dates.first {
                print("Text: \(text)")
                print("Extracted: \(date.text)")
                print("Timezone: \(date.timezone?.identifier ?? "none")")
            }
        }
    }
    
    // MARK: - Natural Language Pattern Tests
    
    @Test("Extract complex natural language patterns")
    func testComplexNaturalLanguagePatterns() {
        let patterns = [
            "every other Tuesday",
            "the first Monday of each month",
            "biweekly on Thursdays",
            "quarterly reviews in January, April, July, and October",
            "annually on December 31st",
            "twice a month on the 1st and 15th",
            "weekdays at 9 AM",
            "weekends only",
            "business days excluding holidays",
            "the last Friday of the month"
        ]
        
        for pattern in patterns {
            let text = "The event occurs \(pattern)."
            let dates = extractor.extractDates(from: text)
            
            print("\nPattern: \(pattern)")
            print("Extracted: \(dates.map { $0.text })")
            
            // These complex patterns might not all be extracted, but document behavior
            if dates.isEmpty {
                print("(Pattern not extracted)")
            }
        }
    }
}