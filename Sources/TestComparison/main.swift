import Foundation
import SwiftDateParser

struct TestScenario {
    let input: String
    let description: String
}

struct TestResult: Codable {
    let input: String
    let description: String
    let `default`: ParseResult
    let fuzzy: ParseResult?
    let dayfirst: ParseResult?
}

struct ParseResult: Codable {
    let success: Bool
    let date: String?
    let timeMs: Double
    let error: String?
}

// Test scenarios matching Python test suite
let testScenarios: [TestScenario] = [
    // ISO Formats
    TestScenario(input: "2003-09-25T10:49:41", description: "ISO datetime with T separator"),
    TestScenario(input: "2003-09-25 10:49:41", description: "ISO datetime with space separator"),
    TestScenario(input: "2003-09-25", description: "ISO date only"),
    TestScenario(input: "20030925T104941", description: "Compact ISO datetime"),
    TestScenario(input: "20030925", description: "Compact ISO date"),
    
    // Common Date Formats
    TestScenario(input: "09/25/2003", description: "US format MM/DD/YYYY"),
    TestScenario(input: "25/09/2003", description: "EU format DD/MM/YYYY"),
    TestScenario(input: "09-25-2003", description: "US format with dashes"),
    TestScenario(input: "25-09-2003", description: "EU format with dashes"),
    TestScenario(input: "09.25.2003", description: "US format with dots"),
    TestScenario(input: "25.09.2003", description: "EU format with dots"),
    TestScenario(input: "2003/09/25", description: "Year first with slashes"),
    
    // Short Date Formats
    TestScenario(input: "10/09/03", description: "Short date - ambiguous"),
    TestScenario(input: "10-09-03", description: "Short date with dashes"),
    TestScenario(input: "10.09.03", description: "Short date with dots"),
    
    // Month Names
    TestScenario(input: "Sep 25 2003", description: "Month abbreviation"),
    TestScenario(input: "September 25, 2003", description: "Full month name with comma"),
    TestScenario(input: "25 Sep 2003", description: "Day first with month name"),
    TestScenario(input: "3rd of May 2001", description: "Ordinal date"),
    TestScenario(input: "May 3rd, 2001", description: "Ordinal date US style"),
    
    // Time Formats
    TestScenario(input: "10:36:28", description: "Time only HH:MM:SS"),
    TestScenario(input: "10:36", description: "Time only HH:MM"),
    TestScenario(input: "10:36:28 PM", description: "Time with PM"),
    TestScenario(input: "10:36:28 AM", description: "Time with AM"),
    TestScenario(input: "22:36:28", description: "24-hour time"),
    
    // Complex Formats
    TestScenario(input: "Thu Sep 25 10:36:28 2003", description: "Unix date format"),
    TestScenario(input: "Wed, July 10, '96", description: "Abbreviated year with apostrophe"),
    TestScenario(input: "1996.July.10 AD 12:08 PM", description: "Complex format with AD"),
    TestScenario(input: "2003-09-25 10:49:41,502", description: "Logger format with milliseconds"),
    
    // Apostrophe Year Formats
    TestScenario(input: "July 10, '96", description: "Apostrophe year without day name"),
    TestScenario(input: "'96-07-10", description: "Apostrophe year ISO style"),
    TestScenario(input: "10-Jul-'96", description: "Apostrophe year with month abbreviation"),
    TestScenario(input: "December 25 '99", description: "Apostrophe year end of string"),
    
    // AD/BC Formats
    TestScenario(input: "753 BC", description: "BC year only"),
    TestScenario(input: "2023 CE", description: "CE year"),
    TestScenario(input: "1 AD", description: "Year 1 AD"),
    TestScenario(input: "December 31, 1 BC", description: "Date with BC"),
    TestScenario(input: "1996.July.10 AD", description: "AD date without time"),
    TestScenario(input: "44 BC", description: "Julius Caesar's death year"),
    
    // Relative Dates
    TestScenario(input: "today", description: "Relative - today"),
    TestScenario(input: "tomorrow", description: "Relative - tomorrow"),
    TestScenario(input: "yesterday", description: "Relative - yesterday"),
    TestScenario(input: "3 days ago", description: "Relative - days ago"),
    TestScenario(input: "in 2 weeks", description: "Relative - in weeks"),
    TestScenario(input: "next month", description: "Relative - next month"),
    TestScenario(input: "last year", description: "Relative - last year"),
    
    // Edge Cases
    TestScenario(input: "", description: "Empty string"),
    TestScenario(input: "not a date", description: "Invalid text"),
    TestScenario(input: "2003-02-29", description: "Invalid date - not leap year"),
    TestScenario(input: "2004-02-29", description: "Valid leap year date"),
    TestScenario(input: "2003-09-31", description: "Invalid date - September has 30 days"),
    TestScenario(input: "99", description: "Two digit number"),
    TestScenario(input: "10", description: "Two digit number"),
    TestScenario(input: "2003", description: "Year only"),
    
    // Fuzzy Parsing Cases
    TestScenario(input: "Today is January 1, 2047 at 8:21:00AM", description: "Fuzzy - date in sentence"),
    TestScenario(input: "The deadline is 2023-12-25", description: "Fuzzy - date at end"),
    TestScenario(input: "On Sep 25 2003 something happened", description: "Fuzzy - date in middle"),
    
    // Special Characters
    TestScenario(input: "2003/09/25", description: "Forward slashes"),
    TestScenario(input: "2003\\09\\25", description: "Backslashes"),
    TestScenario(input: "2003_09_25", description: "Underscores"),
    
    // Timezone Cases
    TestScenario(input: "2003-09-25T10:49:41Z", description: "ISO with UTC timezone"),
    TestScenario(input: "2003-09-25T10:49:41+05:00", description: "ISO with timezone offset"),
    TestScenario(input: "2003-09-25T10:49:41-08:00", description: "ISO with negative timezone offset"),
]

func parseWithSwiftDateParser(_ dateString: String, fuzzy: Bool = false, dayfirst: Bool = false, yearfirst: Bool = false, validateDates: Bool = false) -> ParseResult {
    let startTime = Date()
    
    do {
        let parser = SwiftDateParser.createParser(
            dayfirst: dayfirst,
            yearfirst: yearfirst,
            fuzzy: fuzzy,
            validateDates: validateDates
        )
        let date = try parser.parse(dateString)
        let endTime = Date()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return ParseResult(
            success: true,
            date: formatter.string(from: date),
            timeMs: endTime.timeIntervalSince(startTime) * 1000,
            error: nil
        )
    } catch {
        return ParseResult(
            success: false,
            date: nil,
            timeMs: 0,
            error: error.localizedDescription
        )
    }
}

func runSwiftTests() -> [TestResult] {
    print("Running SwiftDateParser tests...")
    print(String(repeating: "-", count: 80))
    
    var results: [TestResult] = []
    
    for scenario in testScenarios {
        // Test with default settings
        let defaultResult = parseWithSwiftDateParser(scenario.input)
        
        // Test with fuzzy parsing for certain cases
        var fuzzyResult: ParseResult? = nil
        if !defaultResult.success && !scenario.input.isEmpty {
            fuzzyResult = parseWithSwiftDateParser(scenario.input, fuzzy: true)
        }
        
        // Test with dayfirst for ambiguous dates
        var dayfirstResult: ParseResult? = nil
        if scenario.input.contains("/") || scenario.input.contains("-") || scenario.input.contains(".") {
            dayfirstResult = parseWithSwiftDateParser(scenario.input, dayfirst: true)
        }
        
        // Test with validation for dates that should fail
        var validationResult: ParseResult? = nil
        if scenario.description.contains("Invalid date") {
            validationResult = parseWithSwiftDateParser(scenario.input, validateDates: true)
        }
        
        // For invalid dates, use validation result as default if enabled
        let finalDefaultResult = (scenario.description.contains("Invalid date") && validationResult != nil) ? validationResult! : defaultResult
        
        let testResult = TestResult(
            input: scenario.input,
            description: scenario.description,
            default: finalDefaultResult,
            fuzzy: fuzzyResult,
            dayfirst: dayfirstResult
        )
        
        results.append(testResult)
        
        // Print summary
        let status = finalDefaultResult.success ? "✓" : "✗"
        print("\(status) \(scenario.description.padding(toLength: 40, withPad: " ", startingAt: 0)) | Input: '\(scenario.input)'")
        if finalDefaultResult.success {
            print("  → \(finalDefaultResult.date!) (\(String(format: "%.2f", finalDefaultResult.timeMs))ms)")
        } else {
            print("  → Error: \(finalDefaultResult.error!)")
        }
        
        if let fuzzy = fuzzyResult, fuzzy.success {
            print("  → Fuzzy: \(fuzzy.date!)")
        }
        
        if let dayfirst = dayfirstResult, dayfirst.date != defaultResult.date {
            print("  → Dayfirst: \(dayfirst.date!)")
        }
        
        print()
    }
    
    return results
}

func runPerformanceTest() {
    print("\nPerformance Benchmarks")
    print(String(repeating: "-", count: 80))
    
    let perfScenarios = [
        "2023-12-25",
        "12/25/2023",
        "December 25, 2023",
        "2023-12-25T10:30:00",
        "tomorrow",
        "3 days ago"
    ]
    
    let iterations = 1000
    
    for dateString in perfScenarios {
        let parser = SwiftDateParser.createParser()
        let startTime = Date()
        
        for _ in 0..<iterations {
            _ = try? parser.parse(dateString)
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime) * 1000
        let avgTime = totalTime / Double(iterations)
        
        print("\(dateString.padding(toLength: 25, withPad: " ", startingAt: 0)) | Total: \(String(format: "%.2f", totalTime))ms | Avg: \(String(format: "%.3f", avgTime))ms")
    }
}

// Main execution
print("SwiftDateParser Test Suite")
print(String(repeating: "=", count: 80))
print("Swift version: \(#file)")
print("SwiftDateParser version: \(SwiftDateParser.version)")
print(String(repeating: "=", count: 80))
print()

// Run comprehensive tests
let results = runSwiftTests()

// Run performance tests
runPerformanceTest()

// Save results to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

if let jsonData = try? encoder.encode(results),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    let url = URL(fileURLWithPath: "swift_test_results.json")
    try? jsonString.write(to: url, atomically: true, encoding: .utf8)
    print("\nResults saved to swift_test_results.json")
}

// Summary statistics
let total = results.count
let successful = results.filter { $0.default.success }.count
let fuzzySuccess = results.compactMap { $0.fuzzy }.filter { $0.success }.count

print("\nSummary:")
print("Total tests: \(total)")
print("Successful (default): \(successful) (\(String(format: "%.1f", Double(successful) / Double(total) * 100))%)")
print("Additional fuzzy successes: \(fuzzySuccess)")