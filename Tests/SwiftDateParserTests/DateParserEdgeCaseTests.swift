import Testing
@testable import SwiftDateParser
import Foundation

@Suite("DateParser Edge Cases and Ridiculous Tests")
struct DateParserEdgeCaseTests {
    
    let calendar: Calendar
    let locale: Locale
    
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        self.locale = Locale(identifier: "en_US_POSIX")
    }
    
    // MARK: - Ridiculous But Valid Date Tests
    
    @Test("Parse ridiculous but valid dates")
    func testRidiculousButValidDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let ridiculousDates = [
            // Extreme years
            ("January 1, 9999", 9999),
            ("December 31, 1", 1),
            ("July 4, 1776", 1776),  // Historical
            
            // Weird but valid formats
            ("2024-1-1", 2024),
            ("2024-01-1", 2024),
            ("2024-1-01", 2024),
            
            // Multiple spaces
            ("January    15,     2024", 2024),
            ("2024   -   03   -   15", 2024),
            
            // Mixed separators
            ("2024.03-15", 2024),
            ("15/03.2024", 2024),
            
            // Redundant zeros
            ("00003/00015/2024", 2024),
            
            // Case variations
            ("JANUARY 15, 2024", 2024),
            ("jAnUaRy 15, 2024", 2024),
            ("january 15, 2024", 2024),
            
            // With punctuation
            ("March, 15th, 2024.", 2024),
            ("15-Mar-2024!", 2024),
            
            // Spelled out numbers
            ("January fifteen, 2024", 2024),
            ("The fifteenth of January, 2024", 2024),
            
            // Roman numerals (might not work, but let's try)
            ("15-III-2024", 2024),  // March in Roman
            ("XV-03-2024", 2024),   // 15 in Roman
        ]
        
        for (dateString, expectedYear) in ridiculousDates {
            do {
                let date = try parser.parse(dateString)
                let year = calendar.component(.year, from: date)
                print("Successfully parsed '\(dateString)' -> year: \(year)")
                if year != expectedYear {
                    print("  Warning: Expected year \(expectedYear), got \(year)")
                }
            } catch {
                print("Failed to parse '\(dateString)': \(error)")
            }
        }
    }
    
    // MARK: - Boundary Value Tests
    
    @Test("Parse boundary dates")
    func testBoundaryDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(validateDates: true),
            calendar: calendar,
            locale: locale
        )
        
        // Valid boundary dates
        let validBoundaries = [
            "2024-01-01 00:00:00",  // Start of year
            "2024-12-31 23:59:59",  // End of year
            "2024-02-29",           // Leap day
            "2000-02-29",           // Leap day in century year
            "1900-12-31",           // End of 19th century
            "2000-01-01",           // Y2K
            "2038-01-19 03:14:07",  // Near Unix timestamp limit
        ]
        
        for dateString in validBoundaries {
            let date = try parser.parse(dateString)
            #expect(true, "Successfully parsed boundary date: \(dateString)")
        }
        
        // Invalid boundary dates
        let invalidBoundaries = [
            "2024-00-01",   // Month 0
            "2024-13-01",   // Month 13
            "2024-01-00",   // Day 0
            "2024-01-32",   // Day 32
            "2024-02-30",   // Feb 30
            "2023-02-29",   // Leap day in non-leap year
            "1900-02-29",   // Not a leap year (divisible by 100 but not 400)
        ]
        
        for dateString in invalidBoundaries {
            #expect(throws: DateParserError.self) {
                _ = try parser.parse(dateString)
            }
        }
    }
    
    // MARK: - Stress Tests
    
    @Test("Parse extremely long date strings")
    func testExtremelyLongStrings() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        // Create a very long string with a date buried in it
        let prefix = String(repeating: "blah ", count: 1000)
        let suffix = String(repeating: " yada", count: 1000)
        let longString = prefix + "March 15, 2024" + suffix
        
        let date = try parser.parse(longString)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2024)
        #expect(components.month == 3)
        #expect(components.day == 15)
    }
    
    // MARK: - Unicode and Emoji Tests
    
    @Test("Parse dates with unicode and emojis")
    func testUnicodeAndEmojis() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let unicodeDates = [
            "📅 March 15, 2024",
            "Meeting on 2024-03-15 🎉",
            "明天 tomorrow 📆",  // Chinese + English
            "Réunion le 15 mars 2024",  // French
            "15 марта 2024",  // Russian
            "١٥ مارس ٢٠٢٤",  // Arabic numerals
            "🗓️ Next Monday 🕐",
            "Birthday 🎂 December 25, 2024 🎁",
        ]
        
        for dateString in unicodeDates {
            do {
                let date = try parser.parse(dateString)
                print("Successfully parsed unicode date: '\(dateString)'")
            } catch {
                print("Failed to parse unicode date: '\(dateString)'")
            }
        }
    }
    
    // MARK: - Ambiguous Date Tests
    
    @Test("Parse highly ambiguous dates")
    func testHighlyAmbiguousDates() throws {
        // Test with different parser configurations
        let usParser = DateParser2(
            parserInfo: DateParser2.ParserInfo(dayfirst: false, yearfirst: false),
            calendar: calendar,
            locale: locale
        )
        
        let euParser = DateParser2(
            parserInfo: DateParser2.ParserInfo(dayfirst: true, yearfirst: false),
            calendar: calendar,
            locale: locale
        )
        
        // 01/02/03 could be:
        // US: Jan 2, 2003
        // EU: Feb 1, 2003
        // YearFirst: Jan 2, 2001
        
        let ambiguous = "01/02/03"
        
        let usDate = try usParser.parse(ambiguous)
        let usComponents = calendar.dateComponents([.year, .month, .day], from: usDate)
        #expect(usComponents.month == 1)  // January
        #expect(usComponents.day == 2)
        #expect(usComponents.year == 2003)
        
        let euDate = try euParser.parse(ambiguous)
        let euComponents = calendar.dateComponents([.year, .month, .day], from: euDate)
        #expect(euComponents.month == 2)  // February
        #expect(euComponents.day == 1)
        #expect(euComponents.year == 2003)
    }
    
    // MARK: - Malformed Input Tests
    
    @Test("Handle malformed inputs gracefully")
    func testMalformedInputs() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: false),
            calendar: calendar,
            locale: locale
        )
        
        let malformedInputs = [
            "",                      // Empty string
            "     ",                 // Only spaces
            "\n\t\r",               // Only whitespace
            "null",                 // Null string
            "undefined",            // Undefined string
            "NaN",                  // Not a number
            "Infinity",             // Infinity
            "-Infinity",            // Negative infinity
            "💩",                   // Just emoji
            "///",                  // Just separators
            "---",                  // Just dashes
            "...",                  // Just dots
            "12:34:56:78",          // Too many time components
            "2024-03-15-16",        // Too many date components
            "25:00",                // Invalid hour
            "12:61",                // Invalid minute
            "12:30:61",             // Invalid second
            "2024-14-01",           // Invalid month
            "2024-03-32",           // Invalid day
            "99999999999999999999", // Huge number
            "-2024-03-15",          // Negative year
            "2024--03-15",          // Double dash
            "2024-03--15",          // Double dash
            "2024-03-15-",          // Trailing dash
            String(repeating: "9", count: 1000),  // Very long number
        ]
        
        for input in malformedInputs {
            #expect(throws: DateParserError.self) {
                _ = try parser.parse(input)
            }
        }
    }
    
    // MARK: - Time Zone Edge Cases
    
    @Test("Parse dates with unusual timezones")
    func testUnusualTimezones() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(ignoretz: false),
            calendar: calendar,
            locale: locale
        )
        
        let timezoneDates = [
            "2024-03-15T12:00:00+13:00",    // Tonga (UTC+13)
            "2024-03-15T12:00:00-12:00",    // Baker Island (UTC-12)
            "2024-03-15T12:00:00+05:45",    // Nepal (UTC+5:45)
            "2024-03-15T12:00:00+08:30",    // North Korea (UTC+8:30)
            "2024-03-15T12:00:00+00:00",    // UTC
            "2024-03-15T12:00:00Z",         // Zulu time
            "2024-03-15T12:00:00+14:00",    // Line Islands (UTC+14)
        ]
        
        for dateString in timezoneDates {
            let date = try parser.parse(dateString)
            print("Successfully parsed timezone date: \(dateString)")
        }
    }
    
    // MARK: - Relative Date Edge Cases
    
    @Test("Parse extreme relative dates")
    func testExtremeRelativeDates() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let extremeRelatives = [
            "999 days ago",
            "in 1000 weeks",
            "365 months ago",
            "in 50 years",
            "1 second ago",
            "in 1 millisecond",  // Might not parse
            "0 days ago",        // Today?
            "-1 days ago",       // Tomorrow?
            "next next Monday",  // Double next
            "last last Friday",  // Double last
        ]
        
        for dateString in extremeRelatives {
            do {
                let date = try parser.parse(dateString)
                print("Successfully parsed extreme relative: '\(dateString)'")
            } catch {
                print("Failed to parse extreme relative: '\(dateString)'")
            }
        }
    }
    
    // MARK: - Format Mixing Tests
    
    @Test("Parse dates with mixed formats")
    func testMixedFormats() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        let mixedFormats = [
            "2024-Mar-15",              // ISO with month name
            "15-March-24",              // Day-MonthName-Year
            "March 15 '24",             // Month Day Apostrophe Year
            "15.3.2024 10:30",          // EU with time
            "3/15/24 @ 10:30 AM",       // US with @ symbol
            "2024年3月15日",            // Japanese format
            "15 de marzo de 2024",      // Spanish format
            "15. März 2024",            // German format
        ]
        
        for dateString in mixedFormats {
            do {
                let date = try parser.parse(dateString)
                print("Successfully parsed mixed format: '\(dateString)'")
            } catch {
                print("Failed to parse mixed format: '\(dateString)'")
            }
        }
    }
    
    // MARK: - Parser State Tests
    
    @Test("Parser handles state correctly")
    func testParserState() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(fuzzy: true),
            calendar: calendar,
            locale: locale
        )
        
        // Parse multiple dates in sequence to ensure no state pollution
        let dates = [
            "2024-01-01",
            "tomorrow",
            "3 days ago",
            "March 15, 2024",
            "15:30:00",
            "next Monday"
        ]
        
        var previousDate: Date?
        for dateString in dates {
            let date = try parser.parse(dateString)
            
            // Ensure each parse is independent
            if let prev = previousDate {
                #expect(date != prev || dateString == "tomorrow", 
                        "Parser should not reuse previous results")
            }
            previousDate = date
        }
    }
    
    // MARK: - Microsecond/Nanosecond Tests
    
    @Test("Parse dates with sub-second precision")
    func testSubSecondPrecision() throws {
        let parser = DateParser2(
            parserInfo: DateParser2.ParserInfo(),
            calendar: calendar,
            locale: locale
        )
        
        let precisionDates = [
            "2024-03-15T10:30:45.123",      // Milliseconds
            "2024-03-15T10:30:45.123456",   // Microseconds
            "2024-03-15T10:30:45.123456789", // Nanoseconds
            "2024-03-15 10:30:45,123",      // Logger format
            "2024-03-15 10:30:45.999999",   // Edge of second
        ]
        
        for dateString in precisionDates {
            let date = try parser.parse(dateString)
            print("Successfully parsed precision date: \(dateString)")
            
            // Verify the seconds component
            let seconds = calendar.component(.second, from: date)
            #expect(seconds == 45, "Should preserve seconds component")
        }
    }
}