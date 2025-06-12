import Foundation
import NaturalLanguage
import Algorithms

/// A flexible date parser that can parse various date formats including natural language
public struct DateParser {
    
    /// Parser configuration options
    public struct ParserInfo {
        public var dayfirst: Bool = false
        public var yearfirst: Bool = false
        public var fuzzy: Bool = false
        public var defaultDate: Date = Date()
        
        public init(dayfirst: Bool = false, yearfirst: Bool = false, fuzzy: Bool = false, defaultDate: Date = Date()) {
            self.dayfirst = dayfirst
            self.yearfirst = yearfirst
            self.fuzzy = fuzzy
            self.defaultDate = defaultDate
        }
    }
    
    private let parserInfo: ParserInfo
    private let calendar: Calendar
    private let locale: Locale
    
    // Common date formats to try
    private let dateFormatters: [DateFormatter]
    
    // Month names mapping
    private let monthNames: [String: Int] = [
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
    
    // Weekday names
    private let weekdayNames: [String: Int] = [
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7,
        "sunday": 1, "sun": 1
    ]
    
    public init(parserInfo: ParserInfo = ParserInfo(), calendar: Calendar = .current, locale: Locale = .current) {
        self.parserInfo = parserInfo
        self.calendar = calendar
        self.locale = locale
        self.dateFormatters = DateParser.createDateFormatters(locale: locale, calendar: calendar)
    }
    
    /// Parse a date string into a Date object
    public func parse(_ dateString: String) throws -> Date {
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty strings
        if trimmed.isEmpty {
            throw DateParserError.unableToParseDate(dateString)
        }
        
        // For non-fuzzy mode, validate that the string at least contains some digits or valid date words
        let hasDigits = trimmed.contains { $0.isNumber }
        let hasDateWords = monthNames.keys.contains { trimmed.lowercased().contains($0) } ||
                          ["today", "tomorrow", "yesterday", "week", "month", "year"].contains { trimmed.lowercased().contains($0) }
        let hasSpecialChars = Set("!@#$%^&*()_+={}[]|\\:;\"'<>,.?/").contains { trimmed.contains($0) }
        
        // Early rejection for obviously invalid date strings
        if !parserInfo.fuzzy {
            // Test for strings that are just non-date gibberish
            if (!hasDigits && !hasDateWords) || (hasSpecialChars && trimmed.count < 4) {
                throw DateParserError.unableToParseDate(dateString)
            }
        }
        
        // First priority: Try ISO 8601 format with direct component parsing
        if let date = parseISOFormat(trimmed) {
            return date
        }
        
        // Second priority: Try compact ISO 8601 format without separators (e.g. 20030925T1049)
        if let date = parseCompactISO8601(trimmed) {
            return date
        }
        
        // Third priority: Try standard date formatters
        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        // Fourth priority: If fuzzy parsing is enabled, try natural language parsing
        if parserInfo.fuzzy {
            if let date = parseNaturalLanguage(trimmed) {
                return date
            }
        }
        
        // Last priority: Try custom parsing logic
        if let date = parseCustomFormat(trimmed) {
            return date
        }
        
        // For short numeric strings that don't parse as dates
        if trimmed.count <= 6 && hasDigits && !hasDateWords {
            throw DateParserError.unableToParseDate(dateString)
        }
        
        throw DateParserError.unableToParseDate(dateString)
    }
    
    /// Parse ISO 8601 date format (e.g. 2003-09-25T10:49:41)
    private func parseISOFormat(_ text: String) -> Date? {
        // ISO format: yyyy-MM-ddTHH:mm:ss or yyyy-MM-dd HH:mm:ss
        let isoPattern = #"^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):?(\d{2})?:?(\d{2})?.*$"#
        
        // ISO date only: yyyy-MM-dd
        let isoDateOnlyPattern = #"^(\d{4})-(\d{2})-(\d{2})$"#
        
        if let regex = try? NSRegularExpression(pattern: isoPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                
                // Extract year, month, day
                if let yearRange = Range(match.range(at: 1), in: text),
                   let monthRange = Range(match.range(at: 2), in: text),
                   let dayRange = Range(match.range(at: 3), in: text),
                   let hourRange = Range(match.range(at: 4), in: text),
                   let year = Int(text[yearRange]),
                   let month = Int(text[monthRange]),
                   let day = Int(text[dayRange]),
                   let hour = Int(text[hourRange]) {
                    
                    components.year = year
                    components.month = month
                    components.day = day
                    components.hour = hour
                    
                    // Minutes are optional
                    if match.range(at: 5).location != NSNotFound,
                       let minuteRange = Range(match.range(at: 5), in: text),
                       let minute = Int(text[minuteRange]) {
                        components.minute = minute
                    } else {
                        components.minute = 0
                    }
                    
                    // Seconds are optional
                    if match.range(at: 6).location != NSNotFound,
                       let secondRange = Range(match.range(at: 6), in: text),
                       let second = Int(text[secondRange]) {
                        components.second = second
                    } else {
                        components.second = 0
                    }
                    
                    return calendar.date(from: components)
                }
            }
        }
        
        // Try date-only pattern
        if let regex = try? NSRegularExpression(pattern: isoDateOnlyPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                
                // Extract year, month, day
                if let yearRange = Range(match.range(at: 1), in: text),
                   let monthRange = Range(match.range(at: 2), in: text),
                   let dayRange = Range(match.range(at: 3), in: text),
                   let year = Int(text[yearRange]),
                   let month = Int(text[monthRange]),
                   let day = Int(text[dayRange]) {
                    
                    components.year = year
                    components.month = month
                    components.day = day
                    components.hour = 0
                    components.minute = 0
                    components.second = 0
                    
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    /// Parse compact ISO 8601 format (e.g. 20030925T1049)
    private func parseCompactISO8601(_ text: String) -> Date? {
        // yyyyMMddTHHmmss or yyyyMMddTHHmm or yyyyMMddTHH
        let compactISOPattern = #"^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})?(\d{2})?$"#
        
        // yyyyMMdd
        let compactDateOnlyPattern = #"^(\d{4})(\d{2})(\d{2})$"#
        
        if let regex = try? NSRegularExpression(pattern: compactISOPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                
                // Extract year, month, day
                if let yearRange = Range(match.range(at: 1), in: text),
                   let monthRange = Range(match.range(at: 2), in: text),
                   let dayRange = Range(match.range(at: 3), in: text),
                   let hourRange = Range(match.range(at: 4), in: text),
                   let year = Int(text[yearRange]),
                   let month = Int(text[monthRange]),
                   let day = Int(text[dayRange]),
                   let hour = Int(text[hourRange]) {
                    
                    components.year = year
                    components.month = month
                    components.day = day
                    components.hour = hour
                    
                    // Minutes are optional
                    if match.range(at: 5).location != NSNotFound,
                       let minuteRange = Range(match.range(at: 5), in: text),
                       let minute = Int(text[minuteRange]) {
                        components.minute = minute
                    }
                    
                    // Seconds are optional
                    if match.range(at: 6).location != NSNotFound,
                       let secondRange = Range(match.range(at: 6), in: text),
                       let second = Int(text[secondRange]) {
                        components.second = second
                    }
                    
                    return calendar.date(from: components)
                }
            }
        }
        
        // Try date-only pattern
        if let regex = try? NSRegularExpression(pattern: compactDateOnlyPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                
                // Extract year, month, day
                if let yearRange = Range(match.range(at: 1), in: text),
                   let monthRange = Range(match.range(at: 2), in: text),
                   let dayRange = Range(match.range(at: 3), in: text),
                   let year = Int(text[yearRange]),
                   let month = Int(text[monthRange]),
                   let day = Int(text[dayRange]) {
                    
                    components.year = year
                    components.month = month
                    components.day = day
                    
                    return calendar.date(from: components)
                }
            }
        }
        
        return nil
    }
    
    /// Parse multiple date formats using DateFormatter
    private static func createDateFormatters(locale: Locale, calendar: Calendar) -> [DateFormatter] {
        let formats = [
            // ISO formats
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "yyyyMMdd'T'HHmmss",
            "yyyyMMdd",
            
            // Common formats
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "MM-dd-yyyy",
            "dd-MM-yyyy",
            "MM.dd.yyyy",
            "dd.MM.yyyy",
            "MMM dd, yyyy",
            "dd MMM yyyy",
            "MMMM dd, yyyy",
            "EEEE, MMMM dd, yyyy",
            
            // Time formats
            "HH:mm:ss",
            "HH:mm",
            "h:mm a",
            "h:mm:ss a",
            
            // Unix-style formats
            "EEE MMM dd HH:mm:ss yyyy",
            "EEE MMM d HH:mm:ss yyyy",
            
            // Other common formats
            "MM/dd/yy",
            "dd/MM/yy",
            "yy-MM-dd",
            "MMM dd yyyy",
            "dd-MMM-yy",
            "yyyy/MM/dd",
            "dd MMM, yyyy",
            "MMM yyyy"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            return formatter
        }
    }
    
    /// Parse natural language dates
    private func parseNaturalLanguage(_ text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        if let match = matches?.first, let date = match.date {
            return date
        }
        
        // Try relative dates
        if let date = parseRelativeDate(text) {
            return date
        }
        
        return nil
    }
    
    /// Parse relative dates like "tomorrow", "next week", etc.
    private func parseRelativeDate(_ text: String) -> Date? {
        let lowercased = text.lowercased()
        let now = Date()
        
        switch lowercased {
        case "today":
            return calendar.startOfDay(for: now)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
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
            return parseRelativeWithNumber(lowercased)
        }
    }
    
    /// Parse relative dates with numbers like "3 days ago", "in 2 weeks"
    private func parseRelativeWithNumber(_ text: String) -> Date? {
        let pattern = #"(\d+)\s+(day|week|month|year)s?\s+(ago|from now)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        if let match = regex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            let numberRange = Range(match.range(at: 1), in: text)!
            let unitRange = Range(match.range(at: 2), in: text)!
            let directionRange = Range(match.range(at: 3), in: text)!
            
            guard let value = Int(text[numberRange]) else { return nil }
            let unit = String(text[unitRange]).lowercased()
            let direction = String(text[directionRange]).lowercased()
            
            let multiplier = direction == "ago" ? -1 : 1
            let adjustedValue = value * multiplier
            
            switch unit {
            case "day":
                return calendar.date(byAdding: .day, value: adjustedValue, to: Date())
            case "week":
                return calendar.date(byAdding: .weekOfYear, value: adjustedValue, to: Date())
            case "month":
                return calendar.date(byAdding: .month, value: adjustedValue, to: Date())
            case "year":
                return calendar.date(byAdding: .year, value: adjustedValue, to: Date())
            default:
                return nil
            }
        }
        
        // Try "in X days/weeks/months/years" format
        let futurePattern = #"in\s+(\d+)\s+(day|week|month|year)s?"#
        let futureRegex = try? NSRegularExpression(pattern: futurePattern, options: .caseInsensitive)
        
        if let match = futureRegex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            let numberRange = Range(match.range(at: 1), in: text)!
            let unitRange = Range(match.range(at: 2), in: text)!
            
            guard let value = Int(text[numberRange]) else { return nil }
            let unit = String(text[unitRange]).lowercased()
            
            switch unit {
            case "day":
                return calendar.date(byAdding: .day, value: value, to: Date())
            case "week":
                return calendar.date(byAdding: .weekOfYear, value: value, to: Date())
            case "month":
                return calendar.date(byAdding: .month, value: value, to: Date())
            case "year":
                return calendar.date(byAdding: .year, value: value, to: Date())
            default:
                return nil
            }
        }
        
        return nil
    }
    
    /// Parse custom date formats using tokenization
    private func parseCustomFormat(_ text: String) -> Date? {
        // Try custom short date formats like "10-09-03", "10.09.03", "10/09/03"
        if let date = parseShortDateFormats(text) {
            return date
        }
        
        // Try to parse ordinal dates like "3rd of May 2001"
        if let date = parseOrdinalDates(text) {
            return date
        }
        
        let tokens = tokenize(text)
        return parseTokens(tokens)
    }
    
    /// Parse short date formats like "MM-DD-YY", "DD-MM-YY", etc.
    private func parseShortDateFormats(_ text: String) -> Date? {
        // MM-DD-YY, DD-MM-YY, YY-MM-DD
        let shortDatePattern1 = #"^(\d{1,2})[-/.](\d{1,2})[-/.](\d{1,2})$"#
        
        // MM-DD-YYYY, DD-MM-YYYY, YYYY-MM-DD
        let shortDatePattern2 = #"^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$"#
        let shortDatePattern3 = #"^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$"#
        
        if let regex = try? NSRegularExpression(pattern: shortDatePattern1) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                guard let group1Range = Range(match.range(at: 1), in: text),
                      let group2Range = Range(match.range(at: 2), in: text),
                      let group3Range = Range(match.range(at: 3), in: text),
                      let num1 = Int(text[group1Range]),
                      let num2 = Int(text[group2Range]),
                      let num3 = Int(text[group3Range]) else {
                    return nil
                }
                
                var year: Int
                var month: Int
                var day: Int
                
                // Interpret short year format
                year = num3 < 50 ? 2000 + num3 : 1900 + num3
                
                // Determine month/day order based on parser settings
                if parserInfo.dayfirst {
                    day = num1
                    month = num2
                } else {
                    month = num1
                    day = num2
                }
                
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                components.year = year
                components.month = month
                components.day = day
                
                return calendar.date(from: components)
            }
        }
        
        // Try with 4-digit year
        if let regex = try? NSRegularExpression(pattern: shortDatePattern2) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                guard let group1Range = Range(match.range(at: 1), in: text),
                      let group2Range = Range(match.range(at: 2), in: text),
                      let group3Range = Range(match.range(at: 3), in: text),
                      let num1 = Int(text[group1Range]),
                      let num2 = Int(text[group2Range]),
                      let year = Int(text[group3Range]) else {
                    return nil
                }
                
                // Determine month/day order based on parser settings
                let (month, day) = parserInfo.dayfirst ? (num2, num1) : (num1, num2)
                
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                components.year = year
                components.month = month
                components.day = day
                
                return calendar.date(from: components)
            }
        }
        
        // Try with year-first format
        if let regex = try? NSRegularExpression(pattern: shortDatePattern3) {
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
                guard let yearRange = Range(match.range(at: 1), in: text),
                      let monthRange = Range(match.range(at: 2), in: text),
                      let dayRange = Range(match.range(at: 3), in: text),
                      let year = Int(text[yearRange]),
                      let month = Int(text[monthRange]),
                      let day = Int(text[dayRange]) else {
                    return nil
                }
                
                var components = DateComponents()
                components.calendar = calendar
                components.timeZone = calendar.timeZone
                components.year = year
                components.month = month
                components.day = day
                
                return calendar.date(from: components)
            }
        }
        
        return nil
    }
    
    /// Parse dates with ordinal numbers like "1st", "2nd", "3rd", "4th"
    private func parseOrdinalDates(_ text: String) -> Date? {
        // Match patterns like "1st of January 2020" or "3rd May 2001"
        let pattern = #"(\d+)(st|nd|rd|th)?\s+(of\s+)?(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\s+(\d{4})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            guard let dayRange = Range(match.range(at: 1), in: text),
                  let monthRange = Range(match.range(at: 4), in: text),
                  let yearRange = Range(match.range(at: 5), in: text),
                  let day = Int(text[dayRange]),
                  let year = Int(text[yearRange]) else {
                return nil
            }
            
            let monthText = text[monthRange].lowercased()
            
            // Map month names to numbers
            var foundMonth: Int? = monthNames[monthText]
            
            // Try partial match if exact match not found
            if foundMonth == nil {
                for (name, value) in monthNames {
                    if monthText.hasPrefix(name) || name.hasPrefix(monthText) {
                        foundMonth = value
                        break
                    }
                }
            }
            
            // Only proceed if we found a month
            guard let month = foundMonth else {
                return nil
            }
            
            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.year = year
            components.month = month
            components.day = day
            
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    /// Tokenize the input string
    private func tokenize(_ text: String) -> [Token] {
        var tokens: [Token] = []
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        
        while !scanner.isAtEnd {
            // Skip whitespace
            _ = scanner.scanCharacters(from: .whitespaces)
            
            if scanner.isAtEnd {
                break
            }
            
            // Try to scan a number
            if let number = scanner.scanDouble() {
                tokens.append(.number(number))
                continue
            }
            
            // Try to scan a word
            if let word = scanner.scanCharacters(from: .letters) {
                tokens.append(.word(word))
                continue
            }
            
            // Scan separator
            if let separator = scanner.scanCharacters(from: CharacterSet(charactersIn: "/-.,: ")) {
                tokens.append(.separator(separator))
                continue
            }
            
            // Skip unknown character
            scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
        }
        
        return tokens
    }
    
    /// Parse tokens into a date
    private func parseTokens(_ tokens: [Token]) -> Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = TimeZone.current
        
        var year: Int?
        var month: Int?
        var day: Int?
        var hour: Int?
        var minute: Int?
        var second: Int?
        var isPM = false
        
        var i = 0
        while i < tokens.count {
            switch tokens[i] {
            case .number(let value):
                let intValue = Int(value)
                
                // Handle different number patterns
                if value >= 1900 && value <= 2100 {
                    // Full year (1900-2100)
                    year = intValue
                } else if value >= 0 && value <= 99 {
                    // Could be day, month, or 2-digit year
                    if parserInfo.yearfirst && year == nil {
                        // Treat as 2-digit year
                        year = intValue < 50 ? 2000 + intValue : 1900 + intValue
                    } else if value >= 1 && value <= 31 && day == nil {
                        if parserInfo.dayfirst || (month != nil && day == nil) {
                            day = intValue
                        } else {
                            month = intValue
                        }
                    } else if value >= 1 && value <= 12 && month == nil {
                        month = intValue
                    } else if day != nil && month != nil && year == nil {
                        // Must be year if we already have day and month
                        year = intValue < 50 ? 2000 + intValue : 1900 + intValue
                    }
                } else if value >= 1 && value <= 31 && day == nil {
                    day = intValue
                } else if value >= 0 && value <= 23 && hour == nil {
                    hour = intValue
                } else if value >= 0 && value <= 59 && minute == nil {
                    minute = intValue
                } else if value >= 0 && value <= 59 && second == nil {
                    second = intValue
                }
                
            case .word(let word):
                let lowercased = word.lowercased()
                
                // Check for month names
                if let monthNumber = monthNames[lowercased] {
                    month = monthNumber
                }
                // Check for AM/PM
                else if lowercased == "am" || lowercased == "a.m." {
                    isPM = false
                } else if lowercased == "pm" || lowercased == "p.m." {
                    isPM = true
                }
                // Check for weekday names (for future enhancement)
                else if weekdayNames[lowercased] != nil {
                    // Could use this for relative date calculations
                }
                
            case .separator:
                // Separators help with parsing context
                break
            }
            
            i += 1
        }
        
        // Apply PM adjustment
        if isPM, let h = hour, h <= 12 {
            hour = h == 12 ? 12 : h + 12
        } else if !isPM, let h = hour, h == 12 {
            hour = 0
        }
        
        // Handle two-digit years if not already handled
        if let y = year, y >= 0 && y < 100 {
            year = y < 50 ? 2000 + y : 1900 + y
        }
        
        // Use default date components if not specified
        let defaultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parserInfo.defaultDate)
        
        components.year = year ?? defaultComponents.year
        components.month = month ?? defaultComponents.month
        components.day = day ?? defaultComponents.day
        components.hour = hour ?? defaultComponents.hour ?? 0
        components.minute = minute ?? defaultComponents.minute ?? 0
        components.second = second ?? defaultComponents.second ?? 0
        
        return calendar.date(from: components)
    }
    
    /// Token types for parsing
    private enum Token {
        case number(Double)
        case word(String)
        case separator(String)
    }
}

/// Errors that can occur during date parsing
public enum DateParserError: Error, LocalizedError {
    case unableToParseDate(String)
    
    public var errorDescription: String? {
        switch self {
        case .unableToParseDate(let dateString):
            return "Unable to parse date from string: '\(dateString)'"
        }
    }
}