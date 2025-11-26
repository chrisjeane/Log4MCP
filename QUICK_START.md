# Log4MCP Quick Start Guide

## Installation

No additional setup required! Everything is included in the repository.

## Build

```bash
cd Log4MCP
swift build
```

## Run

### Basic Usage
```bash
swift run Log4MCP
```

### With Options
```bash
swift run Log4MCP --log-level DEBUG --verbose --max-entries 5000
```

### Available Options
- `-l, --log-level LEVEL` - Set default log level (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
- `-v, --verbose` - Show debug output on stderr
- `-m, --max-entries NUM` - Maximum log entries per logger
- `--help` - Show help message

## Basic Example

The server communicates via JSON-RPC 2.0 over stdin/stdout. Send requests as JSON lines:

### 1. Log a Message

```bash
echo '{"jsonrpc":"2.0","id":"1","method":"log.message","params":{"loggerId":"myapp","level":"INFO","message":"Hello World"}}' | swift run Log4MCP
```

Response:
```json
{"jsonrpc":"2.0","id":"1","result":{"success":true}}
```

### 2. Retrieve Logs

```bash
echo '{"jsonrpc":"2.0","id":"2","method":"log.getEntries","params":{"loggerId":"myapp","level":null}}' | swift run Log4MCP
```

Response:
```json
{"jsonrpc":"2.0","id":"2","result":{"entries":[{"timestamp":"2024-11-25T21:15:00Z","level":"INFO","message":"Hello World","logger":"myapp","thread":"main","file":"example.swift","line":42,"method":"main()"}]}}
```

## Protocol Methods

### log.message
Log a message to a specific logger

**Params:**
- `loggerId` (string) - Logger identifier
- `level` (string) - Log level: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
- `message` (string) - Message text

### log.getEntries
Get stored log entries

**Params:**
- `loggerId` (string) - Logger identifier
- `level` (string or null) - Filter by level, or null for all

### log.clear
Clear all logs for a logger

**Params:**
- `loggerId` (string) - Logger identifier

### log.setLevel
Change the log level for a logger

**Params:**
- `loggerId` (string) - Logger identifier
- `level` (string) - New log level

### system.capabilities
Get server capabilities

**Params:** (none)

## Python Client Example

```python
#!/usr/bin/env python3
import json
import subprocess

# Start server
proc = subprocess.Popen(
    ['swift', 'run', 'Log4MCP'],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True
)

# Send request
request = {
    "jsonrpc": "2.0",
    "id": "1",
    "method": "log.message",
    "params": {
        "loggerId": "myapp",
        "level": "INFO",
        "message": "Hello from Python"
    }
}

proc.stdin.write(json.dumps(request) + '\n')
proc.stdin.flush()

# Read response
response_json = proc.stdout.readline()
response = json.loads(response_json)
print(response)
```

Run the example:
```bash
python3 example_client.py
```

## Testing

Run the test script:
```bash
./test_client.sh
```

This will:
1. Start the server
2. Send test requests
3. Verify responses
4. Clean up

## Project Structure

```
Log4MCP/
├── Sources/Log4MCP/
│   ├── Log4MCP.swift           - Entry point
│   ├── Config.swift            - Configuration parsing
│   ├── StdioTransport.swift    - JSON-RPC protocol
│   ├── MCPRequestHandler.swift - Request routing
│   ├── Logger.swift            - Core logging
│   ├── MCPMessages.swift       - Message types
│   ├── Errors.swift            - Error handling
│   └── ExampleClient.swift     - Usage docs
├── Package.swift               - Package config
├── README.md                   - Full documentation
├── ARCHITECTURE.md             - Design details
├── QUICK_START.md             - This file
├── example_client.py          - Python example
└── test_client.sh             - Test script
```

## Troubleshooting

### Server not responding

Make sure you're sending proper JSON-RPC format:
```json
{
  "jsonrpc": "2.0",
  "id": "unique-id",
  "method": "method-name",
  "params": { /* parameters */ }
}
```

### "Method not found" error

Check the method name spelling. Valid methods:
- `log.message`
- `log.getEntries`
- `log.clear`
- `log.setLevel`
- `system.capabilities`

### Empty response

The server reads from stdin line by line. Make sure:
1. Each request is a single line
2. End with newline character (`\n`)
3. Server receives EOF to stop (Ctrl+D in bash)

### Debug output

Run with verbose flag to see requests/responses on stderr:
```bash
swift run Log4MCP --verbose
```

## Next Steps

1. **Read Full Documentation**: See `README.md` for complete API reference
2. **Understand Architecture**: Check `ARCHITECTURE.md` for design details
3. **Explore Examples**: Look at `example_client.py` for integration patterns
4. **Integrate with Your App**: Use the Python client as a template

## Common Patterns

### Continuous Logging Session

```bash
# Terminal 1: Start server
swift run Log4MCP --verbose

# Terminal 2: Send requests continuously
while true; do
  read -p "Enter message: " msg
  echo "{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"log.message\",\"params\":{\"loggerId\":\"myapp\",\"level\":\"INFO\",\"message\":\"$msg\"}}" | nc localhost 3000
done
```

### Bulk Logging

```python
import json
import subprocess

proc = subprocess.Popen(
    ['swift', 'run', 'Log4MCP', '--max-entries', '10000'],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True
)

# Log 100 messages
for i in range(100):
    request = {
        "jsonrpc": "2.0",
        "id": str(i),
        "method": "log.message",
        "params": {
            "loggerId": "bulk_test",
            "level": "INFO",
            "message": f"Message {i}"
        }
    }
    proc.stdin.write(json.dumps(request) + '\n')
    proc.stdin.flush()

proc.stdin.close()
```

### Error Handling

```python
def send_request(proc, request):
    proc.stdin.write(json.dumps(request) + '\n')
    proc.stdin.flush()
    response_json = proc.stdout.readline()

    if not response_json:
        raise Exception("Server closed connection")

    response = json.loads(response_json)

    if 'error' in response and response['error']:
        raise Exception(f"RPC Error: {response['error']['message']}")

    return response['result']
```

## Performance Notes

- Log entries are stored in memory (not persisted)
- Max entries per logger defaults to 1000, configurable with `--max-entries`
- When limit is reached, oldest entries are removed (FIFO)
- Each logger instance stores its own entries (independent)

## Security

⚠️ This server has no built-in authentication or authorization.

For production use:
1. Run behind authenticated proxy
2. Use mTLS for client connections
3. Implement rate limiting
4. Validate/sanitize log messages
5. Audit who accesses logs

## Getting Help

- **API Questions**: See `README.md`
- **Architecture Questions**: See `ARCHITECTURE.md`
- **Code Examples**: See `example_client.py`
- **Swift Concurrency**: https://docs.swift.org/swift-book/concurrency
- **JSON-RPC 2.0 Spec**: https://www.jsonrpc.org/specification
- **MCP Spec**: https://spec.modelcontextprotocol.io
