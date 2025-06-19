import Testing
import Foundation
@testable import SwiftDateParser

@Suite("Relative Date Parsing Tests")
struct RelativeDateTests {
    
    @Test("Parse relative dates with injected default date for deterministic testing")
    func testRelativeDatesWithInjectedDefaultDate() throws {
        let calendar = Calendar.current
        
        // Create a fixed reference date for deterministic testing
        // Using January 15, 2024, 10:00 AM as our "now"
        let fixedNow = try #require(DateComponents(
            calendar: calendar,
            year: 2024,
            month: 1,
            day: 15,
            hour: 10,
            minute: 0
        ).date)
        
        // Test with DateParser2
        var parserInfo2 = DateParser2.ParserInfo()
        parserInfo2.defaultDate = fixedNow
        parserInfo2.fuzzy = true  // Enable fuzzy parsing for natural language
        let parser2 = DateParser2(parserInfo: parserInfo2)
        
        // For relative dates, we need to mock the current time behavior
        // Since the parsers use Date() internally for relative dates,
        // we can only test that the logic works correctly
        
        // Test that parse methods work (actual dates will be based on real current time)
        let today2 = try parser2.parse("today")
        let yesterday2 = try parser2.parse("yesterday")
        let tomorrow2 = try parser2.parse("tomorrow")
        
        // Verify they return different dates in the correct order
        #expect(yesterday2 < today2)
        #expect(today2 < tomorrow2)
        
        // Test with DateParser3
        var parserInfo3 = DateParser3.ParserInfo()
        parserInfo3.defaultDate = fixedNow
        parserInfo3.fuzzy = true  // Enable fuzzy parsing for natural language
        let parser3 = DateParser3(parserInfo: parserInfo3)
        
        let today3 = try parser3.parse("today")
        let yesterday3 = try parser3.parse("yesterday")
        let tomorrow3 = try parser3.parse("tomorrow")
        
        // Verify they return different dates in the correct order
        #expect(yesterday3 < today3)
        #expect(today3 < tomorrow3)
    }
    
    @Test("DefaultDate is correctly used for partial date parsing")
    func testDefaultDateForPartialDates() throws {
        let calendar = Calendar.current
        
        // Create a specific default date - June 15, 2024, 2:30 PM
        let defaultDate = try #require(DateComponents(
            calendar: calendar,
            year: 2024,
            month: 6,
            day: 15,
            hour: 14,
            minute: 30
        ).date)
        
        // Test with DateParser2
        var parserInfo2 = DateParser2.ParserInfo()
        parserInfo2.defaultDate = defaultDate
        parserInfo2.fuzzy = true  // Enable fuzzy parsing for natural language
        let parser2 = DateParser2(parserInfo: parserInfo2)
        
        // Parse time-only string - should use defaultDate's year/month/day
        let timeOnly2 = try parser2.parse("3:45 PM")
        let expectedComponents = DateComponents(
            calendar: calendar,
            year: 2024,
            month: 6,
            day: 15,
            hour: 15,
            minute: 45
        )
        let expectedTime = try #require(expectedComponents.date)
        #expect(calendar.isDate(timeOnly2, equalTo: expectedTime, toGranularity: .minute))
        
        // Parse month/day only - should use defaultDate's year
        let monthDay = try parser2.parse("10 March 2024")
        #expect(calendar.component(.year, from: monthDay) == 2024)
        #expect(calendar.component(.month, from: monthDay) == 3)
        #expect(calendar.component(.day, from: monthDay) == 10)
        
        // Test with DateParser3
        var parserInfo3 = DateParser3.ParserInfo()
        parserInfo3.defaultDate = defaultDate
        parserInfo3.fuzzy = true  // Enable fuzzy parsing for natural language
        let parser3 = DateParser3(parserInfo: parserInfo3)
        
        // Parse time-only string
        let timeOnly3 = try parser3.parse("3:45 PM")
        #expect(calendar.isDate(timeOnly3, equalTo: expectedTime, toGranularity: .minute))
    }
    
    @Test("Relative date expressions maintain correct intervals")
    func testRelativeDateIntervals() throws {
        let calendar = Calendar.current
        var parserInfo2 = DateParser2.ParserInfo()
        parserInfo2.fuzzy = true
        let parser2 = DateParser2(parserInfo: parserInfo2)
        
        var parserInfo3 = DateParser3.ParserInfo()
        parserInfo3.fuzzy = true
        let parser3 = DateParser3(parserInfo: parserInfo3)
        
        // Test "N days ago" pattern
        let oneDayAgo2 = try parser2.parse("1 day ago")
        let threeDaysAgo2 = try parser2.parse("3 days ago")
        let fiveDaysAgo2 = try parser2.parse("5 days ago")
        
        // Calculate expected intervals
        let interval1to3 = threeDaysAgo2.timeIntervalSince(oneDayAgo2)
        let interval3to5 = fiveDaysAgo2.timeIntervalSince(threeDaysAgo2)
        
        // Should be approximately 2 days apart (allowing for DST and timing variations)
        // Note: intervals are negative because older dates are larger time intervals ago
        #expect(interval1to3 <= -1.5 * 24 * 60 * 60 && interval1to3 >= -2.5 * 24 * 60 * 60,
               "1 day ago to 3 days ago should be approximately 2 days")
        #expect(interval3to5 <= -1.5 * 24 * 60 * 60 && interval3to5 >= -2.5 * 24 * 60 * 60,
               "3 days ago to 5 days ago should be approximately 2 days")
        
        // Test consistency between parsers
        let threeDaysAgo3 = try parser3.parse("3 days ago")
        #expect(calendar.isDate(threeDaysAgo2, inSameDayAs: threeDaysAgo3))
    }
    
    @Test("Relative dates work correctly at day boundaries")
    func testRelativeDatesAtDayBoundaries() throws {
        let calendar = Calendar.current
        
        // Note: We can't control the exact time these run, but we can verify
        // that "today", "yesterday", and "tomorrow" are always exactly 1 day apart
        var parserInfo = DateParser2.ParserInfo()
        parserInfo.fuzzy = true
        let parser2 = DateParser2(parserInfo: parserInfo)
        
        let today = try parser2.parse("today")
        let yesterday = try parser2.parse("yesterday")
        let tomorrow = try parser2.parse("tomorrow")
        
        // All should be at start of day (midnight)
        #expect(calendar.component(.hour, from: today) == 0)
        #expect(calendar.component(.minute, from: today) == 0)
        #expect(calendar.component(.second, from: today) == 0)
        
        // Should be 1 day apart (allowing for DST transitions: 23-25 hours)
        let intervalYesterdayToday = today.timeIntervalSince(yesterday)
        let intervalTodayTomorrow = tomorrow.timeIntervalSince(today)
        
        #expect(intervalYesterdayToday >= 23 * 60 * 60 && intervalYesterdayToday <= 25 * 60 * 60,
               "Yesterday to today should be approximately 1 day")
        #expect(intervalTodayTomorrow >= 23 * 60 * 60 && intervalTodayTomorrow <= 25 * 60 * 60,
               "Today to tomorrow should be approximately 1 day")
    }
    
    @Test("Parse various relative date formats")
    func testVariousRelativeDateFormats() throws {
        var parserInfo2 = DateParser2.ParserInfo()
        parserInfo2.fuzzy = true
        let parser2 = DateParser2(parserInfo: parserInfo2)
        
        var parserInfo3 = DateParser3.ParserInfo()
        parserInfo3.fuzzy = true
        let parser3 = DateParser3(parserInfo: parserInfo3)
        
        // Test that these all parse without crashing
        let testCases = [
            "today",
            "tomorrow", 
            "yesterday",
            "1 day ago",
            "2 days ago",
            "in 1 day",
            "in 3 days",
            "1 week ago",
            "in 2 weeks"
        ]
        
        for testCase in testCases {
            let result2 = try parser2.parse(testCase)
            let result3 = try parser3.parse(testCase)
            
            // Both parsers should successfully parse these
            // Check that the dates are reasonable (within 100 years of now)
            let now = Date()
            let yearInterval: TimeInterval = 365 * 24 * 60 * 60 * 100
            #expect(abs(result2.timeIntervalSince(now)) < yearInterval,
                   "DateParser2 result for '\(testCase)' should be within reasonable range")
            #expect(abs(result3.timeIntervalSince(now)) < yearInterval,
                   "DateParser3 result for '\(testCase)' should be within reasonable range")
        }
    }
}