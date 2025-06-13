import Foundation

/// Legacy DateParser for backward compatibility
/// This is a simplified version that delegates to DateParser2
public struct DateParser {
    private let parser: DateParser2
    
    public init(parserInfo: ParserInfo = ParserInfo(), 
                calendar: Calendar = Calendar.current,
                locale: Locale = Locale.current) {
        let parser2Info = DateParser2.ParserInfo(
            dayfirst: parserInfo.dayfirst,
            yearfirst: parserInfo.yearfirst,
            fuzzy: parserInfo.fuzzy,
            fuzzyWithTokens: parserInfo.fuzzyWithTokens,
            defaultDate: parserInfo.defaultDate ?? Date()
        )
        self.parser = DateParser2(parserInfo: parser2Info, calendar: calendar, locale: locale)
    }
    
    public func parse(_ dateString: String) throws -> Date {
        return try parser.parse(dateString)
    }
    
    public struct ParserInfo {
        public var dayfirst: Bool
        public var yearfirst: Bool  
        public var fuzzy: Bool
        public var fuzzyWithTokens: Bool
        public var defaultDate: Date?
        
        public init(dayfirst: Bool = false,
                    yearfirst: Bool = false,
                    fuzzy: Bool = false,
                    fuzzyWithTokens: Bool = false,
                    defaultDate: Date? = nil) {
            self.dayfirst = dayfirst
            self.yearfirst = yearfirst
            self.fuzzy = fuzzy
            self.fuzzyWithTokens = fuzzyWithTokens
            self.defaultDate = defaultDate
        }
    }
}