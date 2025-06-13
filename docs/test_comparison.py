#!/usr/bin/env python3
"""
Date Parser Comparison Test Suite
Compares Python dateutil with Swift DateParser implementation
"""

import sys
import time
import json
from datetime import datetime
from dateutil import parser as dateutil_parser
from dateutil.parser import ParserError

# Test scenarios covering various date formats and edge cases
TEST_SCENARIOS = [
    # ISO Formats
    ("2003-09-25T10:49:41", "ISO datetime with T separator"),
    ("2003-09-25 10:49:41", "ISO datetime with space separator"),
    ("2003-09-25", "ISO date only"),
    ("20030925T104941", "Compact ISO datetime"),
    ("20030925", "Compact ISO date"),
    
    # Common Date Formats
    ("09/25/2003", "US format MM/DD/YYYY"),
    ("25/09/2003", "EU format DD/MM/YYYY"),
    ("09-25-2003", "US format with dashes"),
    ("25-09-2003", "EU format with dashes"),
    ("09.25.2003", "US format with dots"),
    ("25.09.2003", "EU format with dots"),
    ("2003/09/25", "Year first with slashes"),
    
    # Short Date Formats
    ("10/09/03", "Short date - ambiguous"),
    ("10-09-03", "Short date with dashes"),
    ("10.09.03", "Short date with dots"),
    
    # Month Names
    ("Sep 25 2003", "Month abbreviation"),
    ("September 25, 2003", "Full month name with comma"),
    ("25 Sep 2003", "Day first with month name"),
    ("3rd of May 2001", "Ordinal date"),
    ("May 3rd, 2001", "Ordinal date US style"),
    
    # Time Formats
    ("10:36:28", "Time only HH:MM:SS"),
    ("10:36", "Time only HH:MM"),
    ("10:36:28 PM", "Time with PM"),
    ("10:36:28 AM", "Time with AM"),
    ("22:36:28", "24-hour time"),
    
    # Complex Formats
    ("Thu Sep 25 10:36:28 2003", "Unix date format"),
    ("Wed, July 10, '96", "Abbreviated year with apostrophe"),
    ("1996.July.10 AD 12:08 PM", "Complex format with AD"),
    ("2003-09-25 10:49:41,502", "Logger format with milliseconds"),
    
    # Apostrophe Year Formats
    ("July 10, '96", "Apostrophe year without day name"),
    ("'96-07-10", "Apostrophe year ISO style"),
    ("10-Jul-'96", "Apostrophe year with month abbreviation"),
    ("December 25 '99", "Apostrophe year end of string"),
    
    # AD/BC Formats
    ("753 BC", "BC year only"),
    ("2023 CE", "CE year"),
    ("1 AD", "Year 1 AD"),
    ("December 31, 1 BC", "Date with BC"),
    ("1996.July.10 AD", "AD date without time"),
    ("44 BC", "Julius Caesar's death year"),
    
    # Relative Dates
    ("today", "Relative - today"),
    ("tomorrow", "Relative - tomorrow"),
    ("yesterday", "Relative - yesterday"),
    ("3 days ago", "Relative - days ago"),
    ("in 2 weeks", "Relative - in weeks"),
    ("next month", "Relative - next month"),
    ("last year", "Relative - last year"),
    
    # Edge Cases
    ("", "Empty string"),
    ("not a date", "Invalid text"),
    ("2003-02-29", "Invalid date - not leap year"),
    ("2004-02-29", "Valid leap year date"),
    ("2003-09-31", "Invalid date - September has 30 days"),
    ("99", "Two digit number"),
    ("10", "Two digit number"),
    ("2003", "Year only"),
    
    # Fuzzy Parsing Cases
    ("Today is January 1, 2047 at 8:21:00AM", "Fuzzy - date in sentence"),
    ("The deadline is 2023-12-25", "Fuzzy - date at end"),
    ("On Sep 25 2003 something happened", "Fuzzy - date in middle"),
    
    # Special Characters
    ("2003/09/25", "Forward slashes"),
    ("2003\\09\\25", "Backslashes"),
    ("2003_09_25", "Underscores"),
    
    # Timezone Cases
    ("2003-09-25T10:49:41Z", "ISO with UTC timezone"),
    ("2003-09-25T10:49:41+05:00", "ISO with timezone offset"),
    ("2003-09-25T10:49:41-08:00", "ISO with negative timezone offset"),
]

def parse_with_dateutil(date_string, fuzzy=False, dayfirst=False, yearfirst=False):
    """Parse date using Python dateutil"""
    try:
        start_time = time.time()
        result = dateutil_parser.parse(date_string, fuzzy=fuzzy, dayfirst=dayfirst, yearfirst=yearfirst)
        end_time = time.time()
        
        return {
            "success": True,
            "date": result.isoformat(),
            "time_ms": (end_time - start_time) * 1000,
            "error": None
        }
    except (ParserError, ValueError, OverflowError) as e:
        return {
            "success": False,
            "date": None,
            "time_ms": 0,
            "error": str(e)
        }

def run_python_tests():
    """Run all test scenarios through Python dateutil"""
    results = []
    
    print("Running Python dateutil tests...")
    print("-" * 80)
    
    for date_string, description in TEST_SCENARIOS:
        # Test with default settings
        result = parse_with_dateutil(date_string)
        
        # Test with fuzzy parsing for certain cases
        fuzzy_result = None
        if not result["success"] and date_string:
            fuzzy_result = parse_with_dateutil(date_string, fuzzy=True)
        
        # Test with dayfirst for ambiguous dates
        dayfirst_result = None
        if "/" in date_string or "-" in date_string or "." in date_string:
            dayfirst_result = parse_with_dateutil(date_string, dayfirst=True)
        
        test_result = {
            "input": date_string,
            "description": description,
            "default": result,
            "fuzzy": fuzzy_result,
            "dayfirst": dayfirst_result
        }
        
        results.append(test_result)
        
        # Print summary
        status = "✓" if result["success"] else "✗"
        print(f"{status} {description:<40} | Input: '{date_string}'")
        if result["success"]:
            print(f"  → {result['date']} ({result['time_ms']:.2f}ms)")
        else:
            print(f"  → Error: {result['error']}")
        
        if fuzzy_result and fuzzy_result["success"]:
            print(f"  → Fuzzy: {fuzzy_result['date']}")
        
        if dayfirst_result and dayfirst_result["date"] != result["date"]:
            print(f"  → Dayfirst: {dayfirst_result['date']}")
        
        print()
    
    return results

def run_performance_test():
    """Run performance benchmarks"""
    print("\nPerformance Benchmarks")
    print("-" * 80)
    
    # Common date formats for performance testing
    perf_scenarios = [
        "2023-12-25",
        "12/25/2023",
        "December 25, 2023",
        "2023-12-25T10:30:00",
        "tomorrow",
        "3 days ago"
    ]
    
    iterations = 1000
    
    for date_string in perf_scenarios:
        start_time = time.time()
        
        for _ in range(iterations):
            try:
                dateutil_parser.parse(date_string)
            except:
                pass
        
        end_time = time.time()
        total_time = (end_time - start_time) * 1000
        avg_time = total_time / iterations
        
        print(f"{date_string:<25} | Total: {total_time:.2f}ms | Avg: {avg_time:.3f}ms")

def main():
    """Main test runner"""
    print("Python dateutil Test Suite")
    print("=" * 80)
    print(f"Python version: {sys.version}")
    print(f"dateutil version: {dateutil_parser.__version__ if hasattr(dateutil_parser, '__version__') else 'Unknown'}")
    print("=" * 80)
    print()
    
    # Run comprehensive tests
    results = run_python_tests()
    
    # Run performance tests
    run_performance_test()
    
    # Save results to JSON for comparison
    with open('python_test_results.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print("\nResults saved to python_test_results.json")
    
    # Summary statistics
    total = len(results)
    successful = sum(1 for r in results if r["default"]["success"])
    fuzzy_success = sum(1 for r in results if r["fuzzy"] and r["fuzzy"]["success"])
    
    print(f"\nSummary:")
    print(f"Total tests: {total}")
    print(f"Successful (default): {successful} ({successful/total*100:.1f}%)")
    print(f"Additional fuzzy successes: {fuzzy_success}")

if __name__ == "__main__":
    main()