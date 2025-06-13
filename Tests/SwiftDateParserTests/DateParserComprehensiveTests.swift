import Testing
@testable import SwiftDateParser
import Foundation

@Suite("DateParser Comprehensive Tests")
struct DateParserComprehensiveTests {
    
    let calendar: Calendar
    let locale: Locale
    
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        self.locale = Locale(identifier: "en_US_POSIX")
    }
    
    // MARK: - Apostrophe Year Tests
    
    @Test("Parse apostrophe years")
    func testApostropheYears() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let testCases: [(String, Int)] = [
            ("'96", 1996),
            ("'00", 2000),
            ("'01", 2001),
            ("'49", 2049),
            ("'50", 1950),
            ("'99", 1999),
            ("December '95", 1995),
            ("March 15, '87", 1987)
        ]
        
        for (dateString, expectedYear) in testCases {
            let date = try parser.parse(dateString)
            let components = calendar.dateComponents([.year], from: date)
            #expect(components.year == expectedYear, "Year mismatch for \(dateString)")
        }
    }
    
    // MARK: - AD/BC Date Tests
    
    @Test("Parse AD/BC dates")
    func testADBCDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let testCases: [(String, (year: Int, era: Int))] = [
            ("100 AD", (100, 1)),
            ("100 A.D.", (100, 1)),
            ("500 BC", (-499, 0)),  // BC years are offset by 1
            ("500 B.C.", (-499, 0)),
            ("1 AD", (1, 1)),
            ("1 BC", (0, 0)),  // Year 1 BC = year 0
            ("July 4, 776 BC", (-775, 0)),
            ("March 15, 44 BC", (-43, 0))
        ]
        
        for (dateString, expected) in testCases {
            let date = try parser.parse(dateString)
            let components = calendar.dateComponents([.year, .era], from: date)
            #expect(components.year == expected.year, "Year mismatch for \(dateString)")
            #expect(components.era == expected.era, "Era mismatch for \(dateString)")
        }
    }
    
    // MARK: - Ordinal Date Tests
    
    @Test("Parse ordinal dates")
    func testOrdinalDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let testCases: [(String, (month: Int, day: Int))] = [
            ("1st of January", (1, 1)),
            ("2nd of February", (2, 2)),
            ("3rd of March", (3, 3)),
            ("4th of April", (4, 4)),
            ("21st of December", (12, 21)),
            ("22nd of November", (11, 22)),
            ("23rd of October", (10, 23)),
            ("31st of July", (7, 31)),
            ("March 1st", (3, 1)),
            ("April 2nd", (4, 2)),
            ("May 3rd", (5, 3)),
            ("June 4th", (6, 4)),
            ("December 25th", (12, 25))
        ]
        
        for (dateString, expected) in testCases {
            let date = try parser.parse(dateString)
            let components = calendar.dateComponents([.month, .day], from: date)
            #expect(components.month == expected.month, "Month mismatch for \(dateString)")
            #expect(components.day == expected.day, "Day mismatch for \(dateString)")
        }
    }
    
    // MARK: - Logger Format Tests
    
    @Test("Parse logger format with comma milliseconds")
    func testLoggerFormat() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(),
            calendar: calendar,
            locale: locale
        )
        
        let testCases = [
            "2003-09-25 10:49:41,502",
            "2023-12-31 23:59:59,999",
            "2024-01-01 00:00:00,001",
            "2024-06-15 14:30:45,123"
        ]
        
        for dateString in testCases {
            let date = try parser.parse(dateString)
            // Verify parsing succeeds
            #expect(true, "Successfully parsed logger format: \(dateString)")
            
            // Extract components to verify correct parsing
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            
            // Extract expected values from string
            let parts = dateString.split(separator: " ")
            let datePart = parts[0].split(separator: "-")
            let timePart = parts[1].split(separator: ",")[0].split(separator: ":")
            
            #expect(components.year == Int(datePart[0]))
            #expect(components.month == Int(datePart[1]))
            #expect(components.day == Int(datePart[2]))
            #expect(components.hour == Int(timePart[0]))
            #expect(components.minute == Int(timePart[1]))
            #expect(components.second == Int(timePart[2]))
        }
    }
    
    // MARK: - Single Number Parsing Tests
    
    @Test("Parse single numbers as years or days")
    func testSingleNumberParsing() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(),
            calendar: calendar,
            locale: locale
        )
        
        // Years (4 digits)
        let yearTests: [(String, Int)] = [
            ("2024", 2024),
            ("1999", 1999),
            ("2000", 2000),
            ("1776", 1776)
        ]
        
        for (yearString, expectedYear) in yearTests {
            let date = try parser.parse(yearString)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(components.year == expectedYear, "Year mismatch for \(yearString)")
            #expect(components.month == 1, "Month should be 1 for year-only parsing")
            #expect(components.day == 1, "Day should be 1 for year-only parsing")
        }
        
        // Days (1-2 digits) - should use current month/year
        let dayTests = ["1", "15", "31", "7", "28"]
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        
        for dayString in dayTests {
            let date = try parser.parse(dayString)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(components.year == currentComponents.year, "Year should match current year")
            #expect(components.month == currentComponents.month, "Month should match current month")
            #expect(components.day == Int(dayString), "Day mismatch for \(dayString)")
        }
    }
    
    // MARK: - Fuzzy Parsing with Token Extraction
    
    @Test("Fuzzy parsing with token extraction")
    func testFuzzyWithTokens() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true, fuzzyWithTokens: true),
            calendar: calendar,
            locale: locale
        )
        
        let testCases = [
            ("The meeting is on March 15, 2024 at the office", "March 15, 2024"),
            ("Email sent yesterday regarding the proposal", "yesterday"),
            ("Please respond by tomorrow morning", "tomorrow"),
            ("I saw him 3 days ago at the conference", "3 days ago")
        ]
        
        for (input, expectedDate) in testCases {
            let result = try parser.parseWithTokens(input)
            #expect(result.date != nil, "Should parse date from: \(input)")
            
            // Tokens should contain the non-date parts
            #expect(result.skippedTokens.count > 0, "Should extract tokens from fuzzy parsing")
            
            // The tokens joined should not contain the date part
            let joinedTokens = result.skippedTokens.joined(separator: " ")
            #expect(!joinedTokens.contains(expectedDate), "Tokens should not contain the parsed date")
        }
    }
    
    // MARK: - Timezone Tests
    
    @Test("Parse dates with timezones")
    func testTimezones() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(ignoretz: false),
            calendar: calendar,
            locale: locale
        )
        
        let testCases = [
            "2024-03-15T10:30:00Z",
            "2024-03-15T10:30:00+00:00",
            "2024-03-15T10:30:00-05:00",
            "2024-03-15T10:30:00+01:00",
            "2024-03-15 10:30:00 EST",
            "2024-03-15 10:30:00 PST",
            "2024-03-15 10:30:00 GMT"
        ]
        
        for dateString in testCases {
            // Should parse without throwing
            let date = try parser.parse(dateString)
            #expect(true, "Successfully parsed timezone format: \(dateString)")
        }
    }
    
    // MARK: - Date Validation Tests
    
    @Test("Date validation")
    func testDateValidation() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(validateDates: true),
            calendar: calendar,
            locale: locale
        )
        
        // Invalid dates that should throw
        let invalidDates = [
            "2024-02-30",  // February doesn't have 30 days
            "2024-04-31",  // April has only 30 days
            "2024-13-01",  // Invalid month
            "2024-00-15",  // Invalid month
            "2024-01-32",  // Invalid day
            "2024-01-00"   // Invalid day
        ]
        
        for invalidDate in invalidDates {
            #expect(throws: DateParserError.self) {
                _ = try parser.parse(invalidDate)
            }
        }
        
        // Valid leap year date
        let leapYearDate = try parser.parse("2024-02-29")
        #expect(true, "Should parse valid leap year date")
        
        // Invalid leap year date
        #expect(throws: DateParserError.self) {
            _ = try parser.parse("2023-02-29")  // 2023 is not a leap year
        }
    }
    
    // MARK: - Default Date Tests
    
    @Test("Default date for missing components")
    func testDefaultDate() throws {
        let defaultDate = calendar.date(from: DateComponents(year: 2020, month: 6, day: 15))!
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(defaultDate: defaultDate),
            calendar: calendar,
            locale: locale
        )
        
        // Parse time only - should use default date
        let timeOnly = try parser.parse("15:30:00")
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: timeOnly)
        #expect(components.year == 2020)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 15)
        #expect(components.minute == 30)
        
        // Parse month/day only - should use default year
        let monthDay = try parser.parse("March 25")
        let mdComponents = calendar.dateComponents([.year, .month, .day], from: monthDay)
        #expect(mdComponents.year == 2020)
        #expect(mdComponents.month == 3)
        #expect(mdComponents.day == 25)
    }
    
    // MARK: - Complex Relative Date Tests
    
    @Test("Complex relative date parsing")
    func testComplexRelativeDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let testCases = [
            "next week",
            "last month",
            "next year",
            "last year",
            "next Monday",
            "last Friday",
            "next January",
            "last December",
            "5 months ago",
            "in 3 years",
            "2 hours ago",
            "in 45 minutes"
        ]
        
        for dateString in testCases {
            let date = try parser.parse(dateString)
            #expect(true, "Successfully parsed relative date: \(dateString)")
        }
    }
    
    // MARK: - Dayfirst and Yearfirst Tests
    
    @Test("Dayfirst and yearfirst configurations")
    func testDayFirstYearFirst() throws {
        // Test dayfirst
        let dayfirstParser = DateParser2(
            parserInfo: DateParser2.ParserInfo(dayfirst: true, yearfirst: false),
            calendar: calendar,
            locale: locale
        )
        
        let date1 = try dayfirstParser.parse("01/02/03")
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        #expect(components1.day == 1)
        #expect(components1.month == 2)
        #expect(components1.year == 2003)
        
        // Test yearfirst
        let yearfirstParser = DateParser2(
            parserInfo: DateParser2.ParserInfo(dayfirst: false, yearfirst: true),
            calendar: calendar,
            locale: locale
        )
        
        let date2 = try yearfirstParser.parse("03/02/01")
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        #expect(components2.year == 2003)
        #expect(components2.month == 2)
        #expect(components2.day == 1)
        
        // Test both
        let bothParser = DateParser2(
            parserInfo: DateParser2.ParserInfo(dayfirst: true, yearfirst: true),
            calendar: calendar,
            locale: locale
        )
        
        let date3 = try bothParser.parse("03/01/02")
        let components3 = calendar.dateComponents([.year, .month, .day], from: date3)
        #expect(components3.year == 2003)
        #expect(components3.day == 1)
        #expect(components3.month == 2)
    }
    
    // MARK: - Performance Comparison Tests
    
    @Test("Performance comparison between parsers")
    func testPerformanceComparison() throws {
        let testDates = [
            "2024-03-15",
            "March 15, 2024",
            "15/03/2024",
            "tomorrow",
            "3 days ago",
            "2024-03-15T10:30:00Z"
        ]
        
        // Test DateParser2
        let parser2 = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        for dateString in testDates {
            _ = try parser2.parse(dateString)
        }
        
        // Test DateParser3
        let parser3 = DateParser3(
            parserInfo: DateParser3.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        for dateString in testDates {
            _ = try parser3.parse(dateString)
        }
        
        #expect(true, "Both parsers successfully parsed all test dates")
    }
}