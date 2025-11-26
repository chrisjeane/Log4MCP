import Foundation
import Log4MCPLib

#if os(Linux)
import Glibc
#else
import Darwin
#endif

@main
struct Log4MCPServer {
    static func main() async {
        let config = ServerConfig.fromCommandLine()

        if config.verbose {
            logToStderr("Log4MCP: Starting with configuration")
            logToStderr("  Mode: \(config.mode == .tcp ? "TCP" : "Stdio")")
            logToStderr("  Port: \(config.port)")
            logToStderr("  Host: \(config.host)")
            logToStderr("  Max Entries: \(config.maxLogEntries)")
            logToStderr("  Default Level: \(config.defaultLogLevel.rawValue)")
        }

        let handler = MCPRequestHandler()
        setupSignalHandlers(verbose: config.verbose)

        do {
            switch config.mode {
            case .tcp:
                let server = TCPServer(handler: handler, host: config.host, port: config.port, verbose: config.verbose)
                try await server.start()

            case .stdio:
                let transport = StdioTransport(handler: handler, verbose: config.verbose)
                try await transport.start()
            }
        } catch {
            logToStderr("Error: \(error)")
            exit(1)
        }
    }

    private static func setupSignalHandlers(verbose: Bool) {
        let signalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signalSource.setEventHandler {
            if verbose {
                Log4MCPServer.logToStderr("Log4MCP: Received SIGTERM, shutting down gracefully")
            }
            exit(0)
        }
        signalSource.resume()

        let intSignalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        intSignalSource.setEventHandler {
            if verbose {
                Log4MCPServer.logToStderr("Log4MCP: Received SIGINT, shutting down gracefully")
            }
            exit(0)
        }
        intSignalSource.resume()
    }

    private static func logToStderr(_ message: String) {
        if let data = "\(message)\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
