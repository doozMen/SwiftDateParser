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
    
    /// Create a default DateParser instance
    public static func createParser(
        dayfirst: Bool = false,
        yearfirst: Bool = false,
        fuzzy: Bool = true,
        defaultDate: Date = Date()
    ) -> DateParser {
        let parserInfo = DateParser.ParserInfo(
            dayfirst: dayfirst,
            yearfirst: yearfirst,
            fuzzy: fuzzy,
            defaultDate: defaultDate
        )
        return DateParser(parserInfo: parserInfo)
    }
    
    /// Create an NLP date extractor
    public static func createExtractor(parser: DateParser? = nil) -> NLPDateExtractor {
        return NLPDateExtractor(parser: parser ?? createParser())
    }
    
    /// Convenience method to parse a date string
    public static func parse(_ dateString: String, fuzzy: Bool = true) throws -> Date {
        let parser = createParser(fuzzy: fuzzy)
        return try parser.parse(dateString)
    }
    
    /// Convenience method to extract dates from text
    public static func extractDates(from text: String) -> [NLPDateExtractor.ExtractedDate] {
        let extractor = createExtractor()
        return extractor.extractDates(from: text)
    }
}