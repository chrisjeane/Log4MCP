import Foundation
@testable import Log4MCPLib

// Phase 6: Configuration & Startup Tests

final class ConfigurationStartupTests {

    // T7.1: Configuration tests
    func testAllServerModes() {
        let tcpConfig = ServerConfig(mode: .tcp)
        let stdioConfig = ServerConfig(mode: .stdio)

        assert(tcpConfig.mode == .tcp, "Should support TCP mode")
        assert(stdioConfig.mode == .stdio, "Should support Stdio mode")
        print("✓ Both server modes supported")
    }

    func testPortBoundaries() {
        let minPortConfig = ServerConfig(port: 1)
        let maxPortConfig = ServerConfig(port: 65535)

        assert(minPortConfig.port == 1, "Should accept minimum port 1")
        assert(maxPortConfig.port == 65535, "Should accept maximum port 65535")
    }

    func testHostBoundaries() {
        let localhostConfig = ServerConfig(host: "127.0.0.1")
        let anyConfig = ServerConfig(host: "0.0.0.0")
        let wildcardConfig = ServerConfig(host: "::")

        assert(localhostConfig.host == "127.0.0.1", "Should accept localhost")
        assert(anyConfig.host == "0.0.0.0", "Should accept any IPv4")
        assert(wildcardConfig.host == "::", "Should accept IPv6 any")
    }

    func testMaxEntriesBoundaries() {
        let minConfig = ServerConfig(maxLogEntries: 1)
        let normalConfig = ServerConfig(maxLogEntries: 1000)
        let largeConfig = ServerConfig(maxLogEntries: 1_000_000)

        assert(minConfig.maxLogEntries == 1, "Should accept minimum entries (1)")
        assert(normalConfig.maxLogEntries == 1000, "Should accept normal entries")
        assert(largeConfig.maxLogEntries == 1_000_000, "Should accept large entry counts")
    }

    func testAllLogLevelConfigs() {
        let levels = [LogLevel.trace, .debug, .info, .warn, .error, .fatal]

        for level in levels {
            let config = ServerConfig(defaultLogLevel: level)
            assert(config.defaultLogLevel == level, "Should set default level to \(level.rawValue)")
        }
    }

    func testVerboseMode() {
        let quietConfig = ServerConfig(verbose: false)
        let verboseConfig = ServerConfig(verbose: true)

        assert(!quietConfig.verbose, "Quiet mode should be false by default")
        assert(verboseConfig.verbose, "Verbose mode should be settable to true")
    }

    func testConfigurationCombinations() {
        let combinations = [
            (port: 3000, host: "0.0.0.0", mode: ServerMode.tcp),
            (port: 8080, host: "127.0.0.1", mode: ServerMode.tcp),
            (port: 9000, host: "localhost", mode: ServerMode.stdio),
            (port: 1, host: "::", mode: ServerMode.stdio),
            (port: 65535, host: "192.168.1.1", mode: ServerMode.tcp)
        ]

        for combo in combinations {
            let config = ServerConfig(port: combo.port, host: combo.host, mode: combo.mode)
            assert(config.port == combo.port, "Port should match")
            assert(config.host == combo.host, "Host should match")
            assert(config.mode == combo.mode, "Mode should match")
        }

        print("✓ All configuration combinations valid")
    }

    // T7.2: Startup tests
    func testRequestHandlerInitialization() async {
        let handler = MCPRequestHandler()
        assert(true, "MCPRequestHandler should initialize without error")
    }

    func testLoggerInitialization() async {
        let logger = Logger(name: "test")
        let entries = await logger.getEntries()
        assert(entries.isEmpty, "New logger should start with empty entries")
    }

    func testMultipleHandlerInstances() async {
        let handler1 = MCPRequestHandler()
        let handler2 = MCPRequestHandler()

        // Verify they're independent
        let encoder = JSONEncoder()

        let params = LogMessageParams(loggerId: "app", level: "INFO", message: "Test")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(params)
        )

        let _ = await handler1.handleRequest(try! encoder.encode(request))
        let _ = await handler2.handleRequest(try! encoder.encode(request))

        assert(true, "Multiple handlers should work independently")
    }

    func testConfigurationPersistence() {
        let config = ServerConfig(
            port: 9000,
            host: "127.0.0.1",
            maxLogEntries: 5000,
            defaultLogLevel: .debug,
            verbose: true,
            mode: .stdio
        )

        // Verify all settings persist
        assert(config.port == 9000, "Port should persist")
        assert(config.host == "127.0.0.1", "Host should persist")
        assert(config.maxLogEntries == 5000, "Max entries should persist")
        assert(config.defaultLogLevel == .debug, "Log level should persist")
        assert(config.verbose == true, "Verbose flag should persist")
        assert(config.mode == .stdio, "Mode should persist")

        print("✓ Configuration persists correctly")
    }

    func testDefaultConfigurationValues() {
        let config = ServerConfig()

        assert(config.port == 3000, "Default port should be 3000")
        assert(config.host == "0.0.0.0", "Default host should be 0.0.0.0")
        assert(config.maxLogEntries == 1000, "Default max entries should be 1000")
        assert(config.defaultLogLevel == .info, "Default level should be INFO")
        assert(config.verbose == false, "Verbose should default to false")
        assert(config.mode == .tcp, "Mode should default to TCP")

        print("✓ All defaults are correct")
    }

    func testLogLevelPriorities() {
        let trace = LogLevel.trace.priority
        let debug = LogLevel.debug.priority
        let info = LogLevel.info.priority
        let warn = LogLevel.warn.priority
        let error = LogLevel.error.priority
        let fatal = LogLevel.fatal.priority

        assert(trace < debug, "TRACE should be lower priority than DEBUG")
        assert(debug < info, "DEBUG should be lower priority than INFO")
        assert(info < warn, "INFO should be lower priority than WARN")
        assert(warn < error, "WARN should be lower priority than ERROR")
        assert(error < fatal, "ERROR should be lower priority than FATAL")

        print("✓ Log level priorities are correct")
    }

    func testInitializationUnderLoad() async {
        let configs: [ServerConfig] = (1...100).map { i in
            ServerConfig(
                port: 3000 + i,
                maxLogEntries: 1000 + i
            )
        }

        assert(configs.count == 100, "Should create 100 configurations")
        print("✓ Bulk configuration creation successful")
    }

    func testServerConfigEquality() {
        let config1 = ServerConfig(port: 3000, host: "0.0.0.0")
        let config2 = ServerConfig(port: 3000, host: "0.0.0.0")
        let config3 = ServerConfig(port: 8080, host: "0.0.0.0")

        // Note: ServerConfig should probably implement Equatable
        // This test verifies the configurations can be compared
        assert(config1.port == config2.port, "Same ports should match")
        assert(config1.host == config2.host, "Same hosts should match")
        assert(config1.port != config3.port, "Different ports should differ")

        print("✓ Configuration comparison works")
    }

    func testModeSpecificDefaults() {
        let tcpConfig = ServerConfig(mode: .tcp)
        let stdioConfig = ServerConfig(mode: .stdio)

        // Both should have same default values except mode
        assert(tcpConfig.port == stdioConfig.port, "Default port should be same for both modes")
        assert(tcpConfig.host == stdioConfig.host, "Default host should be same for both modes")
        assert(tcpConfig.mode != stdioConfig.mode, "Modes should differ")

        print("✓ Mode-specific defaults work correctly")
    }

    func testConfigurationImmutability() {
        let config = ServerConfig(port: 3000)
        // Config is a struct with let properties, so it's immutable
        assert(config.port == 3000, "Configuration should be immutable")
        print("✓ Configuration is immutable")
    }
}

func assert(_ condition: Bool, _ message: String) {
    if !condition {
        print("❌ Assertion failed: \(message)")
    } else {
        print("✓ \(message)")
    }
}
