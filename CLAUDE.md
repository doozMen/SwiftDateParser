# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

SwiftDateParser is a Swift Package Manager library that provides powerful date parsing capabilities inspired by Python's dateutil parser. The library offers natural language date parsing, multiple format support, and NLP-based date extraction from text.

## Common Development Commands

### Building the Package

```bash
# Build the package
swift build

# Build in release mode
swift build -c release

# Clean build artifacts
swift package clean
```

### Running Tests

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run a specific test
swift test --filter SwiftDateParserTests.DateParserTests/testBasicParsing

# Run tests in parallel
swift test --parallel
```

### Package Management

```bash
# Update dependencies
swift package update

# Resolve dependencies
swift package resolve

# Show package dependencies
swift package show-dependencies
```

### Linting

```bash
# Run SwiftLint (if installed)
swiftlint

# Auto-correct linting issues
swiftlint autocorrect
```

## Architecture

### Project Structure

```
SwiftDateParser/
├── Sources/SwiftDateParser/       # Source code
│   ├── SwiftDateParser.swift      # Main public API
│   ├── DateParser.swift           # Legacy parser (delegates to DateParser2)
│   ├── DateParser2.swift          # Full-featured parser with all capabilities
│   ├── DateParser3.swift          # Ultra-optimized parser for performance
│   ├── DateParserError.swift      # Error types
│   ├── NLPDateExtractor.swift     # Legacy NLP extractor
│   └── NLPDateExtractor2.swift    # Enhanced NLP date extraction
├── Tests/SwiftDateParserTests/    # Comprehensive test suite
│   ├── DateParserTests.swift      # Core parser tests
│   ├── DateParserComprehensiveTests.swift  # All parser features
│   ├── DateParserEdgeCaseTests.swift       # Edge cases and stress tests
│   ├── NLPDateExtractorTests.swift         # Basic NLP tests
│   ├── NLPDateExtractorComprehensiveTests.swift  # Full NLP coverage
│   ├── SwiftDateParserTests.swift          # API tests
│   └── SwiftDateParserREADMETests.swift    # README validation
├── docs/                          # Documentation and reports
├── Package.swift                  # Package manifest
├── Package.resolved               # Resolved dependencies
├── README.md                      # Project documentation
├── LICENSE                        # MIT License
├── CHANGELOG.md                   # Version history
└── CLAUDE.md                      # This file
```

### Key Technical Details

1. **Swift Version**: Swift 6.0 required
2. **Platforms**: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+
3. **Dependencies**: 
   - `swift-algorithms` for advanced algorithm support
4. **Testing Framework**: Swift Testing (not XCTest)
   - Tests use `@Test` and `@Suite` attributes
   - Assertions use `#expect` macro

### Core Components

1. **SwiftDateParser** - Static API facade
   - `parse(_:fuzzy:)` - Parse date strings (uses DateParser2)
   - `extractDates(from:)` - Extract dates from text
   - `parseWithTokens(_:fuzzy:)` - Parse with token extraction
   - `createParser()` - Create DateParser2 instance
   - `createParserV3()` - Create optimized DateParser3 instance
   - `createExtractor()` - Create NLPDateExtractor2 instance

2. **DateParser2** - Full-featured parsing engine
   - All date formats: ISO, US, EU, compact, logger format
   - Apostrophe years ('96), AD/BC dates, ordinal dates
   - Relative dates ("tomorrow", "3 days ago", "next Monday")
   - Timezone support, fuzzy parsing, date validation
   - Configurable: dayfirst, yearfirst, defaultDate

3. **DateParser3** - Performance-optimized parser
   - Simplified feature set for speed
   - Pre-computed patterns and optimizations
   - ~10x faster than DateParser2

4. **NLPDateExtractor2** - Enhanced NLP extraction
   - NSDataDetector for system date detection
   - Custom patterns for relative dates
   - Context extraction with configurable word count
   - Confidence scoring
   - Deduplication and position sorting

## Development Workflow

### Testing Best Practices

- Use Swift Testing framework (not XCTest)
- Test functions should be marked with `@Test`
- Use `#expect` for assertions
- Group related tests with `@Suite`
- Comprehensive test coverage includes:
  - Basic functionality tests
  - Edge cases and malformed inputs
  - Performance benchmarks
  - README claim validation
  - 69 tests across 7 test suites

### Code Organization

- Public API exposed through `SwiftDateParser.swift`
- Core parsing in `DateParser2.swift` (full features) and `DateParser3.swift` (optimized)
- NLP functionality in `NLPDateExtractor2.swift`
- Legacy compatibility in `DateParser.swift` and `NLPDateExtractor.swift`
- Error types in `DateParserError.swift`
- Keep internal types marked as `internal` or `private`

### Performance Considerations

- NSCache for date formatter caching
- Pre-compiled regex patterns as static properties
- Lazy initialization for NLP components
- DateParser3 offers ~10x performance improvement
- Inline optimizations with `@inlinable`
- Static lookup tables for O(1) month name resolution

### Known Limitations

- Some relative dates ("next Monday") need implementation
- AD/BC date calculations need refinement
- Timezone parsing partially implemented
- NLP extraction performance slower than claimed in README