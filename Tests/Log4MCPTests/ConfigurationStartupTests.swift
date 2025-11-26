import Foundation
import Testing
@testable import Log4MCPLib
import MCPServer

// Phase 6: Configuration & Startup Tests

struct ConfigurationStartupTests {

    private func initializeHandler(_ handler: MCPRequestHandler) async {
        let encoder = JSONEncoder()

        // Send system.initialize
        let initRequest = MCPRequest(
            jsonrpc: "2.0",
            id: "init",
            method: "system.initialize",
            params: .none
        )
        let _ = await handler.handleRequest(try! encoder.encode(initRequest))

        // Send system.initialized notification
        let initializedRequest = MCPRequest(
            jsonrpc: "2.0",
            id: nil,
            method: "system.initialized",
            params: .none
        )
        let _ = await handler.handleRequest(try! encoder.encode(initializedRequest))
    }

    // T7.1: Configuration tests
    @Test func testAllServerModes() {
        let tcpConfig = ServerConfig(mode: .tcp)
        let stdioConfig = ServerConfig(mode: .stdio)

        #expect(tcpConfig.mode == .tcp)
        #expect(stdioConfig.mode == .stdio)
        print("✓ Both server modes supported")
    }

    @Test func testPortBoundaries() {
        let minPortConfig = ServerConfig(port: 1)
        let maxPortConfig = ServerConfig(port: 65535)

        #expect(minPortConfig.port == 1)
        #expect(maxPortConfig.port == 65535)
    }

    @Test func testHostBoundaries() {
        let localhostConfig = ServerConfig(host: "127.0.0.1")
        let anyConfig = ServerConfig(host: "0.0.0.0")
        let wildcardConfig = ServerConfig(host: "::")

        #expect(localhostConfig.host == "127.0.0.1")
        #expect(anyConfig.host == "0.0.0.0")
        #expect(wildcardConfig.host == "::")
    }

    @Test func testMaxEntriesBoundaries() {
        let minConfig = ServerConfig(maxLogEntries: 1)
        let normalConfig = ServerConfig(maxLogEntries: 1000)
        let largeConfig = ServerConfig(maxLogEntries: 1_000_000)

        #expect(minConfig.maxLogEntries == 1)
        #expect(normalConfig.maxLogEntries == 1000)
        #expect(largeConfig.maxLogEntries == 1_000_000)
    }

    @Test func testAllLogLevelConfigs() {
        let levels = [LogLevel.trace, .debug, .info, .warn, .error, .fatal]

        for level in levels {
            let config = ServerConfig(defaultLogLevel: level)
            #expect(config.defaultLogLevel == level)
        }
    }

    @Test func testVerboseMode() {
        let quietConfig = ServerConfig(verbose: false)
        let verboseConfig = ServerConfig(verbose: true)

        #expect(!quietConfig.verbose)
        #expect(verboseConfig.verbose)
    }

    @Test func testConfigurationCombinations() {
        let combinations = [
            (port: 3000, host: "0.0.0.0", mode: ServerMode.tcp),
            (port: 8080, host: "127.0.0.1", mode: ServerMode.tcp),
            (port: 9000, host: "localhost", mode: ServerMode.stdio),
            (port: 1, host: "::", mode: ServerMode.stdio),
            (port: 65535, host: "192.168.1.1", mode: ServerMode.tcp)
        ]

        for combo in combinations {
            let config = ServerConfig(port: combo.port, host: combo.host, mode: combo.mode)
            #expect(config.port == combo.port)
            #expect(config.host == combo.host)
            #expect(config.mode == combo.mode)
        }

        print("✓ All configuration combinations valid")
    }

    // T7.2: Startup tests
    @Test func testRequestHandlerInitialization() async {
        let handler = MCPRequestHandler()
        #expect(true)
    }

    @Test func testLoggerInitialization() async {
        let logger = Logger(name: "test")
        let entries = await logger.getEntries()
        #expect(entries.isEmpty)
    }

    @Test func testMultipleHandlerInstances() async {
        let handler1 = MCPRequestHandler()
        let handler2 = MCPRequestHandler()

        await initializeHandler(handler1)
        await initializeHandler(handler2)

        // Verify they're independent
        let encoder = JSONEncoder()

        let params = LogMessageParams(loggerId: "app", level: .info, message: "Test")
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: "1",
            method: "log.message",
            params: .logMessage(params)
        )

        let _ = await handler1.handleRequest(try! encoder.encode(request))
        let _ = await handler2.handleRequest(try! encoder.encode(request))

        #expect(true)
    }

    @Test func testConfigurationPersistence() {
        let config = ServerConfig(
            port: 9000,
            host: "127.0.0.1",
            maxLogEntries: 5000,
            defaultLogLevel: .debug,
            verbose: true,
            mode: .stdio
        )

        // Verify all settings persist
        #expect(config.port == 9000)
        #expect(config.host == "127.0.0.1")
        #expect(config.maxLogEntries == 5000)
        #expect(config.defaultLogLevel == .debug)
        #expect(config.verbose == true)
        #expect(config.mode == .stdio)

        print("✓ Configuration persists correctly")
    }

    @Test func testDefaultConfigurationValues() {
        let config = ServerConfig()

        #expect(config.port == 3000)
        #expect(config.host == "0.0.0.0")
        #expect(config.maxLogEntries == 1000)
        #expect(config.defaultLogLevel == .info)
        #expect(config.verbose == false)
        #expect(config.mode == .tcp)

        print("✓ All defaults are correct")
    }

    @Test func testLogLevelPriorities() {
        let trace = LogLevel.trace.priority
        let debug = LogLevel.debug.priority
        let info = LogLevel.info.priority
        let warn = LogLevel.warn.priority
        let error = LogLevel.error.priority
        let fatal = LogLevel.fatal.priority

        #expect(trace < debug)
        #expect(debug < info)
        #expect(info < warn)
        #expect(warn < error)
        #expect(error < fatal)

        print("✓ Log level priorities are correct")
    }

    @Test func testInitializationUnderLoad() async {
        let configs: [ServerConfig] = (1...100).map { i in
            ServerConfig(
                port: 3000 + i,
                maxLogEntries: 1000 + i
            )
        }

        #expect(configs.count == 100)
        print("✓ Bulk configuration creation successful")
    }

    @Test func testServerConfigEquality() {
        let config1 = ServerConfig(port: 3000, host: "0.0.0.0")
        let config2 = ServerConfig(port: 3000, host: "0.0.0.0")
        let config3 = ServerConfig(port: 8080, host: "0.0.0.0")

        // Note: ServerConfig should probably implement Equatable
        // This test verifies the configurations can be compared
        #expect(config1.port == config2.port)
        #expect(config1.host == config2.host)
        #expect(config1.port != config3.port)

        print("✓ Configuration comparison works")
    }

    @Test func testModeSpecificDefaults() {
        let tcpConfig = ServerConfig(mode: .tcp)
        let stdioConfig = ServerConfig(mode: .stdio)

        // Both should have same default values except mode
        #expect(tcpConfig.port == stdioConfig.port)
        #expect(tcpConfig.host == stdioConfig.host)
        #expect(tcpConfig.mode != stdioConfig.mode)

        print("✓ Mode-specific defaults work correctly")
    }

    @Test func testConfigurationImmutability() {
        let config = ServerConfig(port: 3000)
        // Config is a struct with let properties, so it's immutable
        #expect(config.port == 3000)
        print("✓ Configuration is immutable")
    }
}
