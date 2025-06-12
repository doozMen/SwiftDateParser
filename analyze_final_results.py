#!/usr/bin/env python3
import json
from statistics import mean, median

# Load results
with open('python_test_results_final.json', 'r') as f:
    python_results = json.load(f)

with open('swift_test_results_final.json', 'r') as f:
    swift_results = json.load(f)

# Analyze results
total_tests = len(swift_results)
swift_passed = 0
python_passed = 0
both_passed = 0
swift_only = 0
python_only = 0
performance_ratios = []

for i, (swift_test, python_test) in enumerate(zip(swift_results, python_results)):
    # Check default mode success
    swift_success = swift_test['default']['success']
    python_success = python_test['default']['success']
    
    if swift_success:
        swift_passed += 1
    if python_success:
        python_passed += 1
    if swift_success and python_success:
        both_passed += 1
        # Calculate performance ratio
        swift_time = swift_test['default']['timeMs']
        python_time = python_test['default']['timeMs']
        if python_time > 0 and swift_time > 0:
            ratio = swift_time / python_time
            performance_ratios.append(ratio)
    if swift_success and not python_success:
        swift_only += 1
    if python_success and not swift_success:
        python_only += 1

# Check fuzzy mode
swift_fuzzy_passed = 0
python_fuzzy_passed = 0

for swift_test, python_test in zip(swift_results, python_results):
    if 'fuzzy' in swift_test and swift_test['fuzzy']['success']:
        swift_fuzzy_passed += 1
    if 'fuzzy' in python_test and python_test['fuzzy']['success']:
        python_fuzzy_passed += 1

print(f"Total test cases: {total_tests}")
print(f"\nDefault mode:")
print(f"  Swift passed: {swift_passed}/{total_tests} ({swift_passed/total_tests*100:.1f}%)")
print(f"  Python passed: {python_passed}/{total_tests} ({python_passed/total_tests*100:.1f}%)")
print(f"  Both passed: {both_passed}/{total_tests} ({both_passed/total_tests*100:.1f}%)")
print(f"  Swift only: {swift_only}")
print(f"  Python only: {python_only}")

print(f"\nWith fuzzy mode:")
total_swift = swift_passed + swift_fuzzy_passed
total_python = python_passed + python_fuzzy_passed
print(f"  Swift total: {total_swift}/{total_tests} ({total_swift/total_tests*100:.1f}%)")
print(f"  Python total: {total_python}/{total_tests} ({total_python/total_tests*100:.1f}%)")

if performance_ratios:
    print(f"\nPerformance (for tests both passed):")
    print(f"  Average ratio: {mean(performance_ratios):.2f}x")
    print(f"  Median ratio: {median(performance_ratios):.2f}x")
    print(f"  Best ratio: {min(performance_ratios):.2f}x (Swift faster)")
    print(f"  Worst ratio: {max(performance_ratios):.2f}x")

# Find Swift-exclusive features
print("\n## Swift-exclusive successes:")
for i, (swift_test, python_test) in enumerate(zip(swift_results, python_results)):
    if swift_test['default']['success'] and not python_test['default']['success']:
        print(f"  - {swift_test['description']}: {swift_test['input']}")