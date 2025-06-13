# Contributing to SwiftDateParser

Thank you for your interest in contributing to SwiftDateParser! This Swift port of Python's dateutil parser welcomes contributions from the community.

## How to Contribute

### Reporting Issues

- Check if the issue already exists in the [issue tracker](https://github.com/yourusername/SwiftDateParser/issues)
- Include a clear description of the problem
- Provide a minimal code example that reproduces the issue
- Include your Swift version and platform information

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add or update tests as needed
5. Ensure all tests pass (`swift test`)
6. Commit your changes with clear messages
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/SwiftDateParser.git
cd SwiftDateParser

# Build the package
swift build

# Run tests
swift test

# Run tests with verbose output
swift test --verbose
```

### Code Style

- Follow Swift naming conventions
- Use clear, descriptive variable and function names
- Add documentation comments for public APIs
- Keep functions focused and concise
- Use Swift's type system effectively

### Testing

- All new functionality should include tests
- Tests use Swift Testing framework (not XCTest)
- Use `@Test` attributes for test functions
- Use `#expect` for assertions
- Group related tests with `@Suite`

### Areas for Contribution

We especially welcome contributions in these areas:

1. **Additional Date Formats**: Support for more date formats and locales
2. **Timezone Support**: Enhanced timezone parsing and handling
3. **Performance Improvements**: Optimizations for parsing speed
4. **Documentation**: Improvements to code documentation and examples
5. **Test Coverage**: Additional test cases for edge cases
6. **Python Compatibility**: Closer alignment with Python dateutil behavior

### Questions?

Feel free to open an issue for any questions about contributing!