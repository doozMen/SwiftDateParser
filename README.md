# SwiftDateParser

A powerful and flexible date parsing library for Swift, inspired by Python's dateutil parser. This library provides natural language date parsing, multiple format support, and advanced NLP-based date extraction from text.

## Features

- 📅 **Multiple Date Format Support**: Parse dates in various formats (ISO, US, EU, etc.)
- 🗣️ **Natural Language Processing**: Extract dates from natural text
- 🔄 **Relative Date Parsing**: Understand "tomorrow", "3 days ago", "next week", etc.
- 🌍 **Locale Support**: Respects system locale for date interpretation
- ⚡ **High Performance**: Optimized for speed with caching mechanisms
- 🧪 **Comprehensive Tests**: Extensive test coverage
- 📱 **Cross-Platform**: Works on macOS, iOS, tvOS, and watchOS

## Installation

### Swift Package Manager

Add SwiftDateParser to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/doozMen/SwiftDateParser.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/doozMen/SwiftDateParser.git`
3. Click Add Package

## Usage

### Basic Date Parsing

```swift
import SwiftDateParser

// Simple parsing
let date = try SwiftDateParser.parse("2024-03-15")
let relativeDate = try SwiftDateParser.parse("tomorrow")
let naturalDate = try SwiftDateParser.parse("March 15, 2024 at 3:30 PM")
```

### Advanced Parser Configuration

```swift
// Create a custom parser
let parser = SwiftDateParser.createParser(
    dayfirst: true,      // Interpret 01/02/03 as 1 Feb 2003
    yearfirst: false,    // Year doesn't come first
    fuzzy: true,         // Enable fuzzy parsing
    defaultDate: Date()  // Use current date for missing components
)

let date = try parser.parse("15/03/24")
```

### Natural Language Date Extraction

```swift
// Extract dates from text
let text = """
The meeting is scheduled for tomorrow at 3 PM. 
Please submit the report by December 15, 2023.
We'll review it next week.
"""

let extractedDates = SwiftDateParser.extractDates(from: text)

for extracted in extractedDates {
    print("Found: '\(extracted.text)' -> \(extracted.date)")
    print("Confidence: \(extracted.confidence)")
}
```

### Extract Dates with Context

```swift
let extractor = SwiftDateParser.createExtractor()
let results = extractor.extractDatesWithContext(from: text, contextWords: 5)

for (date, context) in results {
    print("Date: \(date.text)")
    print("Context: \(context)")
}
```

## Supported Date Formats

### Standard Formats
- ISO 8601: `2024-03-15T10:30:00`
- US Format: `03/15/2024`, `3/15/24`
- EU Format: `15/03/2024`, `15.03.2024`
- Long Format: `March 15, 2024`
- Compact: `20240315`

### Relative Dates
- Simple: `today`, `tomorrow`, `yesterday`
- With numbers: `3 days ago`, `in 2 weeks`
- Next/Last: `next Monday`, `last month`

### Natural Language
- `The 3rd of May 2024`
- `December 25th at 3:30 PM`
- `Next Tuesday afternoon`
- `2 weeks from today`

## API Reference

### SwiftDateParser

#### `parse(_:fuzzy:)`
Parses a date string and returns a Date object.

```swift
static func parse(_ dateString: String, fuzzy: Bool = true) throws -> Date
```

#### `extractDates(from:)`
Extracts all dates found in the given text.

```swift
static func extractDates(from text: String) -> [NLPDateExtractor.ExtractedDate]
```

### DateParser

The core parsing engine with configurable options.

```swift
let parser = DateParser(parserInfo: parserInfo, calendar: calendar, locale: locale)
let date = try parser.parse("2024-03-15")
```

### NLPDateExtractor

Advanced natural language date extraction.

```swift
let extractor = NLPDateExtractor()
let dates = extractor.extractDates(from: "Meeting tomorrow at 3 PM")
```

## Examples

### Email Date Extraction

```swift
let email = """
Subject: Quarterly Review

Hi team,

Our Q1 review is scheduled for March 15, 2024 at 2 PM EST.
Please submit your reports by end of day tomorrow.

The deadline for Q2 planning is April 1st.

Best regards
"""

let dates = SwiftDateParser.extractDates(from: email)
// Extracts: "March 15, 2024 at 2 PM EST", "tomorrow", "April 1st"
```

### Calendar Event Parsing

```swift
let events = [
    "Team standup every Monday at 9 AM",
    "Project deadline: 2024-06-30",
    "Vacation from July 15 to July 22",
    "Conference in 3 months"
]

for event in events {
    if let dates = SwiftDateParser.extractDates(from: event).first {
        print("Event: \(event)")
        print("Date: \(dates.date)")
    }
}
```

## Error Handling

```swift
do {
    let date = try SwiftDateParser.parse("invalid date")
} catch DateParserError.unableToParseDate(let string) {
    print("Could not parse: \(string)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Performance

SwiftDateParser is optimized for performance:
- Cached date formatters
- Efficient regex patterns
- Lazy initialization of resources

Benchmark results on MacBook Pro M1:
- Simple date parsing: ~0.05ms
- Natural language extraction: ~2ms per 1000 characters
- Relative date parsing: ~0.1ms

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by Python's [dateutil](https://github.com/dateutil/dateutil) library
- Uses Swift's native Natural Language framework
- Built with Swift Package Manager

## Support

For questions and support:
- Open an issue on [GitHub](https://github.com/doozMen/SwiftDateParser/issues)
- Check out the [documentation](https://github.com/doozMen/SwiftDateParser/wiki)

---

Made with ❤️ by the Swift community