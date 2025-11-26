import XCTest
@testable import Log4MCPLib

final class LoggerTests: XCTestCase {

    // T1.2.1: Create logger instance
    func testCreateLoggerInstance() async {
        let logger = Logger(name: "testLogger", level: .info, maxEntries: 100)
        let entries = await logger.getEntries()
        XCTAssertTrue(entries.isEmpty)
    }

    // T1.2.2: Log message at default level
    func testLogMessageAtDefaultLevel() async {
        let logger = Logger(name: "testLogger")
        await logger.info("Test message")
        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].message, "Test message")
        XCTAssertEqual(entries[0].level, .info)
        XCTAssertEqual(entries[0].logger, "testLogger")
    }

    // T1.2.3: Log message at all levels
    func testLogMessageAtAllLevels() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.log(level: .trace, message: "Trace message")
        await logger.log(level: .debug, message: "Debug message")
        await logger.log(level: .info, message: "Info message")
        await logger.log(level: .warn, message: "Warn message")
        await logger.log(level: .error, message: "Error message")
        await logger.log(level: .fatal, message: "Fatal message")

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 6)
        XCTAssertEqual(entries[0].level, .trace)
        XCTAssertEqual(entries[1].level, .debug)
        XCTAssertEqual(entries[2].level, .info)
        XCTAssertEqual(entries[3].level, .warn)
        XCTAssertEqual(entries[4].level, .error)
        XCTAssertEqual(entries[5].level, .fatal)
    }

    // T1.2.4: Log level filtering
    func testLogLevelFiltering() async {
        let logger = Logger(name: "testLogger", level: .warn)

        await logger.info("Info message") // Should be filtered
        await logger.warn("Warn message") // Should pass
        await logger.error("Error message") // Should pass
        await logger.fatal("Fatal message") // Should pass

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].level, .warn)
        XCTAssertEqual(entries[1].level, .error)
        XCTAssertEqual(entries[2].level, .fatal)
    }

    // T1.2.5: Get all entries
    func testGetAllEntries() async {
        let logger = Logger(name: "testLogger")

        await logger.info("Message 1")
        await logger.warn("Message 2")
        await logger.error("Message 3")
        await logger.debug("Message 4")
        await logger.trace("Message 5")

        let entries = await logger.getEntries(level: nil)
        XCTAssertEqual(entries.count, 5)
    }

    // T1.2.6: Get entries by level
    func testGetEntriesByLevel() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.info("Info 1")
        await logger.warn("Warn 1")
        await logger.error("Error 1")
        await logger.info("Info 2")
        await logger.warn("Warn 2")

        let entries = await logger.getEntries(level: .info)
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.allSatisfy { $0.level == .info })
    }

    // T1.2.7: Clear logger entries
    func testClearLoggerEntries() async {
        let logger = Logger(name: "testLogger")

        await logger.info("Message 1")
        await logger.info("Message 2")
        await logger.info("Message 3")

        var entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 3)

        await logger.clear()
        entries = await logger.getEntries()
        XCTAssertTrue(entries.isEmpty)
    }

    // T1.2.8: Set log level
    func testSetLogLevel() async {
        let logger = Logger(name: "testLogger", level: .info)

        await logger.setLogLevel(.debug)
        await logger.debug("Debug message")

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].level, .debug)
    }

    // T1.2.9: Log entry has correct metadata
    func testLogEntryMetadata() async {
        let logger = Logger(name: "myLogger")
        await logger.info("Test message")

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 1)

        let entry = entries[0]
        XCTAssertEqual(entry.message, "Test message")
        XCTAssertEqual(entry.logger, "myLogger")
        XCTAssertEqual(entry.level, .info)
        XCTAssertNotNil(entry.timestamp)
        XCTAssertFalse(entry.file.isEmpty)
        XCTAssertGreaterThan(entry.line, 0)
        XCTAssertFalse(entry.method.isEmpty)
        XCTAssertFalse(entry.thread.isEmpty)
    }

    // T1.2.10: Log entry rotation (FIFO)
    func testLogEntryRotation() async {
        let logger = Logger(name: "testLogger", maxEntries: 3)

        await logger.info("Message 1")
        await logger.info("Message 2")
        await logger.info("Message 3")
        await logger.info("Message 4")
        await logger.info("Message 5")

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].message, "Message 3")
        XCTAssertEqual(entries[1].message, "Message 4")
        XCTAssertEqual(entries[2].message, "Message 5")
    }

    // T1.2.11: Concurrent logging to same logger
    func testConcurrentLogging() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    await logger.info("Message \(i)")
                }
            }
        }

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 10)
    }

    // T1.2.12: Empty logger state
    func testEmptyLoggerState() async {
        let logger = Logger(name: "emptyLogger")
        let entries = await logger.getEntries()
        XCTAssertTrue(entries.isEmpty)
    }

    // T1.2.5: Get entries with filtering at multiple levels
    func testGetEntriesMultipleLevels() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.trace("Trace")
        await logger.debug("Debug")
        await logger.info("Info")
        await logger.warn("Warn")
        await logger.error("Error")
        await logger.fatal("Fatal")

        let traceEntries = await logger.getEntries(level: .trace)
        XCTAssertEqual(traceEntries.count, 1)

        let warnEntries = await logger.getEntries(level: .warn)
        XCTAssertEqual(warnEntries.count, 1)

        let fatalEntries = await logger.getEntries(level: .fatal)
        XCTAssertEqual(fatalEntries.count, 1)
    }

    // Helper logging methods
    func testHelperLoggingMethods() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.debug("Debug")
        await logger.info("Info")
        await logger.warn("Warn")
        await logger.error("Error")
        await logger.fatal("Fatal")

        let entries = await logger.getEntries()
        XCTAssertEqual(entries.count, 5)
    }
}
