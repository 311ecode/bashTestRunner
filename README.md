# bashTestRunner - Bash Test Framework

## Overview
bashTestRunner is a lightweight test framework for Bash scripts that provides test organization, execution, and reporting capabilities. It supports both regular and ignored tests, detailed reporting, and proper exit status handling.

## Basic Usage

### Running Test Suites
To run a test suite, you need to:
1. Define test functions (prefixed with `test`)
2. Create arrays of test functions and ignored tests
3. Call `bashTestRunner` with these arrays and optional command line options

```bash
bashTestRunner [options] <test_functions_array> <ignored_tests_array>
```

Parameters:
- `[options]`: Optional command line options (see Command Line Options below)
- `<test_functions_array>`: Name of an array variable containing all test functions to run
- `<ignored_tests_array>`: Name of an array variable containing tests to ignore

The function will append all output to a log file, display it in real-time via tail (for top-level runs), print the path to the session directory and main log file at the end for top-level runs, and return the status code.

To view the results later:
```bash
cat "/path/to/session/main.log"
```

Example:
```bash
source bashTestRunner.sh

myTests=("test1" "test2")
ignored=("test2")

bashTestRunner myTests ignored
```

## Command Line Options
- `-x, --exclude <tests>`: Space-separated list of additional tests to ignore (quoted if multiple). These are added to the ignored_tests_array. Example: `-x "test3 test4"`
- `-h, --help`: Display usage information and exit.

## Key Features

### Test Organization
- Tests are regular Bash functions prefixed with `test`
- Test suites are collections of these functions
- Ignored tests are excluded from failure counts

### Reporting
- Detailed summary of test results appended to the log file and displayed in real-time via tail
- Individual test status (PASS/FAIL/IGNORED)
- Execution time tracking
- Recommendations for passing ignored tests

### Exit Status Handling
- Returns 0 if all non-ignored tests pass
- Returns 1 if any non-ignored tests fail

## Advanced Usage

### Test Structure
Each test function should:
- Return 0 for success
- Return non-zero for failure
- Output any diagnostic information to stdout/stderr (will be captured in log and displayed in real-time)

Example test:
```bash
testExample() {
  [[ 1 -eq 1 ]]  # Simple assertion
  return $?      # Return the result
}
```

### Ignored Tests
Tests listed in the ignored array will:
- Still be executed
- Be marked as IGNORED in output
- Not affect the overall status code

### Nested Test Suites
bashTestRunner can handle nested test suites by:
- Preserving the calling environment
- Managing directory changes
- Isolating test function arrays
- Appending output to the top-level log file
- Real-time display handled by top-level tail process

## Included Test Suites

The framework includes several example test suites that demonstrate its capabilities:

1. `basicTestSuite.sh` - Simple passing/failing tests
2. `embeddedTestSuite.sh` - Tests that run other test suites
3. `failureStatusTestSuite.sh` - Verifies failure status codes
4. `ignoredFailureTestSuite.sh` - Tests ignored failure handling
5. `missingTestSuite.sh` - Verifies handling of missing test functions
6. `bashTestRunnerTrapTestSuite.sh` - Tests using trap in test functions
7. `logFilePathTestSuite.sh` - Verifies log file path reporting in nested calls
8. `nestedTestNamesSuite.sh` - Verifies nested test name display
9. `trapExitTestSuite.sh` - Tests using trap on EXIT in test functions
10. `excludeOptionTestSuite.sh` - Verifies the --exclude command line option

## Best Practices

1. Keep test functions small and focused
2. Use descriptive test names
3. Include setup/teardown logic within tests
4. Consider time-sensitive tests (sleeps are used in examples)
5. Use the provided metrics for test duration analysis

## Example Output

```
======================================
Starting test suite with 3 tests
(Plus 1 ignored tests)
======================================

Running test: testExample1
PASS: testExample1 completed in 0.123s
--------------------------------------

Running test: testExample2
(Note: This test will be ignored in final results)
IGNORED (FAIL): testExample2 completed in 0.456s
--------------------------------------

Running test: testExample3
PASS: testExample3 completed in 3.656s
--------------------------------------

======================================
TEST SUMMARY
======================================
Total tests: 3
Passed: 2
Failed: 0
Ignored tests: 1 (Passed: 0, Failed: 1)
Total time: 4.235s

Detailed results:
 - PASS: testExample1 (0.123s)
 - IGNORED (FAIL): testExample2 (0.456s)
 - PASS: testExample3 (3.656s)

Test functions:
 - testExample1 (0.123s)
 - testExample2 (0.456s)
 - testExample3 (3.656s)

FINAL STATUS:
PASS: All 2 tests passed successfully
======================================
Session directory: /tmp/bashTestRunnerSessions/XXXXXX
Main log file: /tmp/bashTestRunnerSessions/XXXXXX/main.log
```

## Dependencies
- Bash 4.0 or later (for associative arrays)
- Basic Unix utilities (date, bc, tail, etc.)