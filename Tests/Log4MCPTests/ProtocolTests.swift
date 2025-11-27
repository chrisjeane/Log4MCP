import Foundation
import Testing
@testable import Log4MCPLib
import MCPServer

// Phase 2: Integration Tests - Protocol Compliance

struct ProtocolTests {

    private func createHandler() -> MCPRequestHandler {
        let config = ServerConfig(
            port: 3000,
            host: "localhost",
            maxLogEntries: 1000,
            defaultLogLevel: .info,
            verbose: false,
            mode: .tcp
        )
        let delegate = Log4MCPDelegate(config: config)
        return MCPRequestHandler(delegate: delegate)
    }

    private func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func initializeHandler(_ handler: MCPRequestHandler) async {
        let encoder = createEncoder()

        // Send system.initialize
        let initRequest = MCPRequest(
            jsonrpc: "2.0",
            id: "init",
            method: "initialize",
            params: .none
        )
        let _ = await handler.handleRequest(try! encoder.encode(initRequest))

        // Send system.initialized notification
        let initializedRequest = MCPRequest(
            jsonrpc: "2.0",
            id: nil,
            method: "initialized",
            params: .none
        )
        let _ = await handler.handleRequest(try! encoder.encode(initializedRequest))
    }

    // T2.1.1: Complete log.message cycle
    @Test
    func logMessageCycle() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let params = LogMessageParams(
            loggerId: "app",
            level: .info,
            message: "Test message"
        )

        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(params)
        )

        let encoder = createEncoder()
        let requestData = try! encoder.encode(request)

        let responseData = await handler.handleRequest(requestData)
        let decoder = createDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.id == "1")
        #expect(response.error == nil)
    }

    // T2.1.2: Complete log.getEntries cycle
    @Test
    func getEntriesCycle() async {
        let handler = createHandler()
        await initializeHandler(handler)

        // First log a message
        let logParams = LogMessageParams(
            loggerId: "app",
            level: .info,
            message: "Test"
        )
        let logRequest = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(logParams)
        )

        let encoder = createEncoder()
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
        let decoder = createDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.id == "2")
        #expect(response.error == nil)
    }

    // T2.1.3: Complete log.clear cycle
    @Test
    func clearCycle() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let params = ClearLogsParams(loggerId: "app")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.clear",
            params: .clearLogs(params)
        )

        let encoder = createEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = createDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.error == nil)
    }

    // T2.1.4: Complete log.setLevel cycle
    @Test
    func setLevelCycle() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let params = SetLogLevelParams(loggerId: "app", level: .debug)
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.setLevel",
            params: .setLogLevel(params)
        )

        let encoder = createEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = createDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.error == nil)
    }

    // T2.1.5: Complete initialize cycle
    @Test
    func capabilitiesCycle() async {
        let handler = createHandler()

        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "initialize",
            params: .none
        )

        let encoder = createEncoder()
        let responseData = await handler.handleRequest(try! encoder.encode(request))

        let decoder = createDecoder()
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.error == nil)
    }

    // T2.1.6: Request ID preservation
    @Test
    func requestIDPreservation() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let params = LogMessageParams(
            loggerId: "app",
            level: .info,
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

            let encoder = createEncoder()
            let responseData = await handler.handleRequest(try! encoder.encode(request))

            let decoder = createDecoder()
            let response = try! decoder.decode(MCPResponse.self, from: responseData!)

            #expect(response.id == testID)
        }
    }

    // T2.1.7: Multiple sequential requests
    @Test
    func sequentialRequests() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let encoder = createEncoder()
        let decoder = createDecoder()

        for i in 1...5 {
            let params = LogMessageParams(
                loggerId: "app",
                level: .info,
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

            #expect(response.id == String(i))
            #expect(response.error == nil)
        }
    }

    // T2.1.8: Multiple concurrent requests
    @Test
    func concurrentRequests() async {
        let handler = createHandler()
        await initializeHandler(handler)

        let encoder = createEncoder()
        let decoder = createDecoder()

        await withTaskGroup(of: (String, Bool).self) { group in
            for i in 1...5 {
                group.addTask {
                    let params = LogMessageParams(
                        loggerId: "app\(i)",
                        level: .info,
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

                    return (response.id ?? "", response.error == nil)
                }
            }

            var successCount = 0
            for await (id, success) in group {
                if success {
                    successCount += 1
                }
            }
            #expect(successCount == 5)
        }
    }
}
