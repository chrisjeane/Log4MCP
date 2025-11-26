import Foundation

enum LogLevel: String, Codable {
    case trace = "TRACE"
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    case fatal = "FATAL"

    var priority: Int {
        switch self {
        case .trace: return 0
        case .debug: return 1
        case .info: return 2
        case .warn: return 3
        case .error: return 4
        case .fatal: return 5
        }
    }
}

struct LogEntry: Codable {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let logger: String
    let thread: String
    let file: String
    let line: Int
    let method: String

    init(
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
        self.thread = Thread.current.name ?? "main"
        self.file = (file as NSString).lastPathComponent
        self.line = line
        self.method = function
    }
}

actor Logger {
    private let name: String
    private var level: LogLevel
    private var entries: [LogEntry] = []
    private let maxEntries: Int

    init(name: String, level: LogLevel = .info, maxEntries: Int = 1000) {
        self.name = name
        self.level = level
        self.maxEntries = maxEntries
    }

    func log(
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

    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .debug, message: message, file: file, line: line, function: function)
    }

    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .info, message: message, file: file, line: line, function: function)
    }

    func warn(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .warn, message: message, file: file, line: line, function: function)
    }

    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .error, message: message, file: file, line: line, function: function)
    }

    func fatal(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .fatal, message: message, file: file, line: line, function: function)
    }

    func getEntries(level: LogLevel? = nil) -> [LogEntry] {
        if let level = level {
            return entries.filter { $0.level == level }
        }
        return entries
    }

    func clear() {
        entries.removeAll()
    }

    func setLogLevel(_ newLevel: LogLevel) {
        self.level = newLevel
    }

    private func printEntry(_ entry: LogEntry) {
        let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
        let logLine = "[\(timestamp)] [\(entry.level.rawValue)] [\(entry.logger)] \(entry.file):\(entry.line) - \(entry.message)"
        print(logLine)
    }
}
