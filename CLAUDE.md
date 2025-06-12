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

- **`Sources/SwiftDateParser/`** - Source code
  - `SwiftDateParser.swift` - Main public API providing static methods for date parsing
  - `DateParser.swift` - Core parsing engine with configurable options (dayfirst, yearfirst, fuzzy)
  - `NLPDateExtractor.swift` - Natural language processing for extracting dates from text
- **`Tests/SwiftDateParserTests/`** - Test suite using Swift Testing framework
- **`Package.swift`** - Package manifest defining dependencies and targets
- **`.swiftlint.yml`** - SwiftLint configuration for code style

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
   - `parse(_:fuzzy:)` - Parse date strings
   - `extractDates(from:)` - Extract dates from text
   - `createParser()` - Create custom parser instances
   - `createExtractor()` - Create custom extractor instances

2. **DateParser** - Configurable parsing engine
   - Handles multiple date formats (ISO, US, EU, etc.)
   - Supports relative dates ("tomorrow", "3 days ago")
   - Configurable parsing options

3. **NLPDateExtractor** - Natural language processing
   - Extracts dates from unstructured text
   - Provides confidence scores
   - Returns context around found dates

## Development Workflow

### Testing Best Practices

- Use Swift Testing framework (not XCTest)
- Test functions should be marked with `@Test`
- Use `#expect` for assertions
- Group related tests with `@Suite`

### Code Organization

- Public API should be exposed through `SwiftDateParser.swift`
- Core parsing logic belongs in `DateParser.swift`
- NLP functionality should be in `NLPDateExtractor.swift`
- Keep internal types and methods marked as `internal` or `private`

### Performance Considerations

- Date formatters are cached for performance
- Regex patterns are pre-compiled where possible
- Consider lazy initialization for expensive resources