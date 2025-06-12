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
        self.dateFormatters = DateParser.createDateFormatters(locale: locale)
    }
    
    /// Parse a date string into a Date object
    public func parse(_ dateString: String) throws -> Date {
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First, try standard date formatters
        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        // If fuzzy parsing is enabled, try natural language parsing
        if parserInfo.fuzzy {
            if let date = parseNaturalLanguage(trimmed) {
                return date
            }
        }
        
        // Try custom parsing logic
        if let date = parseCustomFormat(trimmed) {
            return date
        }
        
        throw DateParserError.unableToParseDate(dateString)
    }
    
    /// Parse multiple date formats using DateFormatter
    private static func createDateFormatters(locale: Locale) -> [DateFormatter] {
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
            formatter.timeZone = TimeZone.current
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
        let tokens = tokenize(text)
        return parseTokens(tokens)
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
                // Handle different number patterns
                if value >= 1900 && value <= 2100 {
                    year = Int(value)
                } else if value >= 1 && value <= 31 && day == nil {
                    day = Int(value)
                } else if value >= 1 && value <= 12 && month == nil {
                    month = Int(value)
                } else if value >= 0 && value <= 23 && hour == nil {
                    hour = Int(value)
                } else if value >= 0 && value <= 59 && minute == nil {
                    minute = Int(value)
                } else if value >= 0 && value <= 59 && second == nil {
                    second = Int(value)
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