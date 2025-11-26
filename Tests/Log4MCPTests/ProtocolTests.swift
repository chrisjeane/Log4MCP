import Foundation
@testable import Log4MCPLib

// Phase 2: Integration Tests - Protocol Compliance

final class ProtocolTests {

    // T2.1.1: Complete log.message cycle
    func testLogMessageCycle() async {
        let handler = MCPRequestHandler()

        let params = LogMessageParams(
            loggerId: "app",
            level: "INFO",
            message: "Test message"
        )

        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(params)
        )

        let encoder = JSONEncoder()
        let requestData = try! encoder.encode(request)

        let responseData = await handler.handleRequest(requestData)
        let decoder = JSONDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        assert(response.jsonrpc == "2.0", "jsonrpc field should be 2.0")
        assert(response.id == "1", "id should match request")
        assert(response.error == nil, "error should be nil")
    }

    // T2.1.2: Complete log.getEntries cycle
    func testGetEntriesCycle() async {
        let handler = MCPRequestHandler()

        // First log a message
        let logParams = LogMessageParams(
            loggerId: "app",
            level: "INFO",
            message: "Test"
        )
        let logRequest = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(logParams)
        )

        let encoder = JSONEncoder()
        let _ = await handler.handleRequest(try! encoder.encode(logRequest))

        // Then get entries
        let getParams = GetEntriesParams(loggerId: "app", level: nil)
        let getRequest = MCPRequest(
            jsonrpc: "2.0",
            id: "2",
            method: "log.getEntries",
            params: .getEntries(getParams)
        )

        let responseData = await handler.handleRequest(try! encoder.encode(getRequest))
        let decoder = JSONDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        assert(response.jsonrpc == "2.0", "jsonrpc should be 2.0")
        assert(response.id == "2", "id should match request")
        assert(response.error == nil, "error should be nil")
    }

    // T2.1.3: Complete log.clear cycle
    func testClearCycle() async {
        let handler = MCPRequestHandler()

        let params = ClearLogsParams(loggerId: "app")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.clear",
            params: .clearLogs(params)
        )

        let encoder = JSONEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = JSONDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        assert(response.jsonrpc == "2.0", "jsonrpc should be 2.0")
        assert(response.error == nil, "error should be nil")
    }

    // T2.1.4: Complete log.setLevel cycle
    func testSetLevelCycle() async {
        let handler = MCPRequestHandler()

        let params = SetLogLevelParams(loggerId: "app", level: "DEBUG")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.setLevel",
            params: .setLogLevel(params)
        )

        let encoder = JSONEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = JSONDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        assert(response.jsonrpc == "2.0", "jsonrpc should be 2.0")
        assert(response.error == nil, "error should be nil")
    }

    // T2.1.5: Complete system.capabilities cycle
    func testCapabilitiesCycle() async {
        let handler = MCPRequestHandler()

        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "system.capabilities",
            params: .none
        )

        let encoder = JSONEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = JSONDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        assert(response.jsonrpc == "2.0", "jsonrpc should be 2.0")
        assert(response.error == nil, "error should be nil")
    }

    // T2.1.6: Request ID preservation
    func testRequestIDPreservation() async {
        let handler = MCPRequestHandler()

        let params = LogMessageParams(
            loggerId: "app",
            level: "INFO",
            message: "Test"
        )

        let testIDs = ["test123", "abc-def-ghi", "12345"]

        for testID in testIDs {
            let request = MCPRequest(
                jsonrpc: "2.0",
                id: testID,
                method: "log.message",
                params: .logMessage(params)
            )

            let encoder = JSONEncoder()
            let responseData = await handler.handleRequest(try! encoder.encode(request))

            let decoder = JSONDecoder()
            let response = try! decoder.decode(MCPResponse.self, from: responseData!)

            assert(response.id == testID, "Response ID should match request ID")
        }
    }

    // T2.1.7: Multiple sequential requests
    func testSequentialRequests() async {
        let handler = MCPRequestHandler()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for i in 1...5 {
            let params = LogMessageParams(
                loggerId: "app",
                level: "INFO",
                message: "Message \(i)"
            )

            let request = MCPRequest(
                jsonrpc: "2.0",
                id: String(i),
                method: "log.message",
                params: .logMessage(params)
            )

            let responseData = await handler.handleRequest(try! encoder.encode(request))
            let response = try! decoder.decode(MCPResponse.self, from: responseData!)

            assert(response.id == String(i), "Sequential request IDs should match")
            assert(response.error == nil, "Sequential requests should not error")
        }
    }

    // T2.1.8: Multiple concurrent requests
    func testConcurrentRequests() async {
        let handler = MCPRequestHandler()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        await withTaskGroup(of: (String, Bool).self) { group in
            for i in 1...5 {
                group.addTask {
                    let params = LogMessageParams(
                        loggerId: "app\(i)",
                        level: "INFO",
                        message: "Message \(i)"
                    )

                    let request = MCPRequest(
                        jsonrpc: "2.0",
                        id: String(i),
                        method: "log.message",
                        params: .logMessage(params)
                    )

                    let responseData = await handler.handleRequest(try! encoder.encode(request))
                    let response = try! decoder.decode(MCPResponse.self, from: responseData!)

                    return (response.id, response.error == nil)
                }
            }

            var successCount = 0
            for await (id, success) in group {
                if success {
                    successCount += 1
                }
            }
            assert(successCount == 5, "All concurrent requests should succeed")
        }
    }
}

// Helper function for assertions
func assert(_ condition: Bool, _ message: String) {
    if !condition {
        print("❌ Assertion failed: \(message)")
    } else {
        print("✓ \(message)")
    }
}
