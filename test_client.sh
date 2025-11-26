#!/bin/bash

# Test script for Log4MCP server (TCP Mode)
# This script demonstrates how to interact with the Log4MCP server via TCP
# Requires a running Log4MCP server on localhost:3000

set -e

echo "Log4MCP Test Client (TCP Mode)"
echo "=============================="
echo ""
echo "This test script connects to an existing Log4MCP server on localhost:3000"
echo "If the server is not running, start it with:"
echo "  swift run Log4MCP --log-level DEBUG --verbose"
echo ""

# Check if server is available
if ! nc -z localhost 3000 2>/dev/null; then
    echo "Error: Log4MCP server is not running on localhost:3000"
    echo "Start the server with: swift run Log4MCP"
    exit 1
fi

echo "Server is available on localhost:3000"
echo ""

# Function to send a request via TCP
send_request() {
    local request="$1"
    local description="$2"

    echo ""
    echo "Test: $description"
    echo "Request: $request"
    echo -n "Response: "
    echo "$request" | timeout 5 nc localhost 3000 2>/dev/null || echo "No response"
}

# Test 1: Log a message
send_request \
    '{"jsonrpc":"2.0","id":"1","method":"log.message","params":{"loggerId":"testapp","level":"INFO","message":"Test message"}}' \
    "Log a message"

# Test 2: Get entries
send_request \
    '{"jsonrpc":"2.0","id":"2","method":"log.getEntries","params":{"loggerId":"testapp","level":null}}' \
    "Get all entries"

# Test 3: Log an error
send_request \
    '{"jsonrpc":"2.0","id":"3","method":"log.message","params":{"loggerId":"testapp","level":"ERROR","message":"Error occurred"}}' \
    "Log an error message"

# Test 4: Get only error entries
send_request \
    '{"jsonrpc":"2.0","id":"4","method":"log.getEntries","params":{"loggerId":"testapp","level":"ERROR"}}' \
    "Get only error entries"

# Test 5: Set log level
send_request \
    '{"jsonrpc":"2.0","id":"5","method":"log.setLevel","params":{"loggerId":"testapp","level":"WARN"}}' \
    "Set log level to WARN"

# Test 6: Clear logs
send_request \
    '{"jsonrpc":"2.0","id":"6","method":"log.clear","params":{"loggerId":"testapp"}}' \
    "Clear logs"

# Test 7: System capabilities
send_request \
    '{"jsonrpc":"2.0","id":"7","method":"system.capabilities","params":{}}' \
    "System capabilities"

# Test 8: Invalid method (error case)
send_request \
    '{"jsonrpc":"2.0","id":"8","method":"invalid.method","params":{}}' \
    "Invalid method (should error)"

echo ""
echo ""
echo "Tests completed!"
