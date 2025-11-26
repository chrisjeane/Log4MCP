import Foundation
import MCPServer

public enum ServerMode {
    case tcp
    case stdio
}

public struct ServerConfig {
    public let port: Int
    public let host: String
    public let maxLogEntries: Int
    public let defaultLogLevel: LogLevel
    public let verbose: Bool
    public let mode: ServerMode

    public init(port: Int = 3000, host: String = "0.0.0.0", maxLogEntries: Int = 1000, defaultLogLevel: LogLevel = .info, verbose: Bool = false, mode: ServerMode = .tcp) {
        self.port = port
        self.host = host
        self.maxLogEntries = maxLogEntries
        self.defaultLogLevel = defaultLogLevel
        self.verbose = verbose
        self.mode = mode
    }

    public static func fromCommandLine() -> ServerConfig {
        var port = 3000
        var host = "0.0.0.0"
        var maxLogEntries = 1000
        var defaultLogLevel = LogLevel.info
        var verbose = false
        var mode: ServerMode = .tcp

        let arguments = CommandLine.arguments
        var i = 1
        while i < arguments.count {
            let arg = arguments[i]

            switch arg {
            case "-p", "--port":
                if i + 1 < arguments.count, let p = Int(arguments[i + 1]) {
                    guard p > 0 && p <= 65535 else {
                        print("Error: Port must be between 1 and 65535")
                        exit(1)
                    }
                    port = p
                    i += 2
                } else {
                    print("Error: --port requires an integer value")
                    exit(1)
                }

            case "-h", "--host":
                if i + 1 < arguments.count {
                    let h = arguments[i + 1]
                    guard !h.isEmpty else {
                        print("Error: Host cannot be empty")
                        exit(1)
                    }
                    host = h
                    i += 2
                } else {
                    print("Error: --host requires a value")
                    exit(1)
                }

            case "-m", "--max-entries":
                if i + 1 < arguments.count, let m = Int(arguments[i + 1]) {
                    guard m > 0 else {
                        print("Error: Max entries must be greater than 0")
                        exit(1)
                    }
                    maxLogEntries = m
                    i += 2
                } else {
                    print("Error: --max-entries requires an integer value")
                    exit(1)
                }

            case "-l", "--log-level":
                if i + 1 < arguments.count {
                    let levelStr = arguments[i + 1].uppercased()
                    if let level = LogLevel(rawValue: levelStr) {
                        defaultLogLevel = level
                        i += 2
                    } else {
                        print("Error: Invalid log level. Valid levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL")
                        exit(1)
                    }
                } else {
                    print("Error: --log-level requires a value")
                    exit(1)
                }

            case "-v", "--verbose":
                verbose = true
                i += 1

            case "--stdio":
                mode = .stdio
                i += 1

            case "--help":
                printHelp()
                exit(0)

            default:
                print("Error: Unknown argument: \(arg)")
                printHelp()
                exit(1)
            }
        }

        return ServerConfig(
            port: port,
            host: host,
            maxLogEntries: maxLogEntries,
            defaultLogLevel: defaultLogLevel,
            verbose: verbose,
            mode: mode
        )
    }

    private static func printHelp() {
        print("""
        Log4MCP - Model Context Protocol Server for Logging

        Usage: Log4MCP [OPTIONS]

        Options:
          -p, --port PORT              Port to listen on (default: 3000)
          -h, --host HOST              Host to bind to (default: 0.0.0.0)
          -m, --max-entries NUM        Maximum log entries per logger (default: 1000)
          -l, --log-level LEVEL        Default log level (default: INFO)
                                       Valid levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
          -v, --verbose                Enable verbose output
          --stdio                      Use stdio mode instead of TCP server (default: TCP)
          --help                       Show this help message

        Server Modes:
          TCP (default)  - Listens on specified host:port for connections
          Stdio          - Reads JSON-RPC requests from stdin, writes responses to stdout

        Examples:
          Log4MCP --port 8080 --log-level DEBUG --verbose
          Log4MCP --stdio --log-level DEBUG --verbose
        """)
    }
}
