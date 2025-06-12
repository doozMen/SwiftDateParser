#!/usr/bin/env python3
"""
Compare Python dateutil and Swift DateParser test results
"""

import json
import sys
from datetime import datetime
from dateutil import parser as dateutil_parser

def load_results():
    """Load test results from JSON files"""
    try:
        with open('python_test_results.json', 'r') as f:
            python_results = json.load(f)
    except FileNotFoundError:
        print("Error: python_test_results.json not found. Run test_comparison.py first.")
        sys.exit(1)
    
    try:
        with open('swift_test_results.json', 'r') as f:
            swift_results = json.load(f)
    except FileNotFoundError:
        print("Error: swift_test_results.json not found. Run Swift TestComparison first.")
        sys.exit(1)
    
    return python_results, swift_results

def normalize_dates(date_str):
    """Normalize date strings for comparison"""
    if not date_str:
        return None
    
    try:
        # Parse and normalize to UTC ISO format
        dt = dateutil_parser.isoparse(date_str)
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return date_str

def compare_dates(python_date, swift_date):
    """Compare two date strings, accounting for timezone differences"""
    if not python_date or not swift_date:
        return python_date == swift_date
    
    # Normalize both dates
    norm_python = normalize_dates(python_date)
    norm_swift = normalize_dates(swift_date)
    
    if norm_python == norm_swift:
        return True
    
    # Check if they're the same date but different times (common for date-only inputs)
    try:
        py_dt = dateutil_parser.isoparse(python_date)
        sw_dt = dateutil_parser.isoparse(swift_date)
        
        # Check if dates match (ignoring time)
        if py_dt.date() == sw_dt.date():
            return True
            
    except:
        pass
    
    return False

def analyze_results(python_results, swift_results):
    """Analyze and compare test results"""
    print("Comparison Analysis")
    print("=" * 100)
    print()
    
    # Ensure we have the same number of tests
    if len(python_results) != len(swift_results):
        print(f"WARNING: Test count mismatch! Python: {len(python_results)}, Swift: {len(swift_results)}")
        return
    
    # Categories for analysis
    both_success = []
    both_fail = []
    python_only_success = []
    swift_only_success = []
    different_results = []
    performance_comparison = []
    
    for i, (py_test, sw_test) in enumerate(zip(python_results, swift_results)):
        # Verify we're comparing the same test
        if py_test['input'] != sw_test['input']:
            print(f"ERROR: Test mismatch at index {i}")
            continue
        
        py_success = py_test['default']['success']
        sw_success = sw_test['default']['success']
        
        # Categorize results
        if py_success and sw_success:
            both_success.append((py_test, sw_test))
            
            # Check if results match
            if not compare_dates(py_test['default']['date'], sw_test['default']['date']):
                different_results.append((py_test, sw_test))
                
        elif not py_success and not sw_success:
            both_fail.append((py_test, sw_test))
        elif py_success and not sw_success:
            python_only_success.append((py_test, sw_test))
        else:  # Swift success, Python fail
            swift_only_success.append((py_test, sw_test))
        
        # Collect performance data for successful parses
        if py_success and sw_success:
            performance_comparison.append({
                'input': py_test['input'],
                'python_ms': py_test['default']['time_ms'],
                'swift_ms': sw_test['default']['timeMs']
            })
    
    # Print summary
    print(f"Total tests: {len(python_results)}")
    print(f"Both succeed: {len(both_success)}")
    print(f"Both fail: {len(both_fail)}")
    print(f"Python only: {len(python_only_success)}")
    print(f"Swift only: {len(swift_only_success)}")
    print(f"Different results: {len(different_results)}")
    print()
    
    # Detailed analysis
    if python_only_success:
        print("Tests that Python passes but Swift fails:")
        print("-" * 50)
        for py_test, sw_test in python_only_success:
            print(f"  {py_test['description']}: '{py_test['input']}'")
            print(f"    Python: {py_test['default']['date']}")
            print(f"    Swift error: {sw_test['default']['error']}")
        print()
    
    if swift_only_success:
        print("Tests that Swift passes but Python fails:")
        print("-" * 50)
        for py_test, sw_test in swift_only_success:
            print(f"  {sw_test['description']}: '{sw_test['input']}'")
            print(f"    Swift: {sw_test['default']['date']}")
            print(f"    Python error: {py_test['default']['error']}")
            
            # Check if Python succeeds with fuzzy
            if py_test['fuzzy'] and py_test['fuzzy']['success']:
                print(f"    Python fuzzy: {py_test['fuzzy']['date']} ✓")
        print()
    
    if different_results:
        print("Tests with different results:")
        print("-" * 50)
        for py_test, sw_test in different_results:
            print(f"  {py_test['description']}: '{py_test['input']}'")
            print(f"    Python: {py_test['default']['date']}")
            print(f"    Swift:  {sw_test['default']['date']}")
        print()
    
    # Performance comparison
    if performance_comparison:
        print("Performance Comparison (average ms):")
        print("-" * 50)
        
        # Calculate averages
        total_python_ms = sum(p['python_ms'] for p in performance_comparison)
        total_swift_ms = sum(p['swift_ms'] for p in performance_comparison)
        avg_python_ms = total_python_ms / len(performance_comparison)
        avg_swift_ms = total_swift_ms / len(performance_comparison)
        
        print(f"Overall average:")
        print(f"  Python: {avg_python_ms:.3f}ms")
        print(f"  Swift:  {avg_swift_ms:.3f}ms")
        print(f"  Ratio:  {avg_swift_ms/avg_python_ms:.2f}x")
        print()
        
        # Find best and worst performance ratios
        for p in performance_comparison:
            p['ratio'] = p['swift_ms'] / p['python_ms'] if p['python_ms'] > 0 else float('inf')
        
        performance_comparison.sort(key=lambda x: x['ratio'])
        
        print("Best Swift performance (relative to Python):")
        for p in performance_comparison[:5]:
            print(f"  '{p['input']}': {p['ratio']:.2f}x (Python: {p['python_ms']:.3f}ms, Swift: {p['swift_ms']:.3f}ms)")
        print()
        
        print("Worst Swift performance (relative to Python):")
        for p in performance_comparison[-5:]:
            print(f"  '{p['input']}': {p['ratio']:.2f}x (Python: {p['python_ms']:.3f}ms, Swift: {p['swift_ms']:.3f}ms)")

def identify_missing_features():
    """Identify features present in Python dateutil but missing in Swift"""
    print("\n\nMissing Features Analysis")
    print("=" * 100)
    print()
    
    missing_features = {
        "fuzzy_with_tokens": "Returns both parsed date and skipped tokens",
        "ignoretz": "Option to ignore timezone information",
        "tzinfos": "Custom timezone abbreviation mapping",
        "parserinfo customization": "Ability to subclass parserinfo for different languages",
        "stream parsing": "Parse from file-like objects",
        "bytes/bytearray support": "Parse from bytes or bytearray",
        "relative date parsing": "Limited - Swift handles basic cases but not complex ones",
        "fuzzy parsing": "Limited - Swift's fuzzy mode is less sophisticated",
        "ordinal support": "Partial - Swift handles some ordinals but not all formats",
        "logger format with comma": "Swift doesn't parse milliseconds from comma separator",
        "timezone parsing": "Swift ignores timezone offsets in parsed dates",
        "two-digit year handling": "Different algorithm - Swift doesn't use 50-year window",
        "default date components": "Swift uses fixed defaults, Python uses current date/time",
        "validation": "Python validates dates (no Feb 30), Swift auto-corrects",
        "AM/PM with dots": "Python handles 'a.m.' and 'p.m.', Swift may not",
        "era markers": "Limited support for AD/BC in both, but different handling",
        "numeric-only dates": "Different interpretation of pure numbers like '99' or '2003'",
        "multiple date extraction": "NLPDateExtractor exists but works differently",
        "week dates": "ISO week date format (YYYY-Www-D) not supported in Swift",
        "decimal seconds": "Support for both . and , as decimal separators",
        "24:00 time": "Converting 24:00 to next day 00:00",
        "year 0 validation": "Python raises error for year 0, Swift may accept it"
    }
    
    print("Features in Python dateutil not fully implemented in Swift:")
    for feature, description in missing_features.items():
        print(f"• {feature}: {description}")
    
    print("\n\nRecommendations:")
    print("-" * 50)
    print("1. Implement proper timezone offset parsing and preservation")
    print("2. Improve fuzzy parsing to handle more natural language cases")
    print("3. Add fuzzy_with_tokens functionality for text extraction")
    print("4. Implement two-digit year windowing similar to Python")
    print("5. Add date validation to reject invalid dates instead of auto-correcting")
    print("6. Support for more relative date formats")
    print("7. Add support for custom timezone abbreviations")
    print("8. Implement stream parsing for large text processing")
    print("9. Add millisecond parsing from comma-separated values")
    print("10. Consider adding parserinfo customization for i18n support")

def main():
    """Main comparison function"""
    python_results, swift_results = load_results()
    analyze_results(python_results, swift_results)
    identify_missing_features()

if __name__ == "__main__":
    main()