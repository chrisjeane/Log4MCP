import Foundation
import Testing
@testable import Log4MCPLib
import MCPServer

struct MCPMessagesTests {

    // T1.3.1: Encode LogEntry to JSON
    @Test
    func encodeLogEntry() throws {
        let entry = LogEntry(
            level: .info,
            message: "Test message",
            logger: "testLogger",
            file: "test.swift",
            line: 42,
            function: "testFunc()"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(entry)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString != nil)
        #expect(jsonString?.contains("Test message") ?? false)
        #expect(jsonString?.contains("INFO") ?? false)
    }

    // T1.3.2: Decode LogEntry from JSON
    @Test
    func decodeLogEntry() throws {
        let jsonString = """
        {
            "timestamp": "2024-11-25T21:15:00Z",
            "level": "INFO",
            "message": "Test message",
            "logger": "testLogger",
            "thread": "main",
            "file": "test.swift",
            "line": 42,
            "method": "testFunc()"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(LogEntry.self, from: jsonString.data(using: .utf8)!)

        #expect(entry.message == "Test message")
        #expect(entry.level == .info)
        #expect(entry.logger == "testLogger")
        #expect(entry.line == 42)
        #expect(entry.file == "test.swift")
    }

    // T1.3.3: Encode MCPRequest to JSON
    @Test
    func encodeMCPRequest() throws {
        let params = LogMessageParams(
            loggerId: "myapp",
            level: .info,
            message: "Hello"
        )

        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(params)
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString != nil)
        #expect(jsonString?.contains("log.message") ?? false)
        #expect(jsonString?.contains("2.0") ?? false)
    }

    // T1.3.4: Decode MCPRequest from JSON
    @Test
    func decodeMCPRequest() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "method": "log.message",
            "params": {
                "loggerId": "myapp",
                "level": "INFO",
                "message": "Test"
            }
        }
        """

        let decoder = JSONDecoder()
        let request = try decoder.decode(MCPRequest.self, from: jsonString.data(using: .utf8)!)

        #expect(request.jsonrpc == "2.0")
        #expect(request.id == "1")
        #expect(request.method == "log.message")
    }

    // T1.3.5: Encode MCPResponse with success
    @Test
    func encodeMCPResponseSuccess() throws {
        let result = SuccessResult(success: true)
        let response = MCPResponse(
            id: "1",
            result: .success(result),
            error: nil
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString != nil)
        #expect(jsonString?.contains("true") ?? false)
    }

    // T1.3.6: Encode MCPResponse with error
    @Test
    func encodeMCPResponseError() throws {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = MCPResponse(
            id: "1",
            result: nil,
            error: error
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)

        #expect(jsonString != nil)
        #expect(jsonString?.contains("Method not found") ?? false)
        #expect(jsonString?.contains("-32601") ?? false)
    }

    // T1.3.8: ISO8601 timestamp format
    @Test
    func iso8601TimestampFormat() throws {
        let entry = LogEntry(
            level: .info,
            message: "Test",
            logger: "test"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(entry)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Check for ISO8601 format (YYYY-MM-DDTHH:MM:SSZ)
        let iso8601Pattern = "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z"
        let regex = try NSRegularExpression(pattern: iso8601Pattern)
        let range = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
        let matches = regex.matches(in: jsonString, range: range)

        #expect(matches.count > 0)
    }

    // Test MCPError
    @Test
    func mcpError() {
        let error = MCPError(code: -32700, message: "Parse error")
        #expect(error.code == -32700)
        #expect(error.message == "Parse error")
    }

    // Test ServerInfo
    @Test
    func serverInfo() {
        let serverInfo = ServerInfo(name: "Log4MCP", version: "1.0.0")
        #expect(serverInfo.name == "Log4MCP")
        #expect(serverInfo.version == "1.0.0")
    }

    // Test MCPCapabilities
    @Test
    func mcpCapabilities() {
        let logging = MCPCapabilities.Logging()
        let capabilities = MCPCapabilities(logging: logging)
        #expect(capabilities.logging != nil)
    }

    // Test LogMessageParams
    @Test
    func logMessageParams() {
        let params = LogMessageParams(
            loggerId: "app1",
            level: .info,
            message: "Test message"
        )
        #expect(params.loggerId == "app1")
        #expect(params.level == .info)
        #expect(params.message == "Test message")
    }

    // Test GetEntriesParams
    @Test
    func getEntriesParams() {
        let params = GetEntriesParams(
            loggerId: "app1",
            level: .info
        )
        #expect(params.loggerId == "app1")
        #expect(params.level == .info)
    }

    // Test ClearLogsParams
    @Test
    func clearLogsParams() {
        let params = ClearLogsParams(loggerId: "app1")
        #expect(params.loggerId == "app1")
    }

    // Test SetLogLevelParams
    @Test
    func setLogLevelParams() {
        let params = SetLogLevelParams(
            loggerId: "app1",
            level: .debug
        )
        #expect(params.loggerId == "app1")
        #expect(params.level == .debug)
    }

    // Test SuccessResult
    @Test
    func successResult() {
        let result = SuccessResult(success: true)
        #expect(result.success)
    }

    // Test InitializeResult
    @Test
    func initializeResult() throws {
        let serverInfo = ServerInfo(name: "Log4MCP", version: "1.0.0")
        let capabilities = MCPCapabilities(logging: MCPCapabilities.Logging())
        let result = InitializeResult(
            protocolVersion: "2024-11-25",
            capabilities: capabilities,
            serverInfo: serverInfo
        )

        #expect(result.protocolVersion == "2024-11-25")
        #expect(result.capabilities.logging != nil)
        #expect(result.serverInfo.name == "Log4MCP")
    }
}
