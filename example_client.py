#!/usr/bin/env python3
"""
Example Python client for Log4MCP
Demonstrates how to interact with the Log4MCP server over JSON-RPC 2.0 via TCP
"""

import json
import socket
import sys
from typing import Any, Dict, Optional


class Log4MCPClient:
    """Client for communicating with Log4MCP server via TCP"""

    def __init__(self, host: str = "localhost", port: int = 3000, verbose: bool = False):
        """
        Initialize the client and connect to the server

        Args:
            host: Server host (default: localhost)
            port: Server port (default: 3000)
            verbose: Enable verbose output
        """
        self.host = host
        self.port = port
        self.verbose = verbose
        self.socket: Optional[socket.socket] = None
        self.request_id = 0

        self._connect()

    def _connect(self):
        """Connect to the Log4MCP server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            if self.verbose:
                print(f"Connected to {self.host}:{self.port}", file=sys.stderr)
        except Exception as e:
            print(f"Error connecting to server at {self.host}:{self.port}: {e}", file=sys.stderr)
            raise

    def _send_request(self, method: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Send a JSON-RPC request to the server via TCP

        Args:
            method: RPC method name
            params: Method parameters

        Returns:
            Response dictionary
        """
        if not self.socket:
            raise Exception("Not connected to server")

        self.request_id += 1
        request = {
            "jsonrpc": "2.0",
            "id": str(self.request_id),
            "method": method,
            "params": params or {},
        }

        request_json = json.dumps(request)
        if self.verbose:
            print(f">>> {request_json}", file=sys.stderr)

        try:
            self.socket.send((request_json + "\n").encode())

            response_json = self.socket.recv(4096).decode()
            if not response_json:
                raise Exception("Server closed connection")

            if self.verbose:
                print(f"<<< {response_json}", file=sys.stderr)
            response = json.loads(response_json)
            return response
        except Exception as e:
            print(f"Error sending request: {e}", file=sys.stderr)
            raise

    def log_message(
        self, logger_id: str, level: str, message: str
    ) -> Dict[str, Any]:
        """
        Log a message

        Args:
            logger_id: Identifier for the logger
            level: Log level (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
            message: Log message

        Returns:
            Response from server
        """
        return self._send_request(
            "log.message",
            {"loggerId": logger_id, "level": level, "message": message},
        )

    def get_entries(
        self, logger_id: str, level: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get log entries

        Args:
            logger_id: Identifier for the logger
            level: Optional log level filter

        Returns:
            Response containing log entries
        """
        return self._send_request(
            "log.getEntries",
            {"loggerId": logger_id, "level": level},
        )

    def clear_logs(self, logger_id: str) -> Dict[str, Any]:
        """
        Clear all log entries for a logger

        Args:
            logger_id: Identifier for the logger

        Returns:
            Response from server
        """
        return self._send_request(
            "log.clear",
            {"loggerId": logger_id},
        )

    def set_log_level(self, logger_id: str, level: str) -> Dict[str, Any]:
        """
        Set the log level for a logger

        Args:
            logger_id: Identifier for the logger
            level: New log level

        Returns:
            Response from server
        """
        return self._send_request(
            "log.setLevel",
            {"loggerId": logger_id, "level": level},
        )

    def get_capabilities(self) -> Dict[str, Any]:
        """
        Get system capabilities

        Returns:
            Response from server
        """
        return self._send_request("system.capabilities")

    def close(self):
        """Close the client connection"""
        try:
            if self.socket:
                self.socket.close()
                if self.verbose:
                    print("Disconnected from server", file=sys.stderr)
        except Exception as e:
            print(f"Error closing client: {e}", file=sys.stderr)


def main():
    """Example usage of the Log4MCP client"""
    print("Log4MCP Python Client Example (TCP Mode)")
    print("=" * 50)
    print("Note: Ensure the Log4MCP server is running on localhost:3000")
    print("Start it with: swift run Log4MCP --log-level DEBUG --verbose")
    print("")

    try:
        client = Log4MCPClient(host="localhost", port=3000, verbose=True)

        # Test 1: Log some messages
        print("\n1. Logging messages...")
        client.log_message("myapp", "INFO", "Application started")
        client.log_message("myapp", "DEBUG", "Debug message")
        client.log_message("myapp", "WARN", "Warning message")
        client.log_message("myapp", "ERROR", "Error occurred")

        # Test 2: Get all entries
        print("\n2. Getting all entries...")
        response = client.get_entries("myapp")
        if "result" in response and "entries" in response["result"]:
            print(f"   Found {len(response['result']['entries'])} entries")

        # Test 3: Get only errors
        print("\n3. Getting error entries only...")
        response = client.get_entries("myapp", "ERROR")
        if "result" in response and "entries" in response["result"]:
            print(f"   Found {len(response['result']['entries'])} error entries")

        # Test 4: Set log level
        print("\n4. Setting log level to WARN...")
        client.set_log_level("myapp", "WARN")

        # Test 5: Get capabilities
        print("\n5. Getting system capabilities...")
        response = client.get_capabilities()
        print(f"   Response: {response}")

        # Test 6: Clear logs
        print("\n6. Clearing logs...")
        client.clear_logs("myapp")

        print("\n" + "=" * 50)
        print("All tests completed successfully!")

    except ConnectionRefusedError:
        print("Error: Could not connect to Log4MCP server on localhost:3000", file=sys.stderr)
        print("Make sure the server is running: swift run Log4MCP", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        try:
            client.close()
        except:
            pass


if __name__ == "__main__":
    main()
