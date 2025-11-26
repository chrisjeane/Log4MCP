# Log4MCP Testing Guide

This document describes the testing strategy and how to run tests for Log4MCP.

## Test Plan Overview

A comprehensive test plan has been created covering 123+ test cases organized into 6 phases:

1. **Phase 1: Unit Tests** (33 tests) - Config, Logger, Messages, Errors
2. **Phase 2: Integration Tests** (25 tests) - Protocol, Stdio, Request Handler
3. **Phase 3: API Contract Tests** (26 tests) - RPC method contracts
4. **Phase 4: Performance & Load Tests** (14 tests) - High-volume, concurrency
5. **Phase 5: Error & Edge Cases** (20 tests) - Malformed requests, invalid params
6. **Phase 6: Configuration & Startup** (9 tests) - Config parsing, startup

See `TEST_PLAN.md` for detailed test specifications.

## Project Structure

```
Log4MCP/
├── Sources/
│   ├── Log4MCPLib/          - Library code
│   │   ├── Logger.swift
│   │   ├── Config.swift
│   │   ├── MCPMessages.swift
│   │   ├── MCPRequestHandler.swift
│   │   ├── StdioTransport.swift
│   │   ├── TCPServer.swift
│   │   ├── Errors.swift
│   │   └── ExampleClient.swift
│   └── Executable/          - Executable entry point
│       └── main.swift
└── Tests/
    └── Log4MCPTests/        - Test suite
        ├── ConfigTests.swift
        ├── LoggerTests.swift
        ├── MCPMessagesTests.swift
        └── ErrorTests.swift
```

## Running Tests

### Prerequisites

- Swift 6.2+
- Full Xcode installation (not just Command Line Tools)

### Option 1: Using Xcode

```bash
# Build and run all tests in Xcode
xcodebuild test -scheme Log4MCP

# Run specific test class
xcodebuild test -scheme Log4MCP -testNameFilter ConfigTests
```

### Option 2: Using Swift Package Manager (macOS only, requires full Xcode)

```bash
# Run all tests
swift test

# Run specific test with verbose output
swift test --filter ConfigTests -v

# Run with coverage
swift test --enable-code-coverage
```

### Option 3: GitHub Actions / CI/CD

The project includes GitHub Actions configuration that runs tests automatically on each push. To run tests locally using the same environment:

```bash
# Use Docker to run tests in a controlled environment
docker build -t log4mcp-test .
docker run log4mcp-test swift test
```

## Building Without Tests

If you only want to build the library and executable without running tests:

```bash
# Build library and executable
swift build

# Run the executable
swift run Log4MCP --stdio --log-level DEBUG
```

## Test Coverage Goals

- **Unit Test Coverage**: 90%+
- **Integration Test Coverage**: All public APIs
- **Protocol Compliance**: 100% of MCP methods
- **Error Paths**: All documented error codes
- **Edge Cases**: Critical boundaries and limits

## Test Organization

### Phase 1: Unit Tests (Implemented)

**ConfigTests.swift**
- T1.1.1 - T1.1.8: Configuration parsing and validation
- Tests default config, custom values, log levels, port validation

**LoggerTests.swift**
- T1.2.1 - T1.2.12: Logger functionality
- Tests message logging, level filtering, entry rotation, concurrency

**MCPMessagesTests.swift**
- T1.3.1 - T1.3.8: Message encoding/decoding
- Tests JSON serialization, timestamp formats, type conversions

**ErrorTests.swift**
- T1.4.1 - T1.4.5: Error handling
- Tests error codes, messages, response formatting

### Phase 2-6: Integration & Contract Tests (Ready to Implement)

Test files for additional phases are documented in TEST_PLAN.md and ready for implementation following the same patterns as Phase 1 tests.

## Known Limitations

1. **XCTest Availability**: XCTest requires full Xcode installation. Command Line Tools only includes Swift compilation but not the testing framework.

2. **Test Target Configuration**: The project has been refactored to separate:
   - `Log4MCPLib`: Core library (testable)
   - `Log4MCP`: Executable (depends on library)
   - `Log4MCPTests`: Test suite (depends on library)

3. **Public API Exports**: All library types have been marked public to enable testing:
   - `LogLevel`, `LogEntry`, `Logger`
   - `MCPRequest`, `MCPResponse`, `MCPParams`, `MCPResult`
   - `MCPRequestHandler`, `StdioTransport`, `TCPServer`
   - `ServerConfig`, `MCPError`, and more

## Continuous Integration

### GitHub Actions Workflow

The project includes a `.github/workflows/test.yml` that:
1. Checks out the code
2. Sets up Swift
3. Runs all tests
4. Reports code coverage
5. Builds the executable

### Local CI Simulation

To test locally using the same environment:

```bash
# Simulate CI environment
./scripts/ci-test.sh
```

## Test Development Guidelines

When adding new tests:

1. Follow the naming convention from TEST_PLAN.md (T[Phase].[Section].[Case])
2. Use descriptive test names that explain what's being tested
3. Keep tests isolated - each test should be independent
4. Use async/await for actor testing (Logger)
5. Test both happy paths and error conditions
6. Verify preconditions in test setup

Example test:

```swift
func testLogMessageAtDefaultLevel() async {
    let logger = Logger(name: "testLogger")
    await logger.info("Test message")
    let entries = await logger.getEntries()

    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries[0].message, "Test message")
    XCTAssertEqual(entries[0].level, .info)
}
```

## Troubleshooting

### "No such module 'XCTest'"

**Cause**: Command Line Tools don't include XCTest framework.

**Solution**:
1. Install full Xcode: `xcode-select --install` then install Xcode from App Store
2. Or use GitHub Actions / Docker for testing
3. Or ensure `swift test` runs in a CI/CD environment with Xcode

### Test Timeout

If tests are timing out:

```bash
swift test --parallel=false --timeout 60
```

### Verbose Test Output

```bash
swift test -v --enable-test-discovery
```

## Performance Benchmarking

Phase 4 tests include performance benchmarks. To run with timing:

```bash
swift test -v 2>&1 | grep -i "duration"
```

Expected benchmarks:
- Single message log: <1ms
- 10,000 messages: <500ms
- Concurrent logging (100 tasks): <1s

## Coverage Reports

After running tests with coverage enabled:

```bash
# Generate coverage reports
swift test --enable-code-coverage

# Create HTML report (macOS only)
xcrun llvm-cov show -instr-profile=.build/coverage/default/default.profdata .build/debug/Log4MCPPackageTests
```

## Contributing Tests

When contributing new tests:

1. Add them to the appropriate test file
2. Follow the T[Phase].[Section].[Case] naming convention
3. Update TEST_PLAN.md with new test cases
4. Ensure all tests pass locally
5. Verify coverage is maintained above 85%
6. Document any platform-specific tests

## Future Enhancements

- [ ] Integration tests for TCP server (currently uses stdio)
- [ ] Performance regression testing in CI
- [ ] Code coverage reporting in CI
- [ ] Stress tests with large message volumes
- [ ] Network error simulation tests
- [ ] Docker-based integration testing

---

For detailed test specifications, see `TEST_PLAN.md`.
