# Security Policy

## Supported Versions

Currently supported versions of SwiftDateParser:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within SwiftDateParser, please follow these steps:

1. **Do not** open a public issue
2. Email the details to the repository maintainer through GitHub
3. Include the following information:
   - Type of vulnerability
   - Full paths of source file(s) related to the vulnerability
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact of the vulnerability

## Security Considerations

When using SwiftDateParser:

- Be cautious when parsing user-provided date strings, especially in security-sensitive contexts
- The fuzzy parsing feature may extract unexpected dates from text
- Date parsing does not validate the semantic meaning of dates (e.g., future dates in past-only contexts)
- Consider implementing additional validation for your specific use case

## Response Timeline

- Acknowledgment of report: Within 48 hours
- Initial assessment: Within 1 week
- Resolution timeline will depend on severity and complexity