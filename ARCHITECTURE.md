# Log4MCP Architecture

## Overview

Log4MCP is a Model Context Protocol (MCP) server implementation in Swift that provides distributed logging capabilities through a JSON-RPC 2.0 interface over stdio.

## System Design

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                   │
│              (Python, JavaScript, Swift, etc)            │
└────────────────────┬────────────────────────────────────┘
                     │ JSON-RPC 2.0 over stdio
                     │
┌────────────────────▼────────────────────────────────────┐
│                 StdioTransport                           │
│  • Handles line-based JSON-RPC communication            │
│  • Reads from stdin, writes to stdout                   │
│  • Error handling for malformed requests                │
└────────────────────┬────────────────────────────────────┘
                     │ Decoded MCP Requests
                     │
┌────────────────────▼────────────────────────────────────┐
│            MCPRequestHandler (Actor)                     │
│  • Routes requests to appropriate handler               │
│  • Manages multiple concurrent logger instances         │
│  • Maintains logger registry                            │
└────────────────────┬────────────────────────────────────┘
                     │ Logger Operations
                     │
┌────────────────────▼────────────────────────────────────┐
│          Logger Instances (Actors)                       │
│  • Thread-safe log entry storage                        │
│  • Log level filtering                                  │
│  • Entry rotation and cleanup                           │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Log4MCP.swift
**Entry Point & Server Initialization**

```swift
@main
struct Log4MCPServer
```

- Parses command-line arguments
- Creates configuration
- Instantiates StdioTransport
- Runs the async event loop

**Key Responsibilities:**
- Server bootstrap
- Configuration management
- Error handling and reporting

### 2. Config.swift
**Configuration Management**

```swift
struct ServerConfig
```

- Parses CLI arguments (`--port`, `--host`, `--log-level`, etc.)
- Validates configuration values
- Provides help messages
- Stores configuration state

**Supported Options:**
- `--port`: Network port (for future use)
- `--host`: Bind address (for future use)
- `--max-entries`: Max logs per logger
- `--log-level`: Default minimum level
- `--verbose`: Debug output to stderr

### 3. StdioTransport.swift
**JSON-RPC 2.0 Protocol Handler**

```swift
actor StdioTransport
```

- Reads JSON-RPC requests from stdin (one per line)
- Delegates to MCPRequestHandler
- Writes JSON responses to stdout
- Logs debug info to stderr (if verbose)
- Handles EOF gracefully

**Flow:**
```
stdin line → parse JSON → MCPRequestHandler → JSON response → stdout
```

### 4. MCPRequestHandler.swift
**Request Router & State Manager**

```swift
actor MCPRequestHandler
```

- Maintains registry of Logger instances
- Routes requests to method handlers
- Manages logger lifecycle
- Encodes/decodes JSON payloads

**Supported Methods:**
- `log.message` - Log text to a logger
- `log.getEntries` - Retrieve stored log entries
- `log.clear` - Clear logs for a logger
- `log.setLevel` - Change logger's minimum level
- `system.capabilities` - Report server features

### 5. Logger.swift
**Core Logging Component**

```swift
actor Logger
```

**Features:**
- Thread-safe using Swift actors
- Stores LogEntry structures
- Automatic rotation (FIFO)
- Level-based filtering
- Metadata capture (file, line, function, thread)

**Data Structure:**
```swift
struct LogEntry: Codable {
    let timestamp: Date        // ISO8601 encoded
    let level: LogLevel        // TRACE/DEBUG/INFO/WARN/ERROR/FATAL
    let message: String        // Log message
    let logger: String         // Logger name
    let thread: String         // Thread name
    let file: String           // Source file
    let line: Int              // Source line
    let method: String         // Function name
}
```

### 6. MCPMessages.swift
**Protocol Message Types**

Defines JSON-RPC message structures:
- `MCPRequest` - Incoming requests
- `MCPResponse` - Outgoing responses
- `MCPParams` - Request parameters
- `MCPResult` - Response data
- `LogEntry` - Individual log entries
- `LogLevel` - Enumerated severity levels

**Codable Conformance:**
All types implement `Codable` for JSON serialization

### 7. Errors.swift
**Error Handling**

```swift
enum MCPServerError: Error
```

Defines standard JSON-RPC 2.0 error codes:
- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error

### 8. ExampleClient.swift
**Usage Documentation**

Provides code examples and protocol documentation for client developers.

## Concurrency Model

### Actor-Based Safety

The server uses Swift 5.7+ actors for thread-safe concurrent access:

```swift
// MCPRequestHandler acts as a singleton actor
// - Manages all logger instances
// - Routes all incoming requests
// - Prevents concurrent mutation

// Each Logger is also an actor
// - Manages its own log entries
// - Thread-safe modifications
// - No locks or semaphores needed
```

### Async/Await Flow

```
main() → StdioTransport.start()
  ├─ while true:
  │   ├─ readLine() [blocking]
  │   ├─ await handler.handleRequest() [non-blocking async]
  │   └─ write response
  └─ until EOF
```

## Protocol Specification

### Request Format
```json
{
  "jsonrpc": "2.0",
  "id": "unique-request-id",
  "method": "method-name",
  "params": { "param1": "value" }
}
```

### Response Format
```json
{
  "jsonrpc": "2.0",
  "id": "same-as-request",
  "result": { /* response data */ },
  "error": null
}
```

### Error Response Format
```json
{
  "jsonrpc": "2.0",
  "id": "same-as-request",
  "result": null,
  "error": {
    "code": -32601,
    "message": "Method not found"
  }
}
```

## Data Flow Examples

### Example 1: Logging a Message

```
Client Request:
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "log.message",
  "params": {
    "loggerId": "app1",
    "level": "INFO",
    "message": "User logged in"
  }
}

StdioTransport:
  → Reads from stdin
  → Passes to MCPRequestHandler

MCPRequestHandler:
  → Decodes params as LogMessageParams
  → Gets or creates Logger("app1")
  → Calls logger.log(level: .info, message: "User logged in")

Logger:
  → Creates LogEntry with timestamp, metadata
  → Stores in entries array
  → Prints to stdout if needed

MCPRequestHandler:
  → Encodes MCPResponse with success: true

StdioTransport:
  → Writes response to stdout

Client Response:
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": { "success": true }
}
```

### Example 2: Retrieving Log Entries

```
Client Request:
{
  "jsonrpc": "2.0",
  "id": "2",
  "method": "log.getEntries",
  "params": {
    "loggerId": "app1",
    "level": null
  }
}

MCPRequestHandler:
  → Gets Logger("app1")
  → Calls logger.getEntries(level: nil)
  → Returns all entries

Logger:
  → Filters entries (no level filter = all entries)
  → Returns array of LogEntry

MCPRequestHandler:
  → Encodes MCPResponse with entries array

Client Response:
{
  "jsonrpc": "2.0",
  "id": "2",
  "result": {
    "entries": [
      {
        "timestamp": "2024-11-25T21:15:00Z",
        "level": "INFO",
        "message": "User logged in",
        "logger": "app1",
        "thread": "main",
        "file": "main.swift",
        "line": 42,
        "method": "main()"
      }
    ]
  }
}
```

## Memory Management

### Log Entry Rotation

Each logger maintains a configurable maximum number of entries:

```swift
// Default: 1000 entries
// Configurable via --max-entries flag

if entries.count > maxEntries {
    entries.removeFirst()  // FIFO rotation
}
```

### Logger Lifecycle

- Loggers are created on-demand when first referenced
- Loggers persist for the lifetime of the server
- No automatic cleanup (would require TTL mechanism)

## Performance Considerations

### Strengths
- **Non-blocking I/O**: Pure async/await, no threads needed
- **Thread-safe**: Actors prevent data races
- **Efficient Routing**: Direct method dispatch
- **Minimal Overhead**: No serialization until needed
- **Scalable**: Can handle multiple concurrent loggers

### Limitations
- **In-Memory Only**: No persistence to disk
- **Single Process**: No clustering or replication
- **stdin Blocking**: readLine() blocks the thread (acceptable for stdio)
- **No Filtering Index**: Log queries filter in-memory (O(n) complexity)

## Future Enhancements

### Short Term
1. File-based log persistence
2. Configurable log rotation policies
3. Log message filtering by timestamp range
4. Batch operations for multiple logs

### Medium Term
1. Structured logging with tags/metadata
2. Full-text search over log entries
3. Log aggregation from multiple sources
4. Metrics and statistics

### Long Term
1. Distributed deployment mode
2. Database backend support
3. Real-time log streaming
4. Integration with monitoring systems

## Testing Strategy

### Unit Tests
- Logger: Entry creation, filtering, rotation
- Config: Argument parsing, validation
- Messages: JSON encoding/decoding

### Integration Tests
- Full request/response cycles
- Error handling
- Multiple concurrent loggers
- Protocol compliance

### Load Tests
- High-volume logging
- Memory usage under sustained load
- Concurrent client connections

## Security Considerations

### Current Design
- No authentication or authorization
- No input validation beyond JSON parsing
- Suitable for trusted environments

### Recommendations for Production
1. Add authentication (OAuth2, mTLS)
2. Implement rate limiting
3. Add input validation
4. Sanitize log messages
5. Implement audit logging
6. Consider log redaction for sensitive data

## Dependencies

```
Log4MCP
├── Foundation (stdlib)
├── NIO (swift-nio)
│   └── For future network transport
└── AsyncAlgorithms (swift-async-algorithms)
    └── For async sequence operations
```

Current implementation uses only Foundation (stdin/stdout communication).
NIO and AsyncAlgorithms are available for future network transport modes.
