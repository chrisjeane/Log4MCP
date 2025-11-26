import Foundation
import MCPServer

// Add convenience property to LogLevel
extension LogLevel {
    public var priority: Int {
        self.sortOrder
    }
}

// Extended LogEntry with additional fields
public struct LogEntry: Codable, Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let logger: String
    public let thread: String
    public let file: String
    public let line: Int
    public let method: String

    public init(
        level: LogLevel,
        message: String,
        logger: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.logger = logger
        let threadName = Thread.current.name ?? ""
        self.thread = threadName.isEmpty ? "main" : threadName
        self.file = (file as NSString).lastPathComponent
        self.line = line
        self.method = function
    }
}

public actor Logger {
    private let name: String
    private var level: LogLevel
    private var entries: [LogEntry] = []
    private let maxEntries: Int

    public init(name: String, level: LogLevel = .info, maxEntries: Int = 1000) {
        self.name = name
        self.level = level
        self.maxEntries = maxEntries
    }

    public func log(
        level: LogLevel,
        message: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        guard level.priority >= self.level.priority else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            logger: name,
            file: file,
            line: line,
            function: function
        )

        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst()
        }

        printEntry(entry)
    }

    public func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .debug, message: message, file: file, line: line, function: function)
    }

    public func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .info, message: message, file: file, line: line, function: function)
    }

    public func warn(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .warn, message: message, file: file, line: line, function: function)
    }

    public func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .error, message: message, file: file, line: line, function: function)
    }

    public func fatal(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .fatal, message: message, file: file, line: line, function: function)
    }

    public func getEntries(level: LogLevel? = nil) -> [LogEntry] {
        if let level = level {
            return entries.filter { $0.level == level }
        }
        return entries
    }

    public func clear() {
        entries.removeAll()
    }

    public func setLogLevel(_ newLevel: LogLevel) {
        self.level = newLevel
    }

    private func printEntry(_ entry: LogEntry) {
        let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
        let logLine = "[\(timestamp)] [\(entry.level.rawValue)] [\(entry.logger)] \(entry.file):\(entry.line) - \(entry.message)"
        print(logLine)
    }
}
