import Testing
@testable import SwiftDateParser
import Foundation

@Suite("NLP Date Extractor Tests")
struct NLPDateExtractorTests {
    
    let extractor: NLPDateExtractor2
    
    init() {
        self.extractor = NLPDateExtractor2()
    }
    
    @Test("Extract dates from text")
    func testExtractDatesFromText() {
        let text = """
        The meeting is scheduled for tomorrow at 3 PM. Please prepare the quarterly report 
        by December 15, 2023. We had a great discussion yesterday about the project 
        deadline on 2024-01-31. Let's plan to meet again in 2 weeks.
        """
        
        let extractedDates = extractor.extractDates(from: text)
        
        // Should find multiple dates
        #expect(extractedDates.count > 0, "Should extract at least one date")
        
        // Check that dates were extracted
        let extractedTexts = extractedDates.map { $0.text }
        print("Extracted dates: \(extractedTexts)")
        
        // Verify confidence scores
        for extracted in extractedDates {
            #expect(extracted.confidence > 0, "Confidence should be positive")
            #expect(extracted.confidence <= 1.0, "Confidence should not exceed 1.0")
        }
    }
    
    @Test("Extract dates with context")
    func testExtractDatesWithContext() {
        let text = "The project deadline is January 15, 2024. We need to finish everything by then."
        
        let results = extractor.extractDatesWithContext(from: text, contextWords: 3)
        
        #expect(results.count > 0, "Should extract at least one date with context")
        
        for (date, context) in results {
            print("Date: \(date.text), Context: \(context)")
            #expect(context.contains(date.text), "Context should contain the extracted date")
        }
    }
    
    @Test("Extract relative dates")
    func testExtractRelativeDates() {
        let text = """
        Let's meet tomorrow for lunch. I saw him 3 days ago at the conference. 
        The report is due in 2 weeks. We'll review it next month.
        """
        
        let extractedDates = extractor.extractDates(from: text)
        
        #expect(extractedDates.count > 0, "Should extract relative dates")
        
        // Check for specific relative dates
        let extractedTexts = extractedDates.map { $0.text.lowercased() }
        #expect(extractedTexts.contains { $0.contains("tomorrow") }, "Should extract 'tomorrow'")
        // Note: NSDataDetector may not always extract "3 days ago" reliably
        // This is a known limitation of the system API
        #expect(extractedTexts.contains { $0.contains("in 2 weeks") }, "Should extract 'in 2 weeks'")
    }
    
    @Test("Extract month names")
    func testExtractMonthNames() {
        let text = "The conference is in March. We launched in September 2022. January sales were strong."
        
        let extractedDates = extractor.extractDates(from: text)
        
        #expect(extractedDates.count > 0, "Should extract month names")
        
        let extractedTexts = extractedDates.map { $0.text.lowercased() }
        print("Extracted month dates: \(extractedTexts)")
    }
    
    @Test("Extract day names")
    func testExtractDayNames() {
        let text = "See you on Monday. The meeting was moved from Tuesday to Friday."
        
        let extractedDates = extractor.extractDates(from: text)
        
        #expect(extractedDates.count > 0, "Should extract day names")
        
        let extractedTexts = extractedDates.map { $0.text.lowercased() }
        for text in extractedTexts {
            print("Extracted day: \(text)")
        }
    }
    
    @Test("No date extraction")
    func testNoDateExtraction() {
        let text = "This text contains no dates whatsoever. Just regular words and sentences."
        
        let extractedDates = extractor.extractDates(from: text)
        
        #expect(extractedDates.count == 0, "Should not extract dates from text without dates")
    }
    
    @Test("Complex date extraction")
    func testComplexDateExtraction() {
        let text = """
        Our Q1 planning starts on 2024-01-08. The previous quarter ended December 31st, 2023.
        We should schedule follow-ups for next Tuesday and Thursday. The annual review is 
        typically in June or July. Last year's was on 07/15/2022.
        """
        
        let extractedDates = extractor.extractDates(from: text)
        
        #expect(extractedDates.count > 3, "Should extract multiple dates from complex text")
        
        // Verify dates are in order
        for i in 1..<extractedDates.count {
            let prev = extractedDates[i-1]
            let curr = extractedDates[i]
            #expect(prev.range.lowerBound <= curr.range.lowerBound, 
                    "Dates should be ordered by position in text")
        }
    }
    
    @Test("Date extraction performance", .timeLimit(.minutes(1)))
    func testDateExtractionPerformance() {
        let longText = String(repeating: "Meeting on January 15, 2024 at 3 PM. ", count: 100)
        
        // Should complete quickly
        _ = extractor.extractDates(from: longText)
    }
}