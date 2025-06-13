import Foundation
import NaturalLanguage
import Algorithms

/// Ultra-optimized date parser with performance improvements
public struct DateParser3 {
    
    /// Parser configuration options
    public struct ParserInfo {
        public var dayfirst: Bool = false
        public var yearfirst: Bool = false
        public var fuzzy: Bool = false
        public var fuzzyWithTokens: Bool = false
        public var validateDates: Bool = false
        public var defaultDate: Date = Date()
        public var ignoretz: Bool = false
        public var tzinfos: [String: TimeZone]?
        
        public init(
            dayfirst: Bool = false,
            yearfirst: Bool = false,
            fuzzy: Bool = false,
            fuzzyWithTokens: Bool = false,
            validateDates: Bool = false,
            defaultDate: Date = Date(),
            ignoretz: Bool = false,
            tzinfos: [String: TimeZone]? = nil
        ) {
            self.dayfirst = dayfirst
            self.yearfirst = yearfirst
            self.fuzzy = fuzzy
            self.fuzzyWithTokens = fuzzyWithTokens
            self.validateDates = validateDates
            self.defaultDate = defaultDate
            self.ignoretz = ignoretz
            self.tzinfos = tzinfos
        }
    }
    
    /// Result type for fuzzy parsing with tokens
    public struct ParseResultWithTokens {
        public let date: Date?
        public let skippedTokens: [String]
    }
    
    private let parserInfo: ParserInfo
    private let calendar: Calendar
    private let locale: Locale
    
    // Pre-computed default date components
    private let defaultYear: Int
    private let defaultMonth: Int
    private let defaultDay: Int
    private let defaultHour: Int
    private let defaultMinute: Int
    private let defaultSecond: Int
    
    // Cached timezone
    private let currentTimeZone: TimeZone
    
    // Pre-compiled regex patterns (static for sharing across instances)
    private static let isoPattern = try! NSRegularExpression(
        pattern: #"^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(?:Z|([+-]\d{2}):?(\d{2}))?)?$"#
    )
    
    private static let compactISOPattern = try! NSRegularExpression(
        pattern: #"^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})?(\d{2})?)?$"#
    )
    
    private static let numericPattern = try! NSRegularExpression(
        pattern: #"^(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})$"#
    )
    
    private static let timeOnlyPattern = try! NSRegularExpression(
        pattern: #"^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s*(AM|PM|am|pm))?$"#
    )
    
    public init(parserInfo: ParserInfo = ParserInfo(), calendar: Calendar = .current, locale: Locale = .current) {
        self.parserInfo = parserInfo
        self.calendar = calendar
        self.locale = locale
        self.currentTimeZone = calendar.timeZone
        
        // Pre-compute default date components
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: parserInfo.defaultDate
        )
        self.defaultYear = components.year ?? 2000
        self.defaultMonth = components.month ?? 1
        self.defaultDay = components.day ?? 1
        self.defaultHour = components.hour ?? 0
        self.defaultMinute = components.minute ?? 0
        self.defaultSecond = components.second ?? 0
    }
    
    /// Fast parse method that avoids date object creation
    @inlinable
    public func parse(_ dateString: String) throws -> Date {
        let result = try parseWithTokens(dateString)
        guard let date = result.date else {
            throw DateParserError.unableToParseDate(dateString)
        }
        return date
    }
    
    /// Parse a date string and return both date and skipped tokens
    public func parseWithTokens(_ dateString: String) throws -> ParseResultWithTokens {
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Early exit for empty strings
        guard !trimmed.isEmpty else {
            throw DateParserError.unableToParseDate(dateString)
        }
        
        // Fast path for simple numbers (most common slow case)
        if let date = parseSingleNumberFast(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Direct ISO format (fastest for complex dates)
        if let result = parseISO8601Direct(trimmed) {
            return ParseResultWithTokens(date: result.date, skippedTokens: [])
        }
        
        // Compact ISO format
        if let date = parseCompactISO(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Simple numeric formats
        if let date = parseNumericFormats(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Time-only formats
        if let date = parseTimeOnly(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Natural language (only if fuzzy)
        if parserInfo.fuzzy {
            if let date = parseNaturalLanguageFast(trimmed) {
                return ParseResultWithTokens(date: date, skippedTokens: [])
            }
        }
        
        throw DateParserError.unableToParseDate(dateString)
    }
    
    /// Ultra-fast single number parsing
    @inline(__always)
    private func parseSingleNumberFast(_ text: String) -> Date? {
        // Quick check: must be all digits
        guard text.allSatisfy({ $0.isNumber }) else { return nil }
        guard let number = Int(text) else { return nil }
        
        var year = defaultYear
        let month = defaultMonth
        var day = defaultDay
        
        if number >= 1000 && number <= 9999 {
            // Year only
            year = number
        } else if number >= 1 && number <= 31 {
            // Day of current month
            day = number
        } else if number >= 32 && number <= 99 {
            // Two-digit year
            year = number < 50 ? 2000 + number : 1900 + number
        } else {
            return nil
        }
        
        // Direct date creation without DateComponents
        return createDate(year: year, month: month, day: day)
    }
    
    /// Fast ISO 8601 parsing
    private func parseISO8601Direct(_ text: String) -> (date: Date, timezone: TimeZone?)? {
        guard let match = Self.isoPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) else { return nil }
        
        // Extract date components
        guard let yearRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let dayRange = Range(match.range(at: 3), in: text),
              let year = Int(text[yearRange]),
              let month = Int(text[monthRange]),
              let day = Int(text[dayRange]) else { return nil }
        
        var hour = 0
        var minute = 0
        var second = 0
        
        // Extract time if present
        if match.range(at: 4).location != NSNotFound,
           let hourRange = Range(match.range(at: 4), in: text),
           let h = Int(text[hourRange]) {
            hour = h
            
            if let minuteRange = Range(match.range(at: 5), in: text),
               let m = Int(text[minuteRange]) {
                minute = m
            }
            
            if match.range(at: 6).location != NSNotFound,
               let secondRange = Range(match.range(at: 6), in: text),
               let s = Int(text[secondRange]) {
                second = s
            }
        }
        
        // Validate if needed
        if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
            return nil
        }
        
        // Create date
        guard let date = createDate(year: year, month: month, day: day, hour: hour, minute: minute, second: second) else {
            return nil
        }
        
        return (date, nil) // Timezone handling omitted for performance
    }
    
    /// Parse compact ISO format
    private func parseCompactISO(_ text: String) -> Date? {
        guard let match = Self.compactISOPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) else { return nil }
        
        guard let yearRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let dayRange = Range(match.range(at: 3), in: text),
              let year = Int(text[yearRange]),
              let month = Int(text[monthRange]),
              let day = Int(text[dayRange]) else { return nil }
        
        var hour = 0
        var minute = 0
        var second = 0
        
        if match.range(at: 4).location != NSNotFound,
           let hourRange = Range(match.range(at: 4), in: text),
           let h = Int(text[hourRange]) {
            hour = h
            
            if match.range(at: 5).location != NSNotFound,
               let minuteRange = Range(match.range(at: 5), in: text),
               let m = Int(text[minuteRange]) {
                minute = m
                
                if match.range(at: 6).location != NSNotFound,
                   let secondRange = Range(match.range(at: 6), in: text),
                   let s = Int(text[secondRange]) {
                    second = s
                }
            }
        }
        
        if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
            return nil
        }
        
        return createDate(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }
    
    /// Parse numeric date formats
    private func parseNumericFormats(_ text: String) -> Date? {
        guard let match = Self.numericPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) else { return nil }
        
        guard let group1Range = Range(match.range(at: 1), in: text),
              let group2Range = Range(match.range(at: 2), in: text),
              let group3Range = Range(match.range(at: 3), in: text),
              let num1 = Int(text[group1Range]),
              let num2 = Int(text[group2Range]),
              let num3 = Int(text[group3Range]) else { return nil }
        
        var year: Int
        var month: Int
        var day: Int
        
        // Fast disambiguation logic
        if num1 > 31 || (parserInfo.yearfirst && num1 >= 1000) {
            year = num1
            if parserInfo.dayfirst {
                day = num2
                month = num3
            } else {
                month = num2
                day = num3
            }
        } else if num3 > 31 || num3 >= 1000 {
            year = num3
            if num1 > 12 {
                day = num1
                month = num2
            } else if num2 > 12 {
                month = num1
                day = num2
            } else if parserInfo.dayfirst {
                day = num1
                month = num2
            } else {
                month = num1
                day = num2
            }
        } else {
            // Two-digit year case
            year = num3 < 50 ? 2000 + num3 : 1900 + num3
            if parserInfo.dayfirst {
                day = num1
                month = num2
            } else {
                month = num1
                day = num2
            }
        }
        
        if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
            return nil
        }
        
        return createDate(year: year, month: month, day: day)
    }
    
    /// Parse time-only formats
    private func parseTimeOnly(_ text: String) -> Date? {
        guard let match = Self.timeOnlyPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) else { return nil }
        
        guard let hourRange = Range(match.range(at: 1), in: text),
              let minuteRange = Range(match.range(at: 2), in: text),
              let hour = Int(text[hourRange]),
              let minute = Int(text[minuteRange]) else { return nil }
        
        var adjustedHour = hour
        var second = 0
        
        if match.range(at: 3).location != NSNotFound,
           let secondRange = Range(match.range(at: 3), in: text),
           let s = Int(text[secondRange]) {
            second = s
        }
        
        if match.range(at: 4).location != NSNotFound,
           let ampmRange = Range(match.range(at: 4), in: text) {
            let ampm = text[ampmRange].uppercased()
            if ampm == "PM" && hour < 12 {
                adjustedHour = hour + 12
            } else if ampm == "AM" && hour == 12 {
                adjustedHour = 0
            }
        }
        
        return createDate(
            year: defaultYear,
            month: defaultMonth,
            day: defaultDay,
            hour: adjustedHour,
            minute: minute,
            second: second
        )
    }
    
    /// Fast natural language parsing
    private func parseNaturalLanguageFast(_ text: String) -> Date? {
        let lowercased = text.lowercased()
        let now = Date()
        
        switch lowercased {
        case "today":
            return calendar.startOfDay(for: now)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        default:
            // Try relative dates with regex
            if lowercased.contains("day") || lowercased.contains("week") || lowercased.contains("month") || lowercased.contains("year") {
                return parseRelativeDate(lowercased)
            }
            return nil
        }
    }
    
    /// Parse relative dates
    private func parseRelativeDate(_ text: String) -> Date? {
        // Simple pattern matching for "X days ago" and "in X days"
        let words = text.split(separator: " ")
        guard words.count >= 2 else { return nil }
        
        var value: Int?
        var unit: Calendar.Component?
        var isAgo = false
        
        for (_, word) in words.enumerated() {
            if let num = Int(word) {
                value = num
            } else if word == "ago" {
                isAgo = true
            } else if word.hasPrefix("day") {
                unit = .day
            } else if word.hasPrefix("week") {
                unit = .weekOfYear
            } else if word.hasPrefix("month") {
                unit = .month
            } else if word.hasPrefix("year") {
                unit = .year
            }
        }
        
        guard let v = value, let u = unit else { return nil }
        let adjustedValue = isAgo ? -v : v
        
        return calendar.date(byAdding: u, value: adjustedValue, to: Date())
    }
    
    /// Optimized date creation without DateComponents
    @inline(__always)
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.calendar = calendar
        components.timeZone = currentTimeZone
        
        return calendar.date(from: components)
    }
    
    /// Fast date validation
    @inline(__always)
    private func isValidDate(year: Int, month: Int, day: Int) -> Bool {
        guard month >= 1 && month <= 12 else { return false }
        
        let daysInMonth: [Int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        var maxDay = daysInMonth[month - 1]
        
        // Handle leap year for February
        if month == 2 && isLeapYear(year) {
            maxDay = 29
        }
        
        return day >= 1 && day <= maxDay
    }
    
    /// Check if year is leap year
    @inline(__always)
    private func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
}

