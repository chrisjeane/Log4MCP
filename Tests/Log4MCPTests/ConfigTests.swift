import XCTest
@testable import Log4MCPLib

final class ConfigTests: XCTestCase {

    // T1.1.1: Parse default configuration
    func testDefaultConfiguration() {
        let config = ServerConfig()
        XCTAssertEqual(config.port, 3000)
        XCTAssertEqual(config.host, "0.0.0.0")
        XCTAssertEqual(config.maxLogEntries, 1000)
        XCTAssertEqual(config.defaultLogLevel, .info)
        XCTAssertFalse(config.verbose)
        XCTAssertEqual(config.mode, .tcp)
    }

    // T1.1.2: Parse custom port
    func testCustomPort() {
        let config = ServerConfig(port: 8080)
        XCTAssertEqual(config.port, 8080)
    }

    // T1.1.3: Parse custom log level
    func testCustomLogLevel() {
        let config = ServerConfig(defaultLogLevel: .debug)
        XCTAssertEqual(config.defaultLogLevel, .debug)
    }

    // T1.1.4: Parse max entries
    func testCustomMaxEntries() {
        let config = ServerConfig(maxLogEntries: 5000)
        XCTAssertEqual(config.maxLogEntries, 5000)
    }

    // T1.1.5: Parse verbose flag
    func testVerboseFlag() {
        let config = ServerConfig(verbose: true)
        XCTAssertTrue(config.verbose)
    }

    // T1.1.7: Multiple arguments parsing
    func testMultipleCustomValues() {
        let config = ServerConfig(
            port: 9000,
            host: "127.0.0.1",
            maxLogEntries: 2000,
            defaultLogLevel: .warn,
            verbose: true,
            mode: .stdio
        )
        XCTAssertEqual(config.port, 9000)
        XCTAssertEqual(config.host, "127.0.0.1")
        XCTAssertEqual(config.maxLogEntries, 2000)
        XCTAssertEqual(config.defaultLogLevel, .warn)
        XCTAssertTrue(config.verbose)
        XCTAssertEqual(config.mode, .stdio)
    }

    // T1.1.8: ServerMode enum
    func testServerModes() {
        let tcpMode = ServerMode.tcp
        let stdioMode = ServerMode.stdio
        XCTAssertNotEqual(tcpMode, stdioMode)
    }

    // T1.1.6: Port validation (bounds)
    func testPortValidation() {
        let validConfig = ServerConfig(port: 1)
        XCTAssertEqual(validConfig.port, 1)

        let maxPortConfig = ServerConfig(port: 65535)
        XCTAssertEqual(maxPortConfig.port, 65535)
    }

    // T1.1.4: Max entries minimum validation
    func testMaxEntriesValidation() {
        let config = ServerConfig(maxLogEntries: 1)
        XCTAssertEqual(config.maxLogEntries, 1)

        let largeConfig = ServerConfig(maxLogEntries: 1000000)
        XCTAssertEqual(largeConfig.maxLogEntries, 1000000)
    }

    // Test all log levels
    func testAllLogLevels() {
        let levels: [LogLevel] = [.trace, .debug, .info, .warn, .error, .fatal]

        for level in levels {
            let config = ServerConfig(defaultLogLevel: level)
            XCTAssertEqual(config.defaultLogLevel, level)
        }
    }
}
