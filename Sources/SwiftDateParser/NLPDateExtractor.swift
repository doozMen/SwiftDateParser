import Foundation
import NaturalLanguage

/// Legacy NLP date extractor for backward compatibility
/// This is a simplified version that delegates to NLPDateExtractor2
public class NLPDateExtractor {
    private let extractor: NLPDateExtractor2
    private let parser: DateParser?
    
    public init(parser: DateParser? = nil) {
        self.parser = parser
        self.extractor = NLPDateExtractor2()
    }
    
    public func extractDates(from text: String) -> [ExtractedDate] {
        let newDates = extractor.extractDates(from: text)
        return newDates.map { newDate in
            ExtractedDate(
                date: newDate.date,
                text: newDate.text,
                range: newDate.range,
                confidence: newDate.confidence,
                timezone: newDate.timezone
            )
        }
    }
    
    public struct ExtractedDate {
        public let date: Date
        public let text: String
        public let range: Range<String.Index>
        public let confidence: Double
        public let timezone: TimeZone?
        
        public init(date: Date, text: String, range: Range<String.Index>, 
                    confidence: Double, timezone: TimeZone? = nil) {
            self.date = date
            self.text = text
            self.range = range
            self.confidence = confidence
            self.timezone = timezone
        }
    }
}