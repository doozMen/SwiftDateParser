# Repository Cleanup Plan for SwiftDateParser

## Overview
This document outlines the comprehensive cleanup tasks to be performed on the SwiftDateParser repository to improve organization, documentation, and maintainability.

## Cleanup Tasks

### 1. Update .gitignore
- [ ] Add Python-related ignores for scripts in docs/
  ```
  __pycache__/
  *.pyc
  *.pyo
  *.pyd
  .Python
  *.egg-info/
  .pytest_cache/
  venv/
  env/
  .env
  ```
- [ ] Add .vscode/ to gitignore
- [ ] Add any other common development artifacts

### 2. Update CHANGELOG.md
- [ ] Add entry for comprehensive test suite (69 tests across 7 suites)
- [ ] Document addition of DateParser2, DateParser3, and DateParserError
- [ ] Note legacy compatibility layers (DateParser, NLPDateExtractor)
- [ ] Record repository reorganization (docs/ folder creation)
- [ ] Update version to 1.1.0 or appropriate

### 3. Handle .vscode folder
- [ ] Remove .vscode/ from repository
- [ ] Add .vscode/ to .gitignore
- [ ] Optionally create .vscode.example/ in docs/ with useful configurations

### 4. Update Package.swift
- [ ] Add comprehensive package description
- [ ] Add keywords for Swift Package Index discoverability
- [ ] Verify minimum platform versions match actual requirements
- [ ] Consider adding package plugins if applicable

### 5. Enhance GitHub Actions
- [ ] Add code coverage reporting to CI pipeline
- [ ] Integrate SwiftLint into GitHub Actions
- [ ] Set up automatic release creation on tags
- [ ] Add matrix testing for different Swift versions
- [ ] Add badge generation for README

### 6. Improve Documentation
- [ ] Add comprehensive doc comments to all public APIs
- [ ] Generate DocC documentation
- [ ] Add inline code examples
- [ ] Document performance characteristics
- [ ] Create API migration guide for different parser versions

### 7. Add Repository Files
- [ ] Create `.swiftformat` configuration for consistent formatting
- [ ] Add `SECURITY.md` with security policy
- [ ] Create `CODE_OF_CONDUCT.md`
- [ ] Add `.github/PULL_REQUEST_TEMPLATE.md`
- [ ] Create issue templates:
  - `.github/ISSUE_TEMPLATE/bug_report.md`
  - `.github/ISSUE_TEMPLATE/feature_request.md`
  - `.github/ISSUE_TEMPLATE/config.yml`

### 8. Fix Test Issues
- [ ] Fix failing tests or document known issues:
  - AD/BC date calculations
  - Relative dates like "next Monday"
  - Timezone parsing
  - Performance benchmarks
- [ ] Remove trivial always-passing tests (Bool(true))
- [ ] Improve test names for better clarity
- [ ] Add test coverage reporting

### 9. Performance Documentation
- [ ] Create performance comparison between DateParser2 and DateParser3
- [ ] Document when to use each parser version
- [ ] Update README performance claims to match actual benchmarks
- [ ] Consider making DateParser3 default if stable enough

### 10. README Enhancements
- [ ] Add badges:
  - Build status
  - Swift version
  - Platform support
  - License
  - Swift Package Index
- [ ] Update performance claims with actual measurements
- [ ] Add installation instructions for:
  - CocoaPods (if applicable)
  - Carthage (if applicable)
  - Manual installation
- [ ] Update examples to show both parser versions
- [ ] Add troubleshooting section
- [ ] Credit all contributors properly

### 11. Code Quality Improvements
- [ ] Run SwiftLint and fix all warnings
- [ ] Run SwiftFormat for consistent code style
- [ ] Remove any commented-out code
- [ ] Ensure all TODOs are tracked as issues
- [ ] Add @available annotations where needed

### 12. Release Preparation
- [ ] Tag current version appropriately
- [ ] Create GitHub release with comprehensive notes
- [ ] Submit to Swift Package Index
- [ ] Consider creating a demo app/playground

## Priority Order

1. **Critical** (Do First):
   - Update .gitignore
   - Fix failing tests or document why they fail
   - Update CHANGELOG.md
   - Remove .vscode folder

2. **Important** (Do Second):
   - Update README with accurate information
   - Add comprehensive API documentation
   - Enhance GitHub Actions

3. **Nice to Have** (Do Last):
   - Add repository files (SECURITY.md, etc.)
   - Create performance documentation
   - Set up automatic releases

## Estimated Time
- Total cleanup time: 2-3 hours
- Can be done incrementally

## Success Criteria
- [ ] All tests pass or have documented reasons for failure
- [ ] Repository follows Swift best practices
- [ ] Documentation is comprehensive and accurate
- [ ] CI/CD pipeline is robust
- [ ] Project is ready for wider adoption