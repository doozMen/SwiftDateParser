import Foundation
import NaturalLanguage

/// Natural Language Processing date extractor for finding dates in text
public struct NLPDateExtractor {
    
    /// Result of date extraction
    public struct ExtractedDate {
        public let date: Date
        public let text: String
        public let range: Range<String.Index>
        public let confidence: Double
    }
    
    private let tagger: NLTagger
    private let parser: DateParser
    
    public init(parser: DateParser = DateParser()) {
        self.tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
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
                        confidence: 0.9
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
        
        // Relative date patterns
        let relativePatterns = [
            // Simple relative dates
            (pattern: #"\b(today|tomorrow|yesterday)\b"#, confidence: 0.95),
            // Relative with numbers
            (pattern: #"\b(\d+)\s+(day|week|month|year)s?\s+(ago|from now)\b"#, confidence: 0.85),
            // "in X time" format
            (pattern: #"\bin\s+(\d+)\s+(day|week|month|year)s?\b"#, confidence: 0.85),
            // Next/last time periods
            (pattern: #"\b(next|last)\s+(week|month|year|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, confidence: 0.9),
            // Specific day names
            (pattern: #"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, confidence: 0.7),
            // Month names with optional day/year
            (pattern: #"\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\s+(\d{1,2})?,?\s*(\d{2,4})?\b"#, confidence: 0.8)
        ]
        
        for (pattern, confidence) in relativePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchedText = String(text[range])
                        
                        // Create a fuzzy parser for relative dates
                        let fuzzyParser = DateParser(parserInfo: DateParser.ParserInfo(fuzzy: true))
                        
                        // Try to parse the matched text
                        if let date = try? fuzzyParser.parse(matchedText) {
                            results.append(ExtractedDate(
                                date: date,
                                text: matchedText,
                                range: range,
                                confidence: confidence
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

// Extension for removing duplicates from an array
extension Sequence {
    func uniqued<T: Hashable>(on projection: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = projection(element)
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}