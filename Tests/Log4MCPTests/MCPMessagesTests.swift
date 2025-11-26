import XCTest
@testable import Log4MCPLib

final class MCPMessagesTests: XCTestCase {

    // T1.3.1: Encode LogEntry to JSON
    func testEncodeLogEntry() throws {
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

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("Test message") ?? false)
        XCTAssertTrue(jsonString?.contains("INFO") ?? false)
    }

    // T1.3.2: Decode LogEntry from JSON
    func testDecodeLogEntry() throws {
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

        XCTAssertEqual(entry.message, "Test message")
        XCTAssertEqual(entry.level, .info)
        XCTAssertEqual(entry.logger, "testLogger")
        XCTAssertEqual(entry.line, 42)
        XCTAssertEqual(entry.file, "test.swift")
    }

    // T1.3.3: Encode MCPRequest to JSON
    func testEncodeMCPRequest() throws {
        let params = LogMessageParams(
            loggerId: "myapp",
            level: "INFO",
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

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("log.message") ?? false)
        XCTAssertTrue(jsonString?.contains("2.0") ?? false)
    }

    // T1.3.4: Decode MCPRequest from JSON
    func testDecodeMCPRequest() throws {
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

        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, "1")
        XCTAssertEqual(request.method, "log.message")
    }

    // T1.3.5: Encode MCPResponse with success
    func testEncodeMCPResponseSuccess() throws {
        let result = SuccessResult(success: true)
        let response = MCPResponse(
            jsonrpc: "2.0",
            id: "1",
            result: .success(result),
            error: nil
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("true") ?? false)
    }

    // T1.3.6: Encode MCPResponse with error
    func testEncodeMCPResponseError() throws {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = MCPResponse(
            jsonrpc: "2.0",
            id: "1",
            result: nil,
            error: error
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("Method not found") ?? false)
        XCTAssertTrue(jsonString?.contains("-32601") ?? false)
    }

    // T1.3.8: ISO8601 timestamp format
    func testISO8601TimestampFormat() throws {
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

        XCTAssertGreaterThan(matches.count, 0)
    }

    // Test MCPError
    func testMCPError() {
        let error = MCPError(code: -32700, message: "Parse error")
        XCTAssertEqual(error.code, -32700)
        XCTAssertEqual(error.message, "Parse error")
    }

    // Test ServerInfo
    func testServerInfo() {
        let serverInfo = ServerInfo(name: "Log4MCP", version: "1.0.0")
        XCTAssertEqual(serverInfo.name, "Log4MCP")
        XCTAssertEqual(serverInfo.version, "1.0.0")
    }

    // Test MCPCapabilities
    func testMCPCapabilities() {
        let logging = MCPCapabilities.Logging(level: "DEBUG")
        let capabilities = MCPCapabilities(logging: logging)
        XCTAssertEqual(capabilities.logging.level, "DEBUG")
    }

    // Test LogMessageParams
    func testLogMessageParams() {
        let params = LogMessageParams(
            loggerId: "app1",
            level: "INFO",
            message: "Test message"
        )
        XCTAssertEqual(params.loggerId, "app1")
        XCTAssertEqual(params.level, "INFO")
        XCTAssertEqual(params.message, "Test message")
    }

    // Test GetEntriesParams
    func testGetEntriesParams() {
        let params = GetEntriesParams(
            loggerId: "app1",
            level: "INFO"
        )
        XCTAssertEqual(params.loggerId, "app1")
        XCTAssertEqual(params.level, "INFO")
    }

    // Test ClearLogsParams
    func testClearLogsParams() {
        let params = ClearLogsParams(loggerId: "app1")
        XCTAssertEqual(params.loggerId, "app1")
    }

    // Test SetLogLevelParams
    func testSetLogLevelParams() {
        let params = SetLogLevelParams(
            loggerId: "app1",
            level: "DEBUG"
        )
        XCTAssertEqual(params.loggerId, "app1")
        XCTAssertEqual(params.level, "DEBUG")
    }

    // Test SuccessResult
    func testSuccessResult() {
        let result = SuccessResult(success: true)
        XCTAssertTrue(result.success)
    }

    // Test InitializeResult
    func testInitializeResult() throws {
        let serverInfo = ServerInfo(name: "Log4MCP", version: "1.0.0")
        let capabilities = MCPCapabilities(logging: MCPCapabilities.Logging(level: "DEBUG"))
        let result = InitializeResult(
            protocolVersion: "2024-11-25",
            capabilities: capabilities,
            serverInfo: serverInfo
        )

        XCTAssertEqual(result.protocolVersion, "2024-11-25")
        XCTAssertEqual(result.capabilities.logging.level, "DEBUG")
        XCTAssertEqual(result.serverInfo.name, "Log4MCP")
    }
}
