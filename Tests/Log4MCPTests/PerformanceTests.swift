import Testing
import Foundation
@testable import Log4MCPLib

// Phase 4: Performance & Load Tests

struct PerformanceTests {

    // T4.1.1: Log 10,000 messages to single logger
    @Test func testHighVolumeSingleLogger() async {
        let logger = Logger(name: "highVolume", maxEntries: 10000)
        let messageCount = 10000

        let startTime = Date()

        for i in 1...messageCount {
            await logger.info("Message \(i)")
        }

        let elapsed = Date().timeIntervalSince(startTime)

        let entries = await logger.getEntries()
        #expect(entries.count == messageCount)
        print("✓ Logged \(messageCount) messages in \(String(format: "%.2f", elapsed))s")
    }

    // T4.1.2: Log to 100 different loggers
    @Test func testDistributedLogging() async {
        let loggerCount = 100
        let messagesPerLogger = 100
        var loggers: [Logger] = []

        for i in 0..<loggerCount {
            loggers.append(Logger(name: "logger\(i)"))
        }

        let startTime = Date()

        for (index, logger) in loggers.enumerated() {
            for j in 1...messagesPerLogger {
                await logger.info("Message \(j)")
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)

        var totalEntries = 0
        for logger in loggers {
            let entries = await logger.getEntries()
            totalEntries += entries.count
        }

        #expect(totalEntries == loggerCount * messagesPerLogger)
        print("✓ Logged to \(loggerCount) loggers in \(String(format: "%.2f", elapsed))s")
    }

    // T4.1.3: Log with rotation
    @Test func testLogRotation() async {
        let maxEntries = 100
        let totalMessages = 1000
        let logger = Logger(name: "rotation", maxEntries: maxEntries)

        for i in 1...totalMessages {
            await logger.info("Message \(i)")
        }

        let entries = await logger.getEntries()
        #expect(entries.count == maxEntries)
        #expect(entries.first?.message == "Message \(totalMessages - maxEntries + 1)")
        print("✓ Log rotation maintained \(maxEntries) max entries")
    }

    // T4.1.4: Concurrent logging performance
    @Test func testConcurrentLoggingPerformance() async {
        let logger = Logger(name: "concurrent", maxEntries: 50000)
        let taskCount = 10
        let messagesPerTask = 1000

        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            for taskIndex in 0..<taskCount {
                group.addTask {
                    for i in 1...messagesPerTask {
                        await logger.info("Task \(taskIndex) Message \(i)")
                    }
                }
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)

        let entries = await logger.getEntries()
        #expect(entries.count == taskCount * messagesPerTask)
        print("✓ Logged \(taskCount * messagesPerTask) messages concurrently in \(String(format: "%.2f", elapsed))s")
    }

    // T4.1.5: Response time under load
    @Test func testResponseTimeUnderLoad() async {
        let logger = Logger(name: "loadTest")

        // Warm up
        for _ in 0..<100 {
            await logger.info("Warmup")
        }

        // Measure response times
        var responseTimes: [Double] = []

        for i in 1...100 {
            let startTime = Date()
            await logger.info("Message \(i)")
            let elapsed = Date().timeIntervalSince(startTime)
            responseTimes.append(elapsed)
        }

        let avgResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        let maxResponseTime = responseTimes.max() ?? 0

        #expect(avgResponseTime < 0.01)
        print("✓ Avg response time: \(String(format: "%.4f", avgResponseTime))s, Max: \(String(format: "%.4f", maxResponseTime))s")
    }

    // T4.1.6: Memory stability
    @Test func testMemoryStability() async {
        let logger = Logger(name: "memory", maxEntries: 1000)

        // Log continuously
        for iteration in 1...10 {
            for i in 1...1000 {
                await logger.info("Iteration \(iteration) Message \(i)")
            }

            let entries = await logger.getEntries()
            #expect(entries.count <= 1000)
        }

        print("✓ Memory stability maintained over 10 iterations")
    }

    // T4.2.1: Log message with 1MB text
    @Test func testLargeMessageHandling() async {
        let logger = Logger(name: "largeMsg", maxEntries: 100)

        // Create a 1MB message
        let largeSuffix = String(repeating: "x", count: 1_000_000)
        let message = "Start: \(largeSuffix)"

        let startTime = Date()
        await logger.info(message)
        let elapsed = Date().timeIntervalSince(startTime)

        let entries = await logger.getEntries()
        #expect(entries.count == 1)
        #expect(entries[0].message.count > 1_000_000)
        print("✓ Logged 1MB message in \(String(format: "%.4f", elapsed))s")
    }

    // T4.2.2: Log 100 messages of 100KB each
    @Test func testManyLargeMessages() async {
        let logger = Logger(name: "manyLarge", maxEntries: 200)
        let messageSize = 100_000
        let messageCount = 100

        let largeSuffix = String(repeating: "x", count: messageSize)

        let startTime = Date()

        for i in 1...messageCount {
            await logger.info("Message\(i): \(largeSuffix)")
        }

        let elapsed = Date().timeIntervalSince(startTime)

        let entries = await logger.getEntries()
        #expect(entries.count == messageCount)
        print("✓ Logged \(messageCount) messages of \(messageSize)B in \(String(format: "%.2f", elapsed))s")
    }

    // T4.2.3: Response time with large messages
    @Test func testResponseTimeWithLargeMessages() async {
        let logger = Logger(name: "largeTiming")
        let messageSizes = [10_000, 100_000, 1_000_000]

        for size in messageSizes {
            let message = String(repeating: "x", count: size)

            let startTime = Date()
            await logger.info(message)
            let elapsed = Date().timeIntervalSince(startTime)

            #expect(elapsed < 1.0)
            print("✓ \(size)B message logged in \(String(format: "%.4f", elapsed))s")
        }
    }
}
