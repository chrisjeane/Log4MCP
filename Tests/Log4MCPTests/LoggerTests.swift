import Foundation
import Testing
@testable import Log4MCPLib

struct LoggerTests {

    // T1.2.1: Create logger instance
    @Test
    func createLoggerInstance() async {
        let logger = Logger(name: "testLogger", level: .info, maxEntries: 100)
        let entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    // T1.2.2: Log message at default level
    @Test
    func logMessageAtDefaultLevel() async {
        let logger = Logger(name: "testLogger")
        await logger.info("Test message")
        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].message == "Test message")
        #expect(entries[0].level == .info)
        #expect(entries[0].logger == "testLogger")
    }

    // T1.2.3: Log message at all levels
    @Test
    func logMessageAtAllLevels() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.log(level: .trace, message: "Trace message")
        await logger.log(level: .debug, message: "Debug message")
        await logger.log(level: .info, message: "Info message")
        await logger.log(level: .warn, message: "Warn message")
        await logger.log(level: .error, message: "Error message")
        await logger.log(level: .fatal, message: "Fatal message")

        let entries = await logger.getEntries()
        #expect(entries.count == 6)
        #expect(entries[0].level == .trace)
        #expect(entries[1].level == .debug)
        #expect(entries[2].level == .info)
        #expect(entries[3].level == .warn)
        #expect(entries[4].level == .error)
        #expect(entries[5].level == .fatal)
    }

    // T1.2.4: Log level filtering
    @Test
    func logLevelFiltering() async {
        let logger = Logger(name: "testLogger", level: .warn)

        await logger.info("Info message") // Should be filtered
        await logger.warn("Warn message") // Should pass
        await logger.error("Error message") // Should pass
        await logger.fatal("Fatal message") // Should pass

        let entries = await logger.getEntries()
        #expect(entries.count == 3)
        #expect(entries[0].level == .warn)
        #expect(entries[1].level == .error)
        #expect(entries[2].level == .fatal)
    }

    // T1.2.5: Get all entries
    @Test
    func getAllEntries() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.info("Message 1")
        await logger.warn("Message 2")
        await logger.error("Message 3")
        await logger.debug("Message 4")
        await logger.log(level: .trace, message: "Message 5")

        let entries = await logger.getEntries(level: nil)
        #expect(entries.count == 5)
    }

    // T1.2.6: Get entries by level
    @Test
    func getEntriesByLevel() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.info("Info 1")
        await logger.warn("Warn 1")
        await logger.error("Error 1")
        await logger.info("Info 2")
        await logger.warn("Warn 2")

        let entries = await logger.getEntries(level: .info)
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.level == .info })
    }

    // T1.2.7: Clear logger entries
    @Test
    func clearLoggerEntries() async {
        let logger = Logger(name: "testLogger")

        await logger.info("Message 1")
        await logger.info("Message 2")
        await logger.info("Message 3")

        var entries = await logger.getEntries()
        #expect(entries.count == 3)

        await logger.clear()
        entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    // T1.2.8: Set log level
    @Test
    func setLogLevel() async {
        let logger = Logger(name: "testLogger", level: .info)

        await logger.setLogLevel(.debug)
        await logger.debug("Debug message")

        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].level == .debug)
    }

    // T1.2.9: Log entry has correct metadata
    @Test
    func logEntryMetadata() async {
        let logger = Logger(name: "myLogger")
        await logger.info("Test message")

        let entries = await logger.getEntries()
        #expect(entries.count == 1)

        let entry = entries[0]
        #expect(entry.message == "Test message")
        #expect(entry.logger == "myLogger")
        #expect(entry.level == .info)
        #expect(entry.timestamp != nil)
        #expect(!entry.file.isEmpty)
        #expect(entry.line > 0)
        #expect(!entry.method.isEmpty)
        #expect(!entry.thread.isEmpty)
    }

    // T1.2.10: Log entry rotation (FIFO)
    @Test
    func logEntryRotation() async {
        let logger = Logger(name: "testLogger", maxEntries: 3)

        await logger.info("Message 1")
        await logger.info("Message 2")
        await logger.info("Message 3")
        await logger.info("Message 4")
        await logger.info("Message 5")

        let entries = await logger.getEntries()
        #expect(entries.count == 3)
        #expect(entries[0].message == "Message 3")
        #expect(entries[1].message == "Message 4")
        #expect(entries[2].message == "Message 5")
    }

    // T1.2.11: Concurrent logging to same logger
    @Test
    func concurrentLogging() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    await logger.info("Message \(i)")
                }
            }
        }

        let entries = await logger.getEntries()
        #expect(entries.count == 10)
    }

    // T1.2.12: Empty logger state
    @Test
    func emptyLoggerState() async {
        let logger = Logger(name: "emptyLogger")
        let entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    // T1.2.5: Get entries with filtering at multiple levels
    @Test
    func getEntriesMultipleLevels() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.log(level: .trace, message: "Trace")
        await logger.debug("Debug")
        await logger.info("Info")
        await logger.warn("Warn")
        await logger.error("Error")
        await logger.fatal("Fatal")

        let traceEntries = await logger.getEntries(level: .trace)
        #expect(traceEntries.count == 1)

        let warnEntries = await logger.getEntries(level: .warn)
        #expect(warnEntries.count == 1)

        let fatalEntries = await logger.getEntries(level: .fatal)
        #expect(fatalEntries.count == 1)
    }

    // Helper logging methods
    @Test
    func helperLoggingMethods() async {
        let logger = Logger(name: "testLogger", level: .trace)

        await logger.debug("Debug")
        await logger.info("Info")
        await logger.warn("Warn")
        await logger.error("Error")
        await logger.fatal("Fatal")

        let entries = await logger.getEntries()
        #expect(entries.count == 5)
    }
}
