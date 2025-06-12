import Foundation
import NaturalLanguage

/// Optimized Natural Language Processing date extractor
public struct NLPDateExtractor2 {
    
    /// Result of date extraction
    public struct ExtractedDate {
        public let date: Date
        public let text: String
        public let range: Range<String.Index>
        public let confidence: Double
        public let timezone: TimeZone?
    }
    
    private let parser: DateParser2
    
    public init(parser: DateParser2 = DateParser2()) {
        self.parser = parser
    }
    
    /// Extract all dates from a given text
    public func extractDates(from text: String) -> [ExtractedDate] {
        var extractedDates: [ExtractedDate] = []
        
        // Use NSDataDetector for built-in date detection
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            for match in matches {
                if let date = match.date,
                   let range = Range(match.range, in: text) {
                    let matchedText = String(text[range])
                    extractedDates.append(ExtractedDate(
                        date: date,
                        text: matchedText,
                        range: range,
                        confidence: 0.9,
                        timezone: match.timeZone
                    ))
                }
            }
        }
        
        // Additional custom patterns
        let customPatterns = extractCustomDatePatterns(from: text)
        extractedDates.append(contentsOf: customPatterns)
        
        // Remove duplicates and sort by position
        return extractedDates
            .uniqued(on: { $0.range.lowerBound })
            .sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
    }
    
    /// Extract dates using custom patterns
    private func extractCustomDatePatterns(from text: String) -> [ExtractedDate] {
        var results: [ExtractedDate] = []
        
        // Direct search for relative terms
        let relativeTerms = [
            "today", "tomorrow", "yesterday",
            "next week", "last week", "next month", "last month", "next year", "last year"
        ]
        
        for term in relativeTerms {
            if let range = text.range(of: term, options: .caseInsensitive) {
                if let result = try? parser.parseWithTokens(term),
                   let date = result.date {
                    results.append(ExtractedDate(
                        date: date,
                        text: term,
                        range: range,
                        confidence: 0.95,
                        timezone: nil
                    ))
                }
            }
        }
        
        // Relative date patterns
        let relativePatterns = [
            // Relative with numbers
            (pattern: #"\b(\d+)\s+(day|week|month|year)s?\s+(ago|from now)\b"#, confidence: 0.85),
            // "in X time" format
            (pattern: #"\bin\s+(\d+)\s+(day|week|month|year)s?\b"#, confidence: 0.85),
            // Month names with optional day/year
            (pattern: #"\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\s+(\d{1,2})?,?\s*(\d{2,4})?\b"#, confidence: 0.8)
        ]
        
        for (pattern, confidence) in relativePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchedText = String(text[range])
                        
                        // Try to parse the matched text
                        if let result = try? parser.parseWithTokens(matchedText),
                           let date = result.date {
                            results.append(ExtractedDate(
                                date: date,
                                text: matchedText,
                                range: range,
                                confidence: confidence,
                                timezone: nil
                            ))
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    /// Extract dates with context
    public func extractDatesWithContext(from text: String, contextWords: Int = 5) -> [(date: ExtractedDate, context: String)] {
        let extractedDates = extractDates(from: text)
        var results: [(date: ExtractedDate, context: String)] = []
        
        for extractedDate in extractedDates {
            let context = extractContext(from: text, around: extractedDate.range, wordCount: contextWords)
            results.append((date: extractedDate, context: context))
        }
        
        return results
    }
    
    /// Extract context around a given range
    private func extractContext(from text: String, around range: Range<String.Index>, wordCount: Int) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: true)
        let targetStart = range.lowerBound
        let targetEnd = range.upperBound
        
        var startIndex = 0
        var endIndex = words.count - 1
        var foundStart = false
        var foundEnd = false
        
        // Find word indices containing the range
        for (index, word) in words.enumerated() {
            let wordStartIndex = text.range(of: String(word))?.lowerBound
            let wordEndIndex = text.range(of: String(word))?.upperBound
            
            if let wordStart = wordStartIndex, !foundStart && wordStart >= targetStart {
                startIndex = max(0, index - wordCount)
                foundStart = true
            }
            
            if let wordEnd = wordEndIndex, !foundEnd && wordEnd >= targetEnd {
                endIndex = min(words.count - 1, index + wordCount)
                foundEnd = true
                break
            }
        }
        
        let contextWords = words[startIndex...endIndex]
        return contextWords.joined(separator: " ")
    }
}

