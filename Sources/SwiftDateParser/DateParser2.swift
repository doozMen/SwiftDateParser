import Foundation
import NaturalLanguage
import Algorithms

/// Optimized date parser with improved performance and feature parity with Python dateutil
public struct DateParser2 {
    
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
    
    // Cached formatters - static to share across instances
    private nonisolated(unsafe) static let formatterCache = NSCache<NSString, DateFormatter>()
    private static let formatterQueue = DispatchQueue(label: "dateparser.formatter.cache")
    
    // Lazy NLP components - only created when needed
    private lazy var nlTagger: NLTagger? = {
        guard parserInfo.fuzzy else { return nil }
        return NLTagger(tagSchemes: [.lexicalClass, .nameType])
    }()
    
    // Pre-compiled regex patterns for performance
    private static let isoPattern = try! NSRegularExpression(
        pattern: #"^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T ](\d{1,2}):(\d{1,2}):(\d{1,2})(?:\.(\d+))?(?:([+-]\d{2}):?(\d{2})|Z)?)?$"#
    )
    private static let compactISOPattern = try! NSRegularExpression(
        pattern: #"^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2}))?$"#
    )
    private static let compactISOPatternAlt = try! NSRegularExpression(
        pattern: #"^(\d{8})T(\d{4,6})$"#
    )
    private static let numericPattern = try! NSRegularExpression(
        pattern: #"^(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})$"#
    )
    private static let timeOnlyPattern = try! NSRegularExpression(
        pattern: #"^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s*(AM|PM|am|pm))?$"#
    )
    
    // Month names mapping
    private static let monthNames: [String: Int] = [
        "january": 1, "jan": 1,
        "february": 2, "feb": 2,
        "march": 3, "mar": 3,
        "april": 4, "apr": 4,
        "may": 5,
        "june": 6, "jun": 6,
        "july": 7, "jul": 7,
        "august": 8, "aug": 8,
        "september": 9, "sep": 9, "sept": 9,
        "october": 10, "oct": 10,
        "november": 11, "nov": 11,
        "december": 12, "dec": 12
    ]
    
    public init(parserInfo: ParserInfo = ParserInfo(), calendar: Calendar = .current, locale: Locale = .current) {
        self.parserInfo = parserInfo
        self.calendar = calendar
        self.locale = locale
    }
    
    /// Parse a date string into a Date object
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
        if trimmed.isEmpty {
            throw DateParserError.unableToParseDate(dateString)
        }
        
        // Early exit for obviously invalid inputs (performance optimization)
        if !parserInfo.fuzzy {
            let hasValidChars = trimmed.contains { char in
                char.isNumber || char.isLetter || "/-.:, ".contains(char)
            }
            if !hasValidChars {
                throw DateParserError.unableToParseDate(dateString)
            }
        }
        
        // Try parsing strategies in order of speed (fastest first)
        
        // 1. Direct ISO format (fastest)
        if let result = parseISO8601Direct(trimmed) {
            return ParseResultWithTokens(date: result.date, skippedTokens: [])
        }
        
        // 2. Compact ISO format
        if let date = parseCompactISO(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // 3. Simple numeric formats
        if let date = parseNumericFormats(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // 4. Single number (year or day)
        if let date = parseSingleNumber(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // 5. Time-only formats
        if let date = parseTimeOnly(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // 4. Try cached formatters
        if let date = parseCachedFormatters(trimmed) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // 5. Natural language parsing (only if fuzzy enabled)
        if parserInfo.fuzzy {
            if let result = parseNaturalLanguage(trimmed) {
                return result
            }
        }
        
        // 6. Custom parsing as last resort
        if let result = parseCustomFormat(trimmed) {
            return result
        }
        
        throw DateParserError.unableToParseDate(dateString)
    }
    
    /// Fast ISO 8601 parsing using regex
    private func parseISO8601Direct(_ text: String) -> (date: Date, timezone: TimeZone?)? {
        guard let match = Self.isoPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) else { return nil }
        
        var components = DateComponents()
        components.calendar = calendar
        
        // Extract date components
        guard let yearRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let dayRange = Range(match.range(at: 3), in: text),
              let year = Int(text[yearRange]),
              let month = Int(text[monthRange]),
              let day = Int(text[dayRange]) else { return nil }
        
        components.year = year
        components.month = month
        components.day = day
        
        // Extract time components if present
        if match.range(at: 4).location != NSNotFound,
           let hourRange = Range(match.range(at: 4), in: text),
           let hour = Int(text[hourRange]) {
            components.hour = hour
            
            if let minuteRange = Range(match.range(at: 5), in: text),
               let minute = Int(text[minuteRange]) {
                components.minute = minute
            }
            
            if match.range(at: 6).location != NSNotFound,
               let secondRange = Range(match.range(at: 6), in: text),
               let second = Int(text[secondRange]) {
                components.second = second
            }
            
            // Handle milliseconds
            if match.range(at: 7).location != NSNotFound,
               let msRange = Range(match.range(at: 7), in: text) {
                let msString = String(text[msRange])
                let paddedMs = msString.padding(toLength: 3, withPad: "0", startingAt: 0)
                if let ms = Int(paddedMs.prefix(3)) {
                    components.nanosecond = ms * 1_000_000
                }
            }
        }
        
        // Handle timezone
        var timezone: TimeZone?
        if !parserInfo.ignoretz {
            if match.range(at: 8).location != NSNotFound {
                // UTC indicator
                if text.hasSuffix("Z") {
                    timezone = TimeZone(identifier: "UTC")
                    components.timeZone = timezone
                } else if let hourOffsetRange = Range(match.range(at: 8), in: text),
                          let hourOffset = Int(text[hourOffsetRange]) {
                    // Timezone offset
                    var seconds = hourOffset * 3600
                    if match.range(at: 9).location != NSNotFound,
                       let minuteOffsetRange = Range(match.range(at: 9), in: text),
                       let minuteOffset = Int(text[minuteOffsetRange]) {
                        seconds += (hourOffset < 0 ? -minuteOffset : minuteOffset) * 60
                    }
                    timezone = TimeZone(secondsFromGMT: seconds)
                    components.timeZone = timezone
                }
            }
        }
        
        // Validate date if requested
        if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
            return nil
        }
        
        guard let date = calendar.date(from: components) else { return nil }
        return (date, timezone)
    }
    
    /// Parse compact ISO format (e.g., 20030925T104941)
    private func parseCompactISO(_ text: String) -> Date? {
        // Try standard compact ISO pattern
        if let match = Self.compactISOPattern.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) {
            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            
            guard let yearRange = Range(match.range(at: 1), in: text),
                  let monthRange = Range(match.range(at: 2), in: text),
                  let dayRange = Range(match.range(at: 3), in: text),
                  let year = Int(text[yearRange]),
                  let month = Int(text[monthRange]),
                  let day = Int(text[dayRange]) else { return nil }
            
            components.year = year
            components.month = month
            components.day = day
            
            // Handle time if present
            if match.range(at: 4).location != NSNotFound,
               let hourRange = Range(match.range(at: 4), in: text),
               let minuteRange = Range(match.range(at: 5), in: text),
               let hour = Int(text[hourRange]),
               let minute = Int(text[minuteRange]) {
                components.hour = hour
                components.minute = minute
                
                if match.range(at: 6).location != NSNotFound,
                   let secondRange = Range(match.range(at: 6), in: text),
                   let second = Int(text[secondRange]) {
                    components.second = second
                }
            }
            
            if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
                return nil
            }
            
            return calendar.date(from: components)
        }
        
        // Try alternative pattern (e.g., 20030925T1049)
        if let match = Self.compactISOPatternAlt.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) {
            guard let dateRange = Range(match.range(at: 1), in: text),
                  let timeRange = Range(match.range(at: 2), in: text) else { return nil }
            
            let dateString = String(text[dateRange])
            let timeString = String(text[timeRange])
            
            guard dateString.count == 8,
                  let year = Int(dateString.prefix(4)),
                  let month = Int(dateString.dropFirst(4).prefix(2)),
                  let day = Int(dateString.dropFirst(6)) else { return nil }
            
            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.year = year
            components.month = month
            components.day = day
            
            // Parse time
            if timeString.count >= 4 {
                components.hour = Int(timeString.prefix(2))
                components.minute = Int(timeString.dropFirst(2).prefix(2))
                if timeString.count >= 6 {
                    components.second = Int(timeString.dropFirst(4).prefix(2))
                }
            }
            
            if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
                return nil
            }
            
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    /// Parse simple numeric date formats
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
        
        // Determine component order based on values and settings
        if num1 > 31 || (parserInfo.yearfirst && num1 >= 1000) {
            // First number is year
            year = num1
            if parserInfo.dayfirst {
                day = num2
                month = num3
            } else {
                month = num2
                day = num3
            }
        } else if num3 > 31 || num3 >= 1000 {
            // Last number is year
            year = num3
            if parserInfo.dayfirst {
                day = num1
                month = num2
            } else {
                month = num1
                day = num2
            }
        } else {
            // Ambiguous - apply two-digit year logic
            if parserInfo.yearfirst {
                year = convertTwoDigitYear(num1)
                month = num2
                day = num3
            } else {
                year = convertTwoDigitYear(num3)
                if parserInfo.dayfirst {
                    day = num1
                    month = num2
                } else {
                    month = num1
                    day = num2
                }
            }
        }
        
        // Validate
        if parserInfo.validateDates && !isValidDate(year: year, month: month, day: day) {
            return nil
        }
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        
        return calendar.date(from: components)
    }
    
    /// Parse single number as year or day
    private func parseSingleNumber(_ text: String) -> Date? {
        guard let number = Int(text) else { return nil }
        
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: parserInfo.defaultDate
        )
        
        if number >= 1000 && number <= 9999 {
            // Treat as year
            components.year = number
        } else if number >= 1 && number <= 31 {
            // Treat as day of current month
            components.day = number
        } else if number >= 32 && number <= 99 {
            // Two-digit year
            components.year = convertTwoDigitYear(number)
        } else {
            return nil
        }
        
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        
        return calendar.date(from: components)
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
              var hour = Int(text[hourRange]),
              let minute = Int(text[minuteRange]) else { return nil }
        
        var second = 0
        if match.range(at: 3).location != NSNotFound,
           let secondRange = Range(match.range(at: 3), in: text),
           let sec = Int(text[secondRange]) {
            second = sec
        }
        
        // Handle AM/PM
        if match.range(at: 4).location != NSNotFound,
           let ampmRange = Range(match.range(at: 4), in: text) {
            let ampm = text[ampmRange].lowercased()
            if ampm == "pm" && hour < 12 {
                hour += 12
            } else if ampm == "am" && hour == 12 {
                hour = 0
            }
        }
        
        // Use default date components
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: parserInfo.defaultDate
        )
        components.hour = hour
        components.minute = minute
        components.second = second
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        
        return calendar.date(from: components)
    }
    
    // Static format list for better performance
    private static let commonFormats: ContiguousArray<String> = [
        // Most common formats first
        "yyyy-MM-dd",
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss",
        "MMM dd yyyy",
        "dd MMM yyyy",
        "MMMM dd, yyyy",
        
        // Additional formats
        "MM-dd-yyyy",
        "dd-MM-yyyy",
        "yyyy/MM/dd",
        "EEE MMM dd HH:mm:ss yyyy",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    ]
    
    /// Parse using cached formatters
    private func parseCachedFormatters(_ text: String) -> Date? {
        let formats = Self.commonFormats
        
        for format in formats {
            let key = format as NSString
            
            let formatter = Self.formatterQueue.sync { () -> DateFormatter in
                if let cached = Self.formatterCache.object(forKey: key) {
                    return cached
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = locale
                    formatter.calendar = calendar
                    formatter.timeZone = calendar.timeZone
                    Self.formatterCache.setObject(formatter, forKey: key)
                    return formatter
                }
            }
            
            if let date = formatter.date(from: text) {
                return date
            }
        }
        
        return nil
    }
    
    /// Parse natural language dates
    private func parseNaturalLanguage(_ text: String) -> ParseResultWithTokens? {
        let lowercased = text.lowercased()
        
        // Quick check for common relative dates
        let simpleRelatives = [
            "today": 0,
            "tomorrow": 1,
            "yesterday": -1
        ]
        
        for (keyword, dayOffset) in simpleRelatives {
            if lowercased == keyword {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date()))
                return ParseResultWithTokens(date: date, skippedTokens: [])
            }
        }
        
        // Try relative date patterns
        if let date = parseRelativeDate(text) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // For fuzzy parsing, try to extract date from text
        if parserInfo.fuzzyWithTokens {
            return parseFuzzyWithTokens(text)
        }
        
        return nil
    }
    
    /// Parse relative dates
    private func parseRelativeDate(_ text: String) -> Date? {
        let lowercased = text.lowercased()
        let now = Date()
        
        // Patterns for relative dates
        let patterns: [(pattern: String, handler: (Int) -> Date?)] = [
            (#"(\d+)\s+days?\s+ago"#, { days in
                self.calendar.date(byAdding: .day, value: -days, to: now)
            }),
            (#"in\s+(\d+)\s+days?"#, { days in
                self.calendar.date(byAdding: .day, value: days, to: now)
            }),
            (#"(\d+)\s+weeks?\s+ago"#, { weeks in
                self.calendar.date(byAdding: .weekOfYear, value: -weeks, to: now)
            }),
            (#"in\s+(\d+)\s+weeks?"#, { weeks in
                self.calendar.date(byAdding: .weekOfYear, value: weeks, to: now)
            }),
            (#"(\d+)\s+months?\s+ago"#, { months in
                self.calendar.date(byAdding: .month, value: -months, to: now)
            }),
            (#"in\s+(\d+)\s+months?"#, { months in
                self.calendar.date(byAdding: .month, value: months, to: now)
            }),
            (#"(\d+)\s+years?\s+ago"#, { years in
                self.calendar.date(byAdding: .year, value: -years, to: now)
            }),
            (#"in\s+(\d+)\s+years?"#, { years in
                self.calendar.date(byAdding: .year, value: years, to: now)
            })
        ]
        
        for (pattern, handler) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(location: 0, length: lowercased.utf16.count)),
               let valueRange = Range(match.range(at: 1), in: lowercased),
               let value = Int(lowercased[valueRange]) {
                return handler(value)
            }
        }
        
        // Simple relative terms
        switch lowercased {
        case "next week":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        case "last week":
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now)
        case "next month":
            return calendar.date(byAdding: .month, value: 1, to: now)
        case "last month":
            return calendar.date(byAdding: .month, value: -1, to: now)
        case "next year":
            return calendar.date(byAdding: .year, value: 1, to: now)
        case "last year":
            return calendar.date(byAdding: .year, value: -1, to: now)
        default:
            break
        }
        
        return nil
    }
    
    /// Parse with fuzzy token extraction
    private func parseFuzzyWithTokens(_ text: String) -> ParseResultWithTokens? {
        let tokens = text.split(separator: " ").map { String($0) }
        var skippedTokens: [String] = []
        var dateTokens: [String] = []
        
        // Try to identify date-related tokens
        for token in tokens {
            if isDateToken(token) {
                dateTokens.append(token)
            } else {
                skippedTokens.append(token)
            }
        }
        
        // Try to parse the date tokens
        if !dateTokens.isEmpty {
            let dateString = dateTokens.joined(separator: " ")
            if let date = try? parse(dateString) {
                return ParseResultWithTokens(date: date, skippedTokens: skippedTokens)
            }
        }
        
        return nil
    }
    
    // Static set for O(1) date keyword lookup
    private static let dateKeywords: Set<String> = ["today", "tomorrow", "yesterday", "am", "pm", "week", "month", "year", "day"]
    
    /// Check if a token is likely date-related
    @inline(__always)
    private func isDateToken(_ token: String) -> Bool {
        // Check for numbers first (most common)
        if token.first?.isNumber == true { return true }
        
        // Check for date separators
        if token.contains(where: { "/-.".contains($0) }) { return true }
        
        let lowercased = token.lowercased()
        
        // Check for month names
        if Self.monthNames[lowercased] != nil { return true }
        
        // Check for date keywords
        if Self.dateKeywords.contains(lowercased) { return true }
        
        return false
    }
    
    /// Custom format parsing
    private func parseCustomFormat(_ text: String) -> ParseResultWithTokens? {
        // Handle logger format with comma for milliseconds
        let loggerPattern = #"^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}),(\d{3})$"#
        if let regex = try? NSRegularExpression(pattern: loggerPattern),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let dateRange = Range(match.range(at: 1), in: text),
           let msRange = Range(match.range(at: 2), in: text) {
            
            let dateString = String(text[dateRange])
            let msString = String(text[msRange])
            
            if var date = parseCachedFormatters(dateString),
               let ms = Int(msString) {
                // Add milliseconds
                let interval = TimeInterval(ms) / 1000.0
                date = date.addingTimeInterval(interval)
                return ParseResultWithTokens(date: date, skippedTokens: [])
            }
        }
        
        // Handle apostrophe years ('96)
        if let date = parseApostropheYear(text) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Handle AD/BC dates
        if let date = parseADBCDates(text) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        // Handle ordinal dates
        if let date = parseOrdinalDates(text) {
            return ParseResultWithTokens(date: date, skippedTokens: [])
        }
        
        return nil
    }
    
    /// Parse dates with apostrophe years like "Wed, July 10, '96"
    private func parseApostropheYear(_ text: String) -> Date? {
        // Patterns for apostrophe years
        let patterns = [
            // "Wed, July 10, '96" or "July 10, '96"
            #"(?:(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun),?\s+)?(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\s+(\d{1,2}),?\s*'(\d{2})"#,
            // "'96-07-10" format
            #"'(\d{2})-(\d{1,2})-(\d{1,2})"#,
            // "10-Jul-'96" format
            #"(\d{1,2})-(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)-'(\d{2})"#
        ]
        
        // Try first pattern
        if let regex = try? NSRegularExpression(pattern: patterns[0], options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            
            if let monthRange = Range(match.range(at: 1), in: text),
               let dayRange = Range(match.range(at: 2), in: text),
               let yearRange = Range(match.range(at: 3), in: text),
               let day = Int(text[dayRange]),
               let yearTwoDigit = Int(text[yearRange]) {
                
                let monthText = text[monthRange].lowercased()
                if let month = Self.monthNames[monthText] {
                    let year = convertTwoDigitYear(yearTwoDigit)
                    
                    if !parserInfo.validateDates || isValidDate(year: year, month: month, day: day) {
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = day
                        components.calendar = calendar
                        components.timeZone = calendar.timeZone
                        return calendar.date(from: components)
                    }
                }
            }
        }
        
        // Try second pattern ('YY-MM-DD)
        if let regex = try? NSRegularExpression(pattern: patterns[1], options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let yearRange = Range(match.range(at: 1), in: text),
           let monthRange = Range(match.range(at: 2), in: text),
           let dayRange = Range(match.range(at: 3), in: text),
           let yearTwoDigit = Int(text[yearRange]),
           let month = Int(text[monthRange]),
           let day = Int(text[dayRange]) {
            
            let year = convertTwoDigitYear(yearTwoDigit)
            
            if !parserInfo.validateDates || isValidDate(year: year, month: month, day: day) {
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                return calendar.date(from: components)
            }
        }
        
        // Try third pattern (DD-Mon-'YY)
        if let regex = try? NSRegularExpression(pattern: patterns[2], options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let dayRange = Range(match.range(at: 1), in: text),
           let monthRange = Range(match.range(at: 2), in: text),
           let yearRange = Range(match.range(at: 3), in: text),
           let day = Int(text[dayRange]),
           let yearTwoDigit = Int(text[yearRange]) {
            
            let monthText = text[monthRange].lowercased()
            if let month = Self.monthNames[monthText] {
                let year = convertTwoDigitYear(yearTwoDigit)
                
                if !parserInfo.validateDates || isValidDate(year: year, month: month, day: day) {
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = day
                    components.calendar = calendar
                    components.timeZone = calendar.timeZone
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    /// Parse dates with AD/BC markers
    private func parseADBCDates(_ text: String) -> Date? {
        // Pattern for AD/BC dates
        let pattern = #"(\d{1,4})(?:\.(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\.(\d{1,2}))?\s*(?:AD|A\.D\.|CE|C\.E\.|BC|B\.C\.|BCE|B\.C\.E\.)"#
        
        // Also handle time if present
        let patternWithTime = #"(\d{1,4})(?:\.(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\.(\d{1,2}))?\s*(?:AD|A\.D\.|CE|C\.E\.|BC|B\.C\.|BCE|B\.C\.E\.)\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(?:AM|PM|am|pm)?"#
        
        // Try pattern with time first
        if let regex = try? NSRegularExpression(pattern: patternWithTime, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            
            let yearRange = Range(match.range(at: 1), in: text)!
            var year = Int(text[yearRange])!
            
            // Check if BC/BCE
            let isBCPattern = #"(?:BC|B\.C\.|BCE|B\.C\.E\.)"#
            if let bcRegex = try? NSRegularExpression(pattern: isBCPattern, options: .caseInsensitive),
               bcRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                year = -year + 1  // BC years: 1 BC = year 0, 2 BC = year -1, etc.
            }
            
            var components = DateComponents()
            components.year = year
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            
            // Extract month if present
            if match.range(at: 2).location != NSNotFound,
               let monthRange = Range(match.range(at: 2), in: text) {
                let monthText = text[monthRange].lowercased()
                components.month = Self.monthNames[monthText]
            } else {
                components.month = 1  // Default to January
            }
            
            // Extract day if present
            if match.range(at: 3).location != NSNotFound,
               let dayRange = Range(match.range(at: 3), in: text),
               let day = Int(text[dayRange]) {
                components.day = day
            } else {
                components.day = 1  // Default to 1st
            }
            
            // Extract time if present
            if match.range(at: 4).location != NSNotFound,
               let hourRange = Range(match.range(at: 4), in: text),
               let hour = Int(text[hourRange]) {
                components.hour = hour
                
                if match.range(at: 5).location != NSNotFound,
                   let minuteRange = Range(match.range(at: 5), in: text),
                   let minute = Int(text[minuteRange]) {
                    components.minute = minute
                }
                
                if match.range(at: 6).location != NSNotFound,
                   let secondRange = Range(match.range(at: 6), in: text),
                   let second = Int(text[secondRange]) {
                    components.second = second
                }
            }
            
            return calendar.date(from: components)
        }
        
        // Try simpler pattern without time
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let yearRange = Range(match.range(at: 1), in: text),
           var year = Int(text[yearRange]) {
            
            // Check if BC/BCE
            let isBCPattern = #"(?:BC|B\.C\.|BCE|B\.C\.E\.)"#
            if let bcRegex = try? NSRegularExpression(pattern: isBCPattern, options: .caseInsensitive),
               bcRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                year = -year + 1  // BC years: 1 BC = year 0, 2 BC = year -1, etc.
            }
            
            var components = DateComponents()
            components.year = year
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            
            // Extract month if present
            if match.range(at: 2).location != NSNotFound,
               let monthRange = Range(match.range(at: 2), in: text) {
                let monthText = text[monthRange].lowercased()
                components.month = Self.monthNames[monthText]
            } else {
                components.month = 1  // Default to January
            }
            
            // Extract day if present
            if match.range(at: 3).location != NSNotFound,
               let dayRange = Range(match.range(at: 3), in: text),
               let day = Int(text[dayRange]) {
                components.day = day
            } else {
                components.day = 1  // Default to 1st
            }
            
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    /// Parse ordinal dates like "3rd of May 2001" or "May 3rd, 2001"
    private func parseOrdinalDates(_ text: String) -> Date? {
        // Pattern for "3rd of May 2001" style
        let pattern1 = #"(\d+)(?:st|nd|rd|th)?\s+(?:of\s+)?(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)(?:\s+|,\s*)(\d{4})"#
        
        // Pattern for "May 3rd, 2001" style
        let pattern2 = #"(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\s+(\d+)(?:st|nd|rd|th)?,?\s*(\d{4})"#
        
        // Try first pattern
        if let regex = try? NSRegularExpression(pattern: pattern1, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let dayRange = Range(match.range(at: 1), in: text),
           let monthRange = Range(match.range(at: 2), in: text),
           let yearRange = Range(match.range(at: 3), in: text),
           let day = Int(text[dayRange]),
           let year = Int(text[yearRange]) {
            
            let monthText = text[monthRange].lowercased()
            if let month = Self.monthNames[monthText] {
                if !parserInfo.validateDates || isValidDate(year: year, month: month, day: day) {
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = day
                    components.calendar = calendar
                    components.timeZone = calendar.timeZone
                    return calendar.date(from: components)
                }
            }
        }
        
        // Try second pattern (US style)
        if let regex = try? NSRegularExpression(pattern: pattern2, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let monthRange = Range(match.range(at: 1), in: text),
           let dayRange = Range(match.range(at: 2), in: text),
           let yearRange = Range(match.range(at: 3), in: text),
           let day = Int(text[dayRange]),
           let year = Int(text[yearRange]) {
            
            let monthText = text[monthRange].lowercased()
            if let month = Self.monthNames[monthText] {
                if !parserInfo.validateDates || isValidDate(year: year, month: month, day: day) {
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = day
                    components.calendar = calendar
                    components.timeZone = calendar.timeZone
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    /// Convert two-digit year to four-digit year using 50-year window
    @inline(__always)
    private func convertTwoDigitYear(_ year: Int) -> Int {
        if year >= 100 { return year }
        
        let currentYear = calendar.component(.year, from: Date())
        let century = (currentYear / 100) * 100
        let currentTwoDigit = currentYear % 100
        
        // 50-year window: if year is within 50 years in the future, use current century
        // Otherwise use previous century
        if year <= currentTwoDigit + 50 {
            return century + year
        } else {
            return century - 100 + year
        }
    }
    
    /// Validate date components
    @inline(__always)
    private func isValidDate(year: Int, month: Int, day: Int) -> Bool {
        // Basic range checks
        guard month >= 1 && month <= 12 else { return false }
        
        // Days in month - use static array for performance
        let daysInMonth: ContiguousArray<Int> = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        var maxDay = daysInMonth[month - 1]
        
        // Check for leap year
        if month == 2 && isLeapYear(year) {
            maxDay = 29
        }
        
        return day >= 1 && day <= maxDay
    }
    
    /// Check if year is a leap year
    @inline(__always)
    private func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
}

