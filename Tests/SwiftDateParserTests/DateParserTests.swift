import Testing
@testable import SwiftDateParser
import Foundation

@Suite("Date Parser Tests")
struct DateParserTests {
    
    let parser: DateParser
    let calendar: Calendar
    
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let locale = Locale(identifier: "en_US_POSIX")
        self.calendar = calendar
        self.parser = DateParser(calendar: calendar, locale: locale)
    }
    
    // MARK: - ISO Format Tests
    
    @Test("Parse ISO date formats")
    func testISOFormats() throws {
        let testCases: [(String, (year: Int, month: Int, day: Int, hour: Int?, minute: Int?, second: Int?))] = [
            ("2003-09-25T10:49:41", (2003, 9, 25, 10, 49, 41)),
            ("2003-09-25T10:49", (2003, 9, 25, 10, 49, nil)),
            ("2003-09-25T10", (2003, 9, 25, 10, nil, nil)),
            ("2003-09-25", (2003, 9, 25, nil, nil, nil)),
            ("20030925T104941", (2003, 9, 25, 10, 49, 41)),
            ("20030925T1049", (2003, 9, 25, 10, 49, nil)),
            ("20030925T10", (2003, 9, 25, 10, nil, nil)),
            ("20030925", (2003, 9, 25, nil, nil, nil))
        ]
        
        for (dateString, expected) in testCases {
            let date = try parser.parse(dateString)
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            
            #expect(components.year == expected.year, "Year mismatch for \(dateString)")
            #expect(components.month == expected.month, "Month mismatch for \(dateString)")
            #expect(components.day == expected.day, "Day mismatch for \(dateString)")
            
            if let expectedHour = expected.hour {
                #expect(components.hour == expectedHour, "Hour mismatch for \(dateString)")
            }
            if let expectedMinute = expected.minute {
                #expect(components.minute == expectedMinute, "Minute mismatch for \(dateString)")
            }
            if let expectedSecond = expected.second {
                #expect(components.second == expectedSecond, "Second mismatch for \(dateString)")
            }
        }
    }
    
    // MARK: - Common Format Tests
    
    @Test("Parse common date formats")
    func testCommonDateFormats() throws {
        let testCases: [(String, (year: Int, month: Int, day: Int))] = [
            ("09-25-2003", (2003, 9, 25)),
            ("25-09-2003", (2003, 9, 25)),
            ("10-09-2003", (2003, 10, 9)),
            ("10-09-03", (2003, 10, 9)),
            ("2003.09.25", (2003, 9, 25)),
            ("09.25.2003", (2003, 9, 25)),
            ("25.09.2003", (2003, 9, 25)),
            ("10.09.2003", (2003, 10, 9)),
            ("10.09.03", (2003, 10, 9)),
            ("2003/09/25", (2003, 9, 25)),
            ("09/25/2003", (2003, 9, 25)),
            ("25/09/2003", (2003, 9, 25)),
            ("10/09/2003", (2003, 10, 9)),
            ("10/09/03", (2003, 10, 9))
        ]
        
        for (dateString, expected) in testCases {
            let date = try parser.parse(dateString)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            
            #expect(components.year == expected.year, "Year mismatch for \(dateString)")
            #expect(components.month == expected.month, "Month mismatch for \(dateString)")
            #expect(components.day == expected.day, "Day mismatch for \(dateString)")
        }
    }
    
    // MARK: - Natural Language Tests
    
    @Test("Parse natural language dates")
    func testNaturalLanguageDates() throws {
        // Create a fuzzy parser
        let fuzzyParser = DateParser(
            parserInfo: DateParser.ParserInfo(fuzzy: true),
            calendar: calendar
        )
        
        // Test month names
        let monthTests = [
            "July 4, 1976",
            "4 Jul 1976",
            "January 1, 2000",
            "Dec 31, 1999"
        ]
        
        for dateString in monthTests {
            #expect(throws: Never.self) {
                _ = try fuzzyParser.parse(dateString)
            }
        }
    }
    
    // MARK: - Relative Date Tests
    
    @Test("Parse relative dates")
    func testRelativeDates() throws {
        let fuzzyParser = DateParser(
            parserInfo: DateParser.ParserInfo(fuzzy: true),
            calendar: calendar
        )
        
        // Test relative dates
        let relativeTests = [
            "today",
            "tomorrow",
            "yesterday"
        ]
        
        for dateString in relativeTests {
            let date = try fuzzyParser.parse(dateString)
            #expect(date != nil, "Failed to parse relative date: \(dateString)")
        }
    }
    
    // MARK: - Relative Dates with Numbers
    
    @Test("Parse relative dates with numbers")
    func testRelativeDatesWithNumbers() throws {
        let fuzzyParser = DateParser(
            parserInfo: DateParser.ParserInfo(fuzzy: true),
            calendar: calendar
        )
        
        // Test "X days ago" format
        let daysAgoDate = try fuzzyParser.parse("3 days ago")
        let expectedDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let daysDifference = calendar.dateComponents([.day], from: daysAgoDate, to: expectedDaysAgo).day ?? 0
        #expect(abs(daysDifference) <= 1, "3 days ago parsing is off by more than 1 day")
        
        // Test "in X weeks" format
        let weeksFromNowDate = try fuzzyParser.parse("in 2 weeks")
        let expectedWeeksFromNow = calendar.date(byAdding: .weekOfYear, value: 2, to: Date())!
        let weeksDifference = calendar.dateComponents([.day], from: weeksFromNowDate, to: expectedWeeksFromNow).day ?? 0
        #expect(abs(weeksDifference) <= 1, "in 2 weeks parsing is off by more than 1 day")
    }
    
    // MARK: - Time Format Tests
    
    @Test("Parse time formats")
    func testTimeFormats() throws {
        let testCases: [(String, (hour: Int, minute: Int, second: Int?))] = [
            ("10:36:28", (10, 36, 28)),
            ("10:36", (10, 36, nil)),
            ("10:36 AM", (10, 36, nil)),
            ("10:36 PM", (22, 36, nil)),
            ("10:36:28 PM", (22, 36, 28))
        ]
        
        // Use a parser with a fixed default date
        let defaultDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let timeParser = DateParser(
            parserInfo: DateParser.ParserInfo(defaultDate: defaultDate),
            calendar: calendar
        )
        
        for (timeString, expected) in testCases {
            let date = try timeParser.parse(timeString)
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            
            #expect(components.hour == expected.hour, "Hour mismatch for \(timeString)")
            #expect(components.minute == expected.minute, "Minute mismatch for \(timeString)")
            
            if let expectedSecond = expected.second {
                #expect(components.second == expectedSecond, "Second mismatch for \(timeString)")
            }
        }
    }
    
    // MARK: - Error Tests
    
    @Test("Handle invalid date strings")
    func testInvalidDateStrings() {
        let invalidDates = [
            "not a date",
            "12345",
            "!@#$%",
            ""
        ]
        
        for invalidDate in invalidDates {
            #expect(throws: DateParserError.self) {
                _ = try parser.parse(invalidDate)
            }
        }
    }
    
    // MARK: - Custom Format Tests
    
    @Test("Parse custom date formats")
    func testCustomFormats() throws {
        let fuzzyParser = DateParser(
            parserInfo: DateParser.ParserInfo(fuzzy: true),
            calendar: calendar
        )
        
        let customFormats = [
            ("Thu Sep 25 10:36:28 2003", (2003, 9, 25)),
            ("Mon Jan 2 04:24:27 1995", (1995, 1, 2)),
            ("3rd of May 2001", (2001, 5, 3)),
            ("5th of March 2001", (2001, 3, 5)),
            ("1st of May 2003", (2003, 5, 1))
        ]
        
        for (dateString, expected) in customFormats {
            let date = try fuzzyParser.parse(dateString)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            
            #expect(components.year == expected.0, "Year mismatch for \(dateString)")
            #expect(components.month == expected.1, "Month mismatch for \(dateString)")
            #expect(components.day == expected.2, "Day mismatch for \(dateString)")
        }
    }
}