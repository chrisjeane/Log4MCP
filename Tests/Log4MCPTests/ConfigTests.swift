import Testing
@testable import Log4MCPLib

struct ConfigTests {

    // T1.1.1: Parse default configuration
    @Test
    func defaultConfiguration() {
        let config = ServerConfig()
        #expect(config.port == 3000)
        #expect(config.host == "0.0.0.0")
        #expect(config.maxLogEntries == 1000)
        #expect(config.defaultLogLevel == .info)
        #expect(config.verbose == false)
        #expect(config.mode == .tcp)
    }

    // T1.1.2: Parse custom port
    @Test
    func customPort() {
        let config = ServerConfig(port: 8080)
        #expect(config.port == 8080)
    }

    // T1.1.3: Parse custom log level
    @Test
    func customLogLevel() {
        let config = ServerConfig(defaultLogLevel: .debug)
        #expect(config.defaultLogLevel == .debug)
    }

    // T1.1.4: Parse max entries
    @Test
    func customMaxEntries() {
        let config = ServerConfig(maxLogEntries: 5000)
        #expect(config.maxLogEntries == 5000)
    }

    // T1.1.5: Parse verbose flag
    @Test
    func verboseFlag() {
        let config = ServerConfig(verbose: true)
        #expect(config.verbose == true)
    }

    // T1.1.7: Multiple arguments parsing
    @Test
    func multipleCustomValues() {
        let config = ServerConfig(
            port: 9000,
            host: "127.0.0.1",
            maxLogEntries: 2000,
            defaultLogLevel: .warn,
            verbose: true,
            mode: .stdio
        )
        #expect(config.port == 9000)
        #expect(config.host == "127.0.0.1")
        #expect(config.maxLogEntries == 2000)
        #expect(config.defaultLogLevel == .warn)
        #expect(config.verbose == true)
        #expect(config.mode == .stdio)
    }

    // T1.1.8: ServerMode enum
    @Test
    func serverModes() {
        let tcpMode = ServerMode.tcp
        let stdioMode = ServerMode.stdio
        #expect(tcpMode != stdioMode)
    }

    // T1.1.6: Port validation (bounds)
    @Test
    func portValidation() {
        let validConfig = ServerConfig(port: 1)
        #expect(validConfig.port == 1)

        let maxPortConfig = ServerConfig(port: 65535)
        #expect(maxPortConfig.port == 65535)
    }

    // T1.1.4: Max entries minimum validation
    @Test
    func maxEntriesValidation() {
        let config = ServerConfig(maxLogEntries: 1)
        #expect(config.maxLogEntries == 1)

        let largeConfig = ServerConfig(maxLogEntries: 1000000)
        #expect(largeConfig.maxLogEntries == 1000000)
    }

    // Test all log levels
    @Test
    func allLogLevels() {
        let levels: [LogLevel] = [.trace, .debug, .info, .warn, .error, .fatal]

        for level in levels {
            let config = ServerConfig(defaultLogLevel: level)
            #expect(config.defaultLogLevel == level)
        }
    }
}
