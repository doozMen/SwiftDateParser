import Foundation

/// SwiftDateParser - A flexible date parsing library inspired by Python's dateutil
///
/// This library provides powerful date parsing capabilities including:
/// - Multiple date format support
/// - Natural language date parsing
/// - Relative date parsing ("tomorrow", "3 days ago", etc.)
/// - NLP-based date extraction from text
///
/// Example usage:
/// ```swift
/// let parser = DateParser()
/// let date = try parser.parse("2023-12-25")
/// let relativeDate = try parser.parse("3 days from now")
/// ```
public struct SwiftDateParser {
    /// The current version of SwiftDateParser
    public static let version = "1.0.0"
    
    /// Create a default DateParser instance (uses optimized DateParser2)
    public static func createParser(
        dayfirst: Bool = false,
        yearfirst: Bool = false,
        fuzzy: Bool = true,
        defaultDate: Date = Date(),
        validateDates: Bool = false,
        ignoretz: Bool = false,
        tzinfos: [String: TimeZone]? = nil
    ) -> DateParser2 {
        let parserInfo = DateParser2.ParserInfo(
            dayfirst: dayfirst,
            yearfirst: yearfirst,
            fuzzy: fuzzy,
            fuzzyWithTokens: false,
            validateDates: validateDates,
            defaultDate: defaultDate,
            ignoretz: ignoretz,
            tzinfos: tzinfos
        )
        return DateParser2(parserInfo: parserInfo)
    }
    
    /// Create an ultra-optimized DateParser3 instance
    public static func createParserV3(
        dayfirst: Bool = false,
        yearfirst: Bool = false,
        fuzzy: Bool = true,
        defaultDate: Date = Date(),
        validateDates: Bool = false,
        ignoretz: Bool = false,
        tzinfos: [String: TimeZone]? = nil
    ) -> DateParser3 {
        let parserInfo = DateParser3.ParserInfo(
            dayfirst: dayfirst,
            yearfirst: yearfirst,
            fuzzy: fuzzy,
            fuzzyWithTokens: false,
            validateDates: validateDates,
            defaultDate: defaultDate,
            ignoretz: ignoretz,
            tzinfos: tzinfos
        )
        return DateParser3(parserInfo: parserInfo)
    }
    
    /// Create an NLP date extractor
    public static func createExtractor(parser: DateParser2? = nil) -> NLPDateExtractor2 {
        return NLPDateExtractor2(parser: parser ?? createParser())
    }
    
    /// Create an NLP date extractor with the old parser (for compatibility)
    public static func createExtractorLegacy(parser: DateParser? = nil) -> NLPDateExtractor {
        return NLPDateExtractor(parser: parser ?? DateParser())
    }
    
    /// Convenience method to parse a date string (uses DateParser2 for full feature support)
    public static func parse(_ dateString: String, fuzzy: Bool = true) throws -> Date {
        let parser = createParser(fuzzy: fuzzy)
        return try parser.parse(dateString)
    }
    
    /// Convenience method to extract dates from text
    public static func extractDates(from text: String) -> [NLPDateExtractor2.ExtractedDate] {
        let extractor = createExtractor()
        return extractor.extractDates(from: text)
    }
    
    /// Parse with tokens - returns date and skipped tokens
    public static func parseWithTokens(_ dateString: String, fuzzy: Bool = true) throws -> DateParser2.ParseResultWithTokens {
        let parserInfo = DateParser2.ParserInfo(
            fuzzy: fuzzy,
            fuzzyWithTokens: true,
            validateDates: false
        )
        let parser = DateParser2(parserInfo: parserInfo)
        return try parser.parseWithTokens(dateString)
    }
}