# Log4MCP Test Plan

## Overview

This document outlines a comprehensive testing strategy for Log4MCP, a Swift-based MCP logging server. Tests are organized by category, complexity level, and dependencies.

---

## 1. Unit Tests

### 1.1 Config Module Tests
**File**: `Tests/Log4MCPTests/ConfigTests.swift`

#### Test Cases
- **T1.1.1**: Parse default configuration
  - Verify default values are set correctly
  - Expected: port=3000, log-level=INFO, max-entries=1000, verbose=false

- **T1.1.2**: Parse custom port
  - Input: `--port 8080`
  - Expected: config.port == 8080

- **T1.1.3**: Parse custom log level
  - Input: `--log-level DEBUG`
  - Expected: config.logLevel == .debug

- **T1.1.4**: Parse max entries
  - Input: `--max-entries 5000`
  - Expected: config.maxEntries == 5000

- **T1.1.5**: Parse verbose flag
  - Input: `--verbose`
  - Expected: config.verbose == true

- **T1.1.6**: Invalid log level handling
  - Input: `--log-level INVALID`
  - Expected: Error or fallback to default

- **T1.1.7**: Multiple arguments parsing
  - Input: `--port 9000 --log-level WARN --max-entries 2000 --verbose`
  - Expected: All values parsed correctly

- **T1.1.8**: Help text generation
  - Input: `--help`
  - Expected: Help message displayed without errors

### 1.2 Logger Module Tests
**File**: `Tests/Log4MCPTests/LoggerTests.swift`

#### Test Cases
- **T1.2.1**: Create logger instance
  - Verify logger initializes with correct ID
  - Expected: logger.id == specified id

- **T1.2.2**: Log message at default level
  - Action: Log INFO message
  - Expected: Entry added to entries array with correct level

- **T1.2.3**: Log message at all levels
  - Action: Log message at TRACE, DEBUG, INFO, WARN, ERROR, FATAL
  - Expected: All entries stored with correct levels

- **T1.2.4**: Log level filtering
  - Action: Set logger level to WARN, log INFO and ERROR
  - Expected: Only ERROR (and higher) messages stored

- **T1.2.5**: Get all entries
  - Action: Log 5 messages, call getEntries(level: nil)
  - Expected: All 5 entries returned

- **T1.2.6**: Get entries by level
  - Action: Log mixed levels, filter by WARN
  - Expected: Only WARN and higher level entries returned

- **T1.2.7**: Clear logger entries
  - Action: Log entries, then clear
  - Expected: entries array is empty

- **T1.2.8**: Set log level
  - Action: Create logger, set level to DEBUG
  - Expected: logger.minLevel == .debug

- **T1.2.9**: Log entry has correct metadata
  - Action: Log message
  - Expected: Entry contains timestamp, level, message, logger id, thread info

- **T1.2.10**: Log entry rotation (FIFO)
  - Action: Set max-entries to 3, log 5 messages
  - Expected: Only last 3 messages retained, oldest removed first

- **T1.2.11**: Concurrent logging to same logger
  - Action: Log from multiple async tasks to same logger
  - Expected: All entries stored correctly (no race conditions)

- **T1.2.12**: Empty logger state
  - Action: Create logger, don't log anything
  - Expected: getEntries returns empty array

### 1.3 Message Encoding/Decoding Tests
**File**: `Tests/Log4MCPTests/MCPMessagesTests.swift`

#### Test Cases
- **T1.3.1**: Encode MCPRequest to JSON
  - Action: Create request object, encode to JSON
  - Expected: Valid JSON with all fields

- **T1.3.2**: Decode MCPRequest from JSON
  - Action: Decode valid JSON request
  - Expected: Correct request object created

- **T1.3.3**: Encode LogEntry to JSON
  - Action: Create entry, encode to JSON
  - Expected: JSON includes all fields with ISO8601 timestamp

- **T1.3.4**: Decode LogEntry from JSON
  - Action: Decode entry JSON
  - Expected: Correct entry object with parsed timestamp

- **T1.3.5**: Encode MCPResponse with success
  - Action: Encode success response
  - Expected: result field populated, error field null

- **T1.3.6**: Encode MCPResponse with error
  - Action: Encode error response
  - Expected: error field populated, result field null

- **T1.3.7**: Handle JSON parse errors gracefully
  - Input: Invalid JSON
  - Expected: Appropriate error message

- **T1.3.8**: ISO8601 timestamp format
  - Action: Create entry, check timestamp format
  - Expected: Timestamp in ISO8601 format (e.g., "2024-11-25T21:15:00Z")

### 1.4 Error Handling Tests
**File**: `Tests/Log4MCPTests/ErrorTests.swift`

#### Test Cases
- **T1.4.1**: Parse error (invalid JSON)
  - Input: `{invalid json`
  - Expected: Parse error code -32700

- **T1.4.2**: Invalid request (missing fields)
  - Input: `{"jsonrpc":"2.0"}`
  - Expected: Invalid request error code -32600

- **T1.4.3**: Method not found
  - Input: `{"jsonrpc":"2.0","id":"1","method":"invalid.method","params":{}}`
  - Expected: Method not found error code -32601

- **T1.4.4**: Invalid params
  - Input: Request with wrong param type
  - Expected: Invalid params error code -32602

- **T1.4.5**: Internal error
  - Action: Trigger internal error condition
  - Expected: Internal error code -32603

---

## 2. Integration Tests

### 2.1 Protocol Compliance Tests
**File**: `Tests/Log4MCPTests/ProtocolTests.swift`

#### Test Cases
- **T2.1.1**: Complete log.message cycle
  - Action: Send log.message request, verify response
  - Expected: Correct JSON-RPC response with success result

- **T2.1.2**: Complete log.getEntries cycle
  - Action: Log messages, retrieve entries
  - Expected: Entries returned in correct format

- **T2.1.3**: Complete log.clear cycle
  - Action: Log messages, clear, verify empty
  - Expected: Entries cleared successfully

- **T2.1.4**: Complete log.setLevel cycle
  - Action: Set level, log at different levels
  - Expected: Level filtering works after set

- **T2.1.5**: Complete system.capabilities cycle
  - Action: Request capabilities
  - Expected: Server capabilities returned

- **T2.1.6**: Request ID preservation
  - Action: Send request with ID "test123"
  - Expected: Response has same ID

- **T2.1.7**: Multiple sequential requests
  - Action: Send 5 requests in sequence
  - Expected: All responses received in correct order

- **T2.1.8**: Multiple concurrent requests
  - Action: Send 5 requests concurrently
  - Expected: All responses received (order may vary)

### 2.2 Stdio Transport Tests
**File**: `Tests/Log4MCPTests/StdioTransportTests.swift`

#### Test Cases
- **T2.2.1**: Read single JSON request from stdin
  - Action: Send one request line
  - Expected: Request processed, response written

- **T2.2.2**: Read multiple requests from stdin
  - Action: Send 3 request lines
  - Expected: All processed in order

- **T2.2.3**: Handle malformed JSON gracefully
  - Action: Send invalid JSON line
  - Expected: Error response, continue processing

- **T2.2.4**: EOF handling
  - Action: Send requests then EOF
  - Expected: Process requests and terminate cleanly

- **T2.2.5**: Verbose output to stderr
  - Action: Run with --verbose, send request
  - Expected: Debug output appears on stderr

- **T2.2.6**: Newline handling
  - Action: Send request with proper newline
  - Expected: Request processed correctly

- **T2.2.7**: Large request handling
  - Action: Send large JSON request (1MB+)
  - Expected: Request processed or appropriate error

- **T2.2.8**: Empty lines in input
  - Action: Send empty line between requests
  - Expected: Handled gracefully

### 2.3 Request Handler Tests
**File**: `Tests/Log4MCPTests/RequestHandlerTests.swift`

#### Test Cases
- **T2.3.1**: Route to log.message handler
  - Action: Send log.message request
  - Expected: Routed to correct handler

- **T2.3.2**: Route to log.getEntries handler
  - Action: Send log.getEntries request
  - Expected: Routed to correct handler

- **T2.3.3**: Route to log.clear handler
  - Action: Send log.clear request
  - Expected: Routed to correct handler

- **T2.3.4**: Route to log.setLevel handler
  - Action: Send log.setLevel request
  - Expected: Routed to correct handler

- **T2.3.5**: Route to system.capabilities handler
  - Action: Send system.capabilities request
  - Expected: Routed to correct handler

- **T2.3.6**: Multiple loggers isolation
  - Action: Create logger1 and logger2, log different messages
  - Expected: Entries kept separate

- **T2.3.7**: Logger persistence across requests
  - Action: Log to logger1, close connection, reconnect, log more to logger1
  - Expected: Both sets of logs retained (in same process)

- **T2.3.8**: Decode log.message params correctly
  - Action: Send log.message with all fields
  - Expected: All params decoded correctly

- **T2.3.9**: Decode log.getEntries params correctly
  - Action: Send getEntries with level filter
  - Expected: Params decoded, filtering applied

---

## 3. API Contract Tests

### 3.1 log.message Tests
**File**: `Tests/Log4MCPTests/APIContractTests.swift`

#### Test Cases
- **T3.1.1**: log.message with required params
  - Params: loggerId, level, message
  - Expected: Message logged successfully

- **T3.1.2**: log.message response format
  - Expected: `{"success": true}`

- **T3.1.3**: log.message with invalid level
  - Params: loggerId="test", level="INVALID", message="msg"
  - Expected: Error or message logged at default level

- **T3.1.4**: log.message with empty message
  - Params: message=""
  - Expected: Entry created with empty string message

- **T3.1.5**: log.message with special characters
  - Params: message with unicode, quotes, newlines
  - Expected: Message preserved correctly

- **T3.1.6**: log.message with long message
  - Params: message with 10KB of text
  - Expected: Message logged successfully

- **T3.1.7**: log.message creates unique timestamp
  - Action: Log 2 messages rapidly
  - Expected: Different timestamps (or microsecond precision)

### 3.2 log.getEntries Tests

#### Test Cases
- **T3.2.1**: getEntries with level=null
  - Expected: All entries returned regardless of level

- **T3.2.2**: getEntries with level="INFO"
  - Expected: Only INFO and higher returned

- **T3.2.3**: getEntries empty logger
  - Expected: Empty array returned

- **T3.2.4**: getEntries response format
  - Expected: `{"entries": [...]}`

- **T3.2.5**: getEntries entry structure
  - Expected: Each entry has timestamp, level, message, logger, thread, file, line, method

- **T3.2.6**: getEntries filtering for TRACE
  - Expected: TRACE and all higher levels returned

- **T3.2.7**: getEntries filtering for FATAL
  - Expected: Only FATAL entries returned

### 3.3 log.clear Tests

#### Test Cases
- **T3.3.1**: clear removes all entries
  - Action: Log messages, clear, getEntries
  - Expected: Empty entries array

- **T3.3.2**: clear response format
  - Expected: `{"success": true}`

- **T3.3.3**: clear on empty logger
  - Action: Clear logger with no entries
  - Expected: Success response

- **T3.3.4**: clear doesn't affect other loggers
  - Action: Log to logger1 and logger2, clear logger1
  - Expected: logger2 entries unaffected

### 3.4 log.setLevel Tests

#### Test Cases
- **T3.4.1**: setLevel changes filtering
  - Action: Log at DEBUG level, set level to WARN, log DEBUG and WARN
  - Expected: Only WARN and above are stored after setLevel

- **T3.4.2**: setLevel response format
  - Expected: `{"success": true}`

- **T3.4.3**: setLevel with valid levels
  - Action: Test each level: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
  - Expected: All set successfully

- **T3.4.4**: setLevel with invalid level
  - Input: level="INVALID"
  - Expected: Error response

- **T3.4.5**: setLevel persists across requests
  - Action: Set level to WARN, close connection, reopen, log DEBUG
  - Expected: DEBUG still filtered (within same process)

### 3.5 system.capabilities Tests

#### Test Cases
- **T3.5.1**: capabilities returns structure
  - Expected: Response contains server capabilities

- **T3.5.2**: capabilities lists methods
  - Expected: Contains list of supported methods

- **T3.5.3**: capabilities includes version
  - Expected: Version or protocol version included

---

## 4. Performance & Load Tests

### 4.1 High-Volume Logging
**File**: `Tests/Log4MCPTests/PerformanceTests.swift`

#### Test Cases
- **T4.1.1**: Log 10,000 messages to single logger
  - Action: Send 10K log messages
  - Expected: All logged, memory reasonable, no crashes

- **T4.1.2**: Log 1,000 messages to 100 different loggers
  - Action: Distribute logging across many loggers
  - Expected: All stored correctly, isolation maintained

- **T4.1.3**: Log with rotation
  - Action: Set max-entries to 100, log 1,000
  - Expected: Memory bounded, oldest entries rotated out

- **T4.1.4**: Concurrent logging performance
  - Action: 10 concurrent tasks logging 1,000 messages each
  - Expected: No race conditions, all messages stored

- **T4.1.5**: Response time under load
  - Action: Log continuously, measure response time
  - Expected: Response time remains sub-100ms

- **T4.1.6**: Memory stability
  - Action: Log continuously for extended period
  - Expected: Memory usage remains stable (no leaks)

### 4.2 Large Message Handling
**File**: `Tests/Log4MCPTests/PerformanceTests.swift`

#### Test Cases
- **T4.2.1**: Log message with 1MB text
  - Expected: Logged successfully, no truncation

- **T4.2.2**: Log 100 messages of 100KB each
  - Expected: All stored without degradation

- **T4.2.3**: Response time with large messages
  - Expected: Sub-second response time

---

## 5. Concurrency & Thread Safety Tests

### 5.1 Actor Safety Tests
**File**: `Tests/Log4MCPTests/ConcurrencyTests.swift`

#### Test Cases
- **T5.1.1**: Concurrent reads from same logger
  - Action: 100 concurrent getEntries calls
  - Expected: No deadlocks, consistent results

- **T5.1.2**: Concurrent writes to same logger
  - Action: 100 concurrent log calls
  - Expected: All entries stored, no data loss

- **T5.1.3**: Concurrent mixed operations
  - Action: Simultaneous log, getEntries, clear, setLevel
  - Expected: Operations serialize correctly, no conflicts

- **T5.1.4**: Concurrent logger creation
  - Action: Create 100 loggers concurrently
  - Expected: All created successfully

- **T5.1.5**: Rapid clear and log
  - Action: Clear logger while logging
  - Expected: No race conditions or crashes

---

## 6. Error & Edge Case Tests

### 6.1 Malformed Request Tests
**File**: `Tests/Log4MCPTests/ErrorEdgeCaseTests.swift`

#### Test Cases
- **T6.1.1**: Request missing jsonrpc field
  - Expected: Invalid request error

- **T6.1.2**: Request missing id field
  - Expected: Invalid request error (or process anyway)

- **T6.1.3**: Request missing method field
  - Expected: Invalid request error

- **T6.1.4**: Request missing params field
  - Expected: Handled gracefully or error

- **T6.1.5**: Request with null params
  - Expected: Handled or appropriate error

- **T6.1.6**: Request with wrong param types
  - Expected: Invalid params error

- **T6.1.7**: Deeply nested JSON
  - Expected: Parsed correctly or error

- **T6.1.8**: Circular reference in JSON
  - Expected: Error handling

### 6.2 Invalid Parameter Tests

#### Test Cases
- **T6.2.1**: loggerId with special characters
  - Expected: Handled correctly or sanitized

- **T6.2.2**: loggerId with null bytes
  - Expected: Handled or error

- **T6.2.3**: loggerId very long (1000+ chars)
  - Expected: Accepted or reasonable limit enforced

- **T6.2.4**: message with null characters
  - Expected: Handled correctly

- **T6.2.5**: Missing loggerId parameter
  - Expected: Invalid params error

- **T6.2.6**: Missing level parameter in log.message
  - Expected: Invalid params error

- **T6.2.7**: Missing message parameter in log.message
  - Expected: Invalid params error

### 6.3 State Edge Cases

#### Test Cases
- **T6.3.1**: Clear and immediately getEntries
  - Expected: Empty entries returned

- **T6.3.2**: SetLevel and immediately log at old level
  - Expected: New level filtering applied

- **T6.3.3**: Log after 1000 entries with max-entries=1000
  - Expected: Oldest entry removed

- **T6.3.4**: Multiple rapid clears
  - Expected: All succeed

- **T6.3.5**: Non-existent logger operations
  - Action: Get entries from logger never created
  - Expected: Empty entries or error

---

## 7. Configuration & Startup Tests

### 7.1 Configuration Tests
**File**: `Tests/Log4MCPTests/ConfigurationTests.swift`

#### Test Cases
- **T7.1.1**: All CLI flags combinations
  - Action: Test each valid flag combination
  - Expected: Configuration parsed correctly

- **T7.1.2**: Invalid flag value
  - Input: `--port abc`
  - Expected: Error or fallback to default

- **T7.1.3**: Unrecognized flag
  - Input: `--unknown-flag value`
  - Expected: Error or ignored

- **T7.1.4**: Empty argument list
  - Expected: Default configuration used

- **T7.1.5**: Very large max-entries
  - Input: `--max-entries 1000000`
  - Expected: Accepted or reasonable limit

### 7.2 Startup Tests

#### Test Cases
- **T7.2.1**: Server starts successfully
  - Expected: No errors on startup

- **T7.2.2**: Server ready for requests immediately
  - Expected: First request succeeds

- **T7.2.3**: Server shutdown on EOF
  - Expected: Graceful shutdown

- **T7.2.4**: Signal handling (SIGTERM, SIGINT)
  - Expected: Graceful shutdown, no data loss

---

## 8. TCP Server Tests (Future)

*These tests apply when TCP transport is implemented*

### 8.1 TCP Connection Tests
- Multiple client connections
- Client disconnection handling
- Port binding and conflicts
- IPv4 and IPv6 support
- Connection timeouts
- Keep-alive handling

---

## 9. Test Execution Plan

### Phase 1: Unit Tests (Week 1)
- Config tests (8 cases)
- Logger tests (12 cases)
- Message encoding tests (8 cases)
- Error handling tests (5 cases)
- **Total: 33 tests**

### Phase 2: Integration Tests (Week 2)
- Protocol compliance (8 cases)
- Stdio transport (8 cases)
- Request handler (9 cases)
- **Total: 25 tests**

### Phase 3: API Contract Tests (Week 2-3)
- log.message (7 cases)
- log.getEntries (7 cases)
- log.clear (4 cases)
- log.setLevel (5 cases)
- system.capabilities (3 cases)
- **Total: 26 tests**

### Phase 4: Performance & Concurrency (Week 3)
- High-volume logging (6 cases)
- Large messages (3 cases)
- Concurrency (5 cases)
- **Total: 14 tests**

### Phase 5: Error & Edge Cases (Week 4)
- Malformed requests (8 cases)
- Invalid parameters (7 cases)
- State edge cases (5 cases)
- **Total: 20 tests**

### Phase 6: Configuration & Startup (Week 4)
- Configuration (5 cases)
- Startup (4 cases)
- **Total: 9 tests**

---

## 10. Test Coverage Goals

- **Unit Test Coverage**: 90%+ of core logic
- **Integration Test Coverage**: All public APIs
- **Protocol Compliance**: 100% of MCP methods
- **Error Paths**: All documented error codes
- **Edge Cases**: Critical boundaries and limits

---

## 11. Testing Tools & Environment

### Required Tools
- Swift 6.2+
- XCTest framework
- Python 3 (for example client tests)
- Bash (for script-based tests)

### Test Environment
- macOS (development)
- Linux (CI/CD)
- Windows (if applicable)

### CI/CD Integration
- Run all tests on each commit
- Report coverage metrics
- Performance regression detection
- Timeout: 10 minutes max per test run

---

## 12. Success Criteria

A release is ready when:
1. All unit tests pass (Phase 1)
2. All integration tests pass (Phase 2)
3. All API contract tests pass (Phase 3)
4. Performance benchmarks within acceptable range (Phase 4)
5. No unhandled edge cases (Phase 5)
6. Configuration works correctly (Phase 6)
7. Code coverage >85%
8. No memory leaks detected
9. No race conditions detected
10. Documentation updated and verified

---

## 13. Known Issues & Limitations

- TCP server not yet implemented (tests marked for future)
- No file-based persistence tests (feature planned)
- No clustering tests (single-process only)
- No authentication/authorization tests (out of scope for MVP)

---

## 14. Test Maintenance

- Review and update test plan quarterly
- Add tests for new features before implementation
- Refactor tests when code refactored
- Keep examples in sync with actual API
- Monitor test execution time trends

