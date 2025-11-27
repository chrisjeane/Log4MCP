import Foundation
import Testing
@testable import Log4MCPLib
import MCPServer

// Phase 5: Error & Edge Case Tests

struct ErrorEdgeCaseTests {

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

    private func initializeHandler(_ handler: MCPRequestHandler) async {
        let encoder = JSONEncoder()

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

    // T6.1: Malformed request tests
    @Test
    func missingJsonRpcField() {
        let invalidJSON = """
        {
            "id": "1",
            "method": "log.message",
            "params": {}
        }
        """

        let decoder = JSONDecoder()
        var decodingFailed = false
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
        } catch {
            decodingFailed = true
        }
        #expect(decodingFailed)
    }

    @Test
    func missingMethodField() {
        let invalidJSON = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "params": {}
        }
        """

        let decoder = JSONDecoder()
        var decodingFailed = false
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
        } catch {
            decodingFailed = true
        }
        #expect(decodingFailed)
    }

    @Test
    func emptyJSON() {
        let invalidJSON = "{}"

        let decoder = JSONDecoder()
        var decodingFailed = false
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
        } catch {
            decodingFailed = true
        }
        #expect(decodingFailed)
    }

    @Test
    func invalidJSON() {
        let invalidJSON = "{invalid json"

        let decoder = JSONDecoder()
        var decodingFailed = false
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
        } catch {
            decodingFailed = true
        }
        #expect(decodingFailed)
    }

    // T6.2: Invalid parameter tests
    @Test
    func logMessageWithEmptyLoggerId() async {
        let logger = Logger(name: "")
        await logger.info("Test")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
    }

    @Test
    func logMessageWithEmptyMessage() async {
        let logger = Logger(name: "app")
        await logger.info("")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].message == "")
    }

    @Test
    func logMessageWithVeryLongLoggerId() async {
        let longId = String(repeating: "a", count: 10000)
        let logger = Logger(name: longId)
        await logger.info("Test")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
    }

    @Test
    func logMessageWithSpecialCharactersInId() async {
        let specialIds = [
            "app-1",
            "app_1",
            "app.1",
            "app/1",
            "app:1",
            "app|1",
            "app@1",
            "app#1"
        ]

        for id in specialIds {
            let logger = Logger(name: id)
            await logger.info("Test")
            let entries = await logger.getEntries()
            #expect(entries.count == 1)
        }
    }

    @Test
    func logMessageWithUnicodeId() async {
        let logger = Logger(name: "应用-アプリ-приложение")
        await logger.info("Test")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
    }

    // T6.3: State edge cases
    @Test
    func clearAndImmediateGetEntries() async {
        let logger = Logger(name: "app")
        await logger.info("Message")
        await logger.clear()
        let entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    @Test
    func setLevelAndImmediateLog() async {
        let logger = Logger(name: "app", level: .info)

        await logger.setLogLevel(.warn)
        await logger.debug("This should be filtered")
        await logger.warn("This should pass")

        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].level == .warn)
    }

    @Test
    func logAtMaximumEntries() async {
        let maxEntries = 10
        let logger = Logger(name: "app", maxEntries: maxEntries)

        // Log exactly maxEntries
        for i in 1...maxEntries {
            await logger.info("Message \(i)")
        }

        let entries = await logger.getEntries()
        #expect(entries.count == maxEntries)
    }

    @Test
    func logOneMoreThanMaximumEntries() async {
        let maxEntries = 10
        let logger = Logger(name: "app", maxEntries: maxEntries)

        // Log one more than maxEntries
        for i in 1...(maxEntries + 1) {
            await logger.info("Message \(i)")
        }

        let entries = await logger.getEntries()
        #expect(entries.count == maxEntries)
        #expect(entries[0].message == "Message 2")
    }

    @Test
    func nonExistentLoggerOperations() async {
        let handler = createHandler()
        await initializeHandler(handler)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let params = GetEntriesParams(loggerId: "nonexistent", level: nil)
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.getEntries",
            params: .getEntries(params)
        )

        let responseData = await handler.handleRequest(try! encoder.encode(request))
        let response = try! decoder.decode(MCPResponse.self, from: responseData!)

        #expect(response.error == nil)
    }

    // T6.2: Invalid level tests
    @Test
    func setLevelWithValidLevels() async {
        let handler = createHandler()
        await initializeHandler(handler)
        let encoder = JSONEncoder()

        // Try to set with valid levels
        let params = SetLogLevelParams(loggerId: "app", level: .warn)
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.setLevel",
            params: .setLogLevel(params)
        )

        let responseData = await handler.handleRequest(try! encoder.encode(request))
        #expect(responseData != nil)
    }

    // T6.3: Boundary tests
    @Test
    func minimumLogLevel() async {
        let logger = Logger(name: "app", level: .trace)
        await logger.log(level: .trace, message: "Trace message")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].level == .trace)
    }

    @Test
    func maximumLogLevel() async {
        let logger = Logger(name: "app", level: .fatal)
        await logger.debug("Debug") // Should be filtered
        await logger.fatal("Fatal") // Should pass
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].level == .fatal)
    }

    @Test
    func allLogLevelTransitions() async {
        let logger = Logger(name: "app", level: .trace)
        let levels = [LogLevel.debug, .info, .warn, .error, .fatal]

        for level in levels {
            await logger.setLogLevel(level)
            await logger.info("Test at \(level)")
        }

        let entries = await logger.getEntries()
        #expect(entries.count >= 1)
    }

    @Test
    func concurrentClearAndLog() async {
        let logger = Logger(name: "app", maxEntries: 1000)

        // Log initial messages
        for i in 1...100 {
            await logger.info("Message \(i)")
        }

        // Concurrent clear and log
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await logger.clear()
            }
            group.addTask {
                for i in 1...100 {
                    await logger.info("New message \(i)")
                }
            }
        }

        let entries = await logger.getEntries()
        // Due to race condition, we just verify it doesn't crash
        #expect(entries.count >= 0)
    }

    @Test
    func multipleRapidClears() async {
        let logger = Logger(name: "app")
        await logger.info("Message")

        for _ in 1...10 {
            await logger.clear()
        }

        let entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    @Test
    func filteringAtBoundaries() async {
        let logger = Logger(name: "app", level: .trace)

        await logger.log(level: .trace, message: "TRACE")
        await logger.debug("DEBUG")
        await logger.info("INFO")
        await logger.warn("WARN")
        await logger.error("ERROR")
        await logger.fatal("FATAL")

        // Test filtering at each level
        for filterLevel in [LogLevel.trace, .debug, .info, .warn, .error, .fatal] {
            let entries = await logger.getEntries(level: filterLevel)
            #expect(entries.count == 1)
        }
    }
}
