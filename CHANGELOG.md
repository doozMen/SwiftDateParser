# Changelog

All notable changes to SwiftDateParser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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