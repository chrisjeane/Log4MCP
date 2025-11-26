import Foundation

/// Example client code for interacting with Log4MCP server
/// This demonstrates how to use the MCP protocol to send logging requests

struct ExampleClient {
    static func example() {
        print("""
        Example Log4MCP Client Usage
        ============================

        1. Log a message:
           Request:
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

           Response:
           {
             "jsonrpc": "2.0",
             "id": "1",
             "result": { "success": true }
           }

        2. Get log entries:
           Request:
           {
             "jsonrpc": "2.0",
             "id": "2",
             "method": "log.getEntries",
             "params": {
               "loggerId": "myapp",
               "level": null
             }
           }

           Response:
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

        3. Get entries filtered by level:
           Request:
           {
             "jsonrpc": "2.0",
             "id": "3",
             "method": "log.getEntries",
             "params": {
               "loggerId": "myapp",
               "level": "ERROR"
             }
           }

        4. Clear logs:
           Request:
           {
             "jsonrpc": "2.0",
             "id": "4",
             "method": "log.clear",
             "params": {
               "loggerId": "myapp"
             }
           }

        5. Set log level:
           Request:
           {
             "jsonrpc": "2.0",
             "id": "5",
             "method": "log.setLevel",
             "params": {
               "loggerId": "myapp",
               "level": "DEBUG"
             }
           }

        Protocol Details
        ================
        - The server communicates via JSON-RPC 2.0 over stdio
        - Each request and response is a single line of JSON
        - Log levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
        - All timestamps are in ISO8601 format
        - Responses include an ID matching the request

        Command-line Options
        ====================
        Log4MCP [OPTIONS]

        Options:
          -p, --port PORT              Port to listen on (not used in stdio mode)
          -h, --host HOST              Host to bind to (not used in stdio mode)
          -m, --max-entries NUM        Maximum log entries per logger (default: 1000)
          -l, --log-level LEVEL        Default log level (default: INFO)
          -v, --verbose                Enable verbose output to stderr
          --help                       Show help message

        Example invocation:
        Log4MCP --log-level DEBUG --max-entries 5000 --verbose
        """)
    }
}
