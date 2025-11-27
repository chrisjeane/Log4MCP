import Foundation
import MCPServer

/// Actor responsible for managing the lifecycle of logger instances.
///
/// LoggerRegistry maintains a thread-safe registry of logger instances, creating them
/// on-demand and managing their lifecycle. All operations are serialized through
/// Swift's actor isolation mechanism, ensuring thread safety without explicit locks.
public actor LoggerRegistry {
    private var loggers: [String: Logger] = [:]
    private let config: ServerConfig

    /// Creates a new logger registry with the specified configuration.
    ///
    /// - Parameter config: Server configuration containing default log level and max entries
    public init(config: ServerConfig) {
        self.config = config
    }

    /// Retrieves an existing logger or creates a new one if it doesn't exist.
    ///
    /// Logger instances are created lazily on first access. The logger will be configured
    /// with the registry's default log level and maximum entries settings.
    ///
    /// - Parameter id: Unique identifier for the logger
    /// - Returns: Logger instance for the specified ID
    public func getLogger(id: String) -> Logger {
        if let logger = loggers[id] {
            return logger
        }
        let logger = Logger(
            name: id,
            level: config.defaultLogLevel,
            maxEntries: config.maxLogEntries
        )
        loggers[id] = logger
        return logger
    }

    /// Removes a logger from the registry.
    ///
    /// Once removed, subsequent calls to getLogger with the same ID will create
    /// a fresh logger instance.
    ///
    /// - Parameter id: Unique identifier of the logger to remove
    public func removeLogger(id: String) {
        loggers.removeValue(forKey: id)
    }

    /// Returns the total number of loggers currently registered.
    ///
    /// - Returns: Number of active logger instances
    public func loggerCount() -> Int {
        return loggers.count
    }
}
