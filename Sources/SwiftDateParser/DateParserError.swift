import Foundation

/// Errors that can occur during date parsing
public enum DateParserError: Error, LocalizedError {
    /// Unable to parse the given date string
    case unableToParseDate(String)
    
    public var errorDescription: String? {
        switch self {
        case .unableToParseDate(let dateString):
            return "Unable to parse date: '\(dateString)'"
        }
    }
}