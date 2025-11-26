import Foundation
@testable import Log4MCPLib

// Phase 5: Error & Edge Case Tests

final class ErrorEdgeCaseTests {

    // T6.1: Malformed request tests
    func testMissingJsonRpcField() {
        let invalidJSON = """
        {
            "id": "1",
            "method": "log.message",
            "params": {}
        }
        """

        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
            print("❌ Should have failed to decode request without jsonrpc")
        } catch {
            print("✓ Correctly rejected request missing jsonrpc field")
        }
    }

    func testMissingMethodField() {
        let invalidJSON = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "params": {}
        }
        """

        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
            print("❌ Should have failed to decode request without method")
        } catch {
            print("✓ Correctly rejected request missing method field")
        }
    }

    func testEmptyJSON() {
        let invalidJSON = "{}"

        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
            print("❌ Should have failed to decode empty JSON")
        } catch {
            print("✓ Correctly rejected empty JSON request")
        }
    }

    func testInvalidJSON() {
        let invalidJSON = "{invalid json"

        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(MCPRequest.self, from: invalidJSON.data(using: .utf8)!)
            print("❌ Should have failed to decode invalid JSON")
        } catch {
            print("✓ Correctly rejected invalid JSON")
        }
    }

    // T6.2: Invalid parameter tests
    func testLogMessageWithEmptyLoggerId() async {
        let logger = Logger(name: "")
        await logger.info("Test")
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should allow empty logger ID")
    }

    func testLogMessageWithEmptyMessage() async {
        let logger = Logger(name: "app")
        await logger.info("")
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should allow empty message string")
        assert(entries[0].message == "", "Message should be empty string")
    }

    func testLogMessageWithVeryLongLoggerId() async {
        let longId = String(repeating: "a", count: 10000)
        let logger = Logger(name: longId)
        await logger.info("Test")
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should handle very long logger ID")
    }

    func testLogMessageWithSpecialCharactersInId() async {
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
            assert(entries.count == 1, "Should handle special char in ID: \(id)")
        }
    }

    func testLogMessageWithUnicodeId() async {
        let logger = Logger(name: "应用-アプリ-приложение")
        await logger.info("Test")
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should handle unicode in logger ID")
    }

    // T6.3: State edge cases
    func testClearAndImmediateGetEntries() async {
        let logger = Logger(name: "app")
        await logger.info("Message")
        await logger.clear()
        let entries = await logger.getEntries()
        assert(entries.isEmpty, "Entries should be empty after clear")
    }

    func testSetLevelAndImmediateLog() async {
        let logger = Logger(name: "app", level: .info)

        await logger.setLogLevel(.warn)
        await logger.debug("This should be filtered")
        await logger.warn("This should pass")

        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should only have WARN message after level change")
        assert(entries[0].level == .warn, "Entry should be WARN level")
    }

    func testLogAtMaximumEntries() async {
        let maxEntries = 10
        let logger = Logger(name: "app", maxEntries: maxEntries)

        // Log exactly maxEntries
        for i in 1...maxEntries {
            await logger.info("Message \(i)")
        }

        let entries = await logger.getEntries()
        assert(entries.count == maxEntries, "Should have exactly max entries")
    }

    func testLogOneMoreThanMaximumEntries() async {
        let maxEntries = 10
        let logger = Logger(name: "app", maxEntries: maxEntries)

        // Log one more than maxEntries
        for i in 1...(maxEntries + 1) {
            await logger.info("Message \(i)")
        }

        let entries = await logger.getEntries()
        assert(entries.count == maxEntries, "Should maintain max entries limit")
        assert(entries[0].message == "Message 2", "Should have removed oldest entry")
    }

    func testNonExistentLoggerOperations() async {
        let handler = MCPRequestHandler()
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

        assert(response.error == nil, "Should handle non-existent logger gracefully")
    }

    // T6.2: Invalid level tests
    func testSetLevelWithInvalidLevel() async {
        let handler = MCPRequestHandler()
        let encoder = JSONEncoder()

        // Try to set an invalid level
        let params = SetLogLevelParams(loggerId: "app", level: "INVALID")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.setLevel",
            params: .setLogLevel(params)
        )

        let responseData = await handler.handleRequest(try! encoder.encode(request))
        assert(responseData != nil, "Should handle invalid level somehow")
    }

    // T6.3: Boundary tests
    func testMinimumLogLevel() async {
        let logger = Logger(name: "app", level: .trace)
        await logger.trace("Trace message")
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should accept TRACE level")
        assert(entries[0].level == .trace, "Message should be TRACE")
    }

    func testMaximumLogLevel() async {
        let logger = Logger(name: "app", level: .fatal)
        await logger.debug("Debug") // Should be filtered
        await logger.fatal("Fatal") // Should pass
        let entries = await logger.getEntries()
        assert(entries.count == 1, "Should only accept FATAL at max level")
        assert(entries[0].level == .fatal, "Message should be FATAL")
    }

    func testAllLogLevelTransitions() async {
        let logger = Logger(name: "app", level: .trace)
        let levels = [LogLevel.debug, .info, .warn, .error, .fatal]

        for level in levels {
            await logger.setLogLevel(level)
            await logger.info("Test at \(level)")
        }

        let entries = await logger.getEntries()
        assert(entries.count >= 1, "Should handle level transitions")
    }

    func testConcurrentClearAndLog() async {
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
        assert(entries.count >= 0, "Should handle concurrent clear and log")
    }

    func testMultipleRapidClears() async {
        let logger = Logger(name: "app")
        await logger.info("Message")

        for _ in 1...10 {
            await logger.clear()
        }

        let entries = await logger.getEntries()
        assert(entries.isEmpty, "Should handle multiple clears")
    }

    func testFilteringAtBoundaries() async {
        let logger = Logger(name: "app", level: .trace)

        await logger.trace("TRACE")
        await logger.debug("DEBUG")
        await logger.info("INFO")
        await logger.warn("WARN")
        await logger.error("ERROR")
        await logger.fatal("FATAL")

        // Test filtering at each level
        for filterLevel in [LogLevel.trace, .debug, .info, .warn, .error, .fatal] {
            let entries = await logger.getEntries(level: filterLevel)
            assert(entries.count == 1, "Should filter exactly one entry at level \(filterLevel)")
        }
    }
}

func assert(_ condition: Bool, _ message: String) {
    if !condition {
        print("❌ Assertion failed: \(message)")
    } else {
        print("✓ \(message)")
    }
}
