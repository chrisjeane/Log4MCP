# Log4MCP - Swift Model Context Protocol Logger

A high-performance, thread-safe logging server implemented in Swift that communicates via the Model Context Protocol (MCP) over JSON-RPC 2.0. Perfect for distributed logging, multi-tenant applications, and integrating logging capabilities into Claude AI contexts.

## Features

- **MCP-Compliant**: Implements the Model Context Protocol for seamless integration
- **Async/Await**: Built on Swift's modern concurrency model with actors
- **Multiple Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
- **Thread-Safe**: Uses actor-based concurrency for thread-safe logging
- **Flexible Storage**: Configurable maximum log entries with automatic rotation
- **TCP Server**: JSON-RPC 2.0 over TCP (primary access method)
- **Stdio Support**: Optional JSON-RPC 2.0 over stdin/stdout for MCP integration
- **Command-Line Configuration**: Easy setup via CLI arguments

## Building

```bash
# Build the project
swift build

# Run with default settings
swift run Log4MCP

# Run with custom configuration
swift run Log4MCP --port 3000 --log-level DEBUG --verbose

# Run in stdio mode (for MCP integration)
swift run Log4MCP --stdio --log-level DEBUG --verbose
```

## Command-Line Options

```
Log4MCP [OPTIONS]

Options:
  -p, --port PORT              Port to listen on (default: 3000) [TCP mode]
  -h, --host HOST              Host to bind to (default: 0.0.0.0) [TCP mode]
  -m, --max-entries NUM        Maximum log entries per logger (default: 1000)
  -l, --log-level LEVEL        Default log level (default: INFO)
                               Valid levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
  -v, --verbose                Enable verbose output to stderr
  --stdio                      Use stdio mode instead of TCP (default: TCP server)
  --help                       Show this help message

Server Modes:
  TCP (default)  - Listens on specified host:port for client connections
  Stdio          - Reads JSON-RPC requests from stdin, writes responses to stdout

Examples:
  swift run Log4MCP --log-level DEBUG --max-entries 5000 --verbose
  swift run Log4MCP --port 8080 --host 127.0.0.1 --log-level DEBUG
  swift run Log4MCP --stdio --log-level DEBUG --verbose
```

## MCP Methods

### log.message
Log a message to a specific logger.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "log.message",
  "params": {
    "loggerId": "myapp",
    "level": "INFO",
    "message": "Application started successfully"
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": { "success": true }
}
```

### log.getEntries
Retrieve logged entries, optionally filtered by log level.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": "2",
  "method": "log.getEntries",
  "params": {
    "loggerId": "myapp",
    "level": null
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": "2",
  "result": {
    "entries": [
      {
        "timestamp": "2024-11-25T21:15:00Z",
        "level": "INFO",
        "message": "Application started",
        "logger": "myapp",
        "thread": "main",
        "file": "main.swift",
        "line": 42,
        "method": "main()"
      }
    ]
  }
}
```

### log.clear
Clear all log entries for a specific logger.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": "3",
  "method": "log.clear",
  "params": {
    "loggerId": "myapp"
  }
}
```

### log.setLevel
Change the log level for a specific logger.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": "4",
  "method": "log.setLevel",
  "params": {
    "loggerId": "myapp",
    "level": "DEBUG"
  }
}
```

### system.capabilities
Report server capabilities.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": "5",
  "method": "system.capabilities"
}
```

## Project Structure

```
Log4MCP/
├── Sources/Log4MCP/
│   ├── Log4MCP.swift          - Main entry point
│   ├── Config.swift           - Command-line configuration
│   ├── StdioTransport.swift   - JSON-RPC stdio communication
│   ├── Logger.swift           - Thread-safe logging actor
│   ├── MCPMessages.swift      - MCP protocol message types
│   ├── MCPRequestHandler.swift - Request processing
│   ├── Errors.swift           - Error handling
│   └── ExampleClient.swift    - Usage examples
├── Package.swift              - Package manifest
└── README.md                  - This file
```

## Protocol Details

- **Communication**: JSON-RPC 2.0 over TCP (primary) or stdin/stdout (stdio mode)
- **Format**: Each request and response is a single line of JSON terminated with newline
- **Timestamps**: ISO8601 format
- **Request ID**: Always include a unique `id` field
- **Error Handling**: Errors follow JSON-RPC 2.0 error specification

## Log Levels

| Level | Priority | Use Case |
|-------|----------|----------|
| TRACE | 0 | Very detailed diagnostic info |
| DEBUG | 1 | Debug-level messages |
| INFO | 2 | General informational messages |
| WARN | 3 | Warning conditions |
| ERROR | 4 | Error conditions |
| FATAL | 5 | Fatal error conditions |

## Architecture

### Key Components

1. **MCPServer**: Coordinates the server initialization
2. **StdioTransport**: Handles JSON-RPC communication over stdio
3. **MCPRequestHandler**: Processes incoming MCP requests
4. **Logger**: Thread-safe actor managing log entries
5. **Config**: Parses and manages server configuration

### Concurrency Model

- Uses Swift actors for thread-safe logging
- Async/await for non-blocking operations
- Safe handling of multi-threaded access

## Example Usage

### Starting the Server (TCP Mode - Default)
```bash
swift run Log4MCP --log-level DEBUG --verbose
# Server listens on 0.0.0.0:3000
```

### Sending Requests via TCP (from another terminal)

Using `nc` (netcat):
```bash
# Log a message via TCP
echo '{"jsonrpc":"2.0","id":"1","method":"log.message","params":{"loggerId":"app","level":"INFO","message":"Test message"}}' | nc localhost 3000
```

Using a Python client:
```python
# Python TCP client example
import json
import socket

def send_request(method, params):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(('localhost', 3000))

    request = {
        "jsonrpc": "2.0",
        "id": "1",
        "method": method,
        "params": params or {}
    }

    sock.send((json.dumps(request) + '\n').encode())
    response = sock.recv(4096).decode()
    sock.close()

    return json.loads(response)

# Log a message
response = send_request("log.message", {
    "loggerId": "myapp",
    "level": "INFO",
    "message": "Hello from Python"
})
print(response)
```

### Using Stdio Mode (MCP Integration)

To use stdio mode for MCP integration:
```bash
swift run Log4MCP --stdio --log-level DEBUG --verbose
```

Stdio mode reads JSON-RPC requests from stdin and writes responses to stdout, making it suitable for integration with Claude and other MCP-compatible clients.

## Dependencies

- **Swift NIO** 2.56+ - For high-performance async networking
- **Swift AsyncAlgorithms** 1.0+ - For async sequence algorithms
- Swift 6.2+ compiler

## Development

### Building in Debug Mode
```bash
swift build
```

### Running Tests
Tests can be added to the `Tests/` directory:
```bash
swift test
```

### Verbose Logging
Enable verbose output to see all requests and responses:
```bash
swift run Log4MCP --verbose
```

## Performance

- Handles multiple concurrent loggers efficiently
- Log entries are stored in memory with configurable rotation
- Supports high-throughput logging scenarios

## Limitations

- Log entries are stored in memory (not persisted to disk)
- No built-in clustering or replication
- Single-process deployment

## Future Enhancements

- File-based persistence
- Structured logging with tags and metadata
- Built-in filtering and search
- Metrics and statistics collection
- Integration with Claude AI contexts

## License

MIT License

## Contributing

Contributions are welcome! Please ensure:
- Code follows Swift style guidelines
- All code builds without warnings
- New features include documentation
- Changes maintain backward compatibility with MCP standard

## Support

For issues, questions, or suggestions, please refer to the MCP specification at https://spec.modelcontextprotocol.io
