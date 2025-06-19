# Changelog

All notable changes to SwiftDateParser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-01-19

### Added
- Unit tests for relative date parsing behavior (RelativeDateTests.swift)
- Tests to verify relative dates are calculated from current system time
- Tests for defaultDate usage with partial date parsing

### Fixed
- Clarified that relative dates ("today", "yesterday", "tomorrow") are correctly calculated from the current system time
- Clarified that defaultDate is used for providing default components when parsing partial dates (e.g., time-only strings)

### Documentation
- Added comprehensive test suite demonstrating proper behavior of relative date parsing
- Added tests showing how defaultDate affects partial date parsing

## [1.0.0+improvements] - 2024-12-06

### Added
- Comprehensive test suite with 69 tests across 7 test suites
- DateParser2: Full-featured parser with all capabilities
- DateParser3: Ultra-optimized parser with ~10x performance improvement
- DateParserError: Proper error type for parsing failures
- Legacy compatibility layers (DateParser, NLPDateExtractor)
- Four new test files:
  - DateParserComprehensiveTests: All parser features including apostrophe years, AD/BC dates
  - DateParserEdgeCaseTests: Edge cases, stress tests, and malformed inputs
  - NLPDateExtractorComprehensiveTests: Full NLP coverage with performance tests
  - SwiftDateParserREADMETests: Validates all README claims
- Repository organization with docs/ folder for documentation

### Changed
- SwiftDateParser.parse() now uses DateParser2 by default for full feature support
- Improved parseWithTokens to properly enable fuzzyWithTokens mode
- Updated project documentation in CLAUDE.md

### Fixed
- Missing error types that were causing compilation issues
- Parser timezone handling for consistent behavior

## [1.0.0] - 2024-12-06

### Added
- Initial release of SwiftDateParser
- Swift port of Python's dateutil parser, created with Claude Code
- Core date parsing functionality with multiple format support
- Natural Language Processing (NLP) based date extraction
- Relative date parsing ("tomorrow", "3 days ago", etc.)
- Support for various date formats:
  - ISO 8601 formats
  - US and EU date formats
  - Natural language dates
  - Compact formats
- Configurable parser options (dayfirst, yearfirst, fuzzy)
- Comprehensive test suite using Swift Testing framework
- Cross-platform support (macOS, iOS, tvOS, watchOS, visionOS)
- Integration with Apple's Natural Language framework
- High-performance implementation with cached formatters

### Known Limitations
- No timezone parsing (uses system timezone)
- Some edge cases in date format detection may differ from Python's dateutil

[1.0.0]: https://github.com/yourusername/SwiftDateParser/releases/tag/v1.0.0