import Foundation

// MARK: - MCP Protocol Constants

let MCP_PROTOCOL_VERSION = "2024-11-05"

// MARK: - MCP Capabilities

struct MCPCapabilities: Codable {
    struct Logging: Codable {
        let level: Bool

        init(level: Bool = true) {
            self.level = level
        }
    }

    let logging: Logging

    init(logging: Logging = Logging()) {
        self.logging = logging
    }
}

// MARK: - Server Info

struct ServerInfo: Codable {
    let name: String
    let version: String

    init(name: String = "Log4MCP", version: String = "2.0.0") {
        self.name = name
        self.version = version
    }
}

// MARK: - Protocol Messages

struct MCPRequest: Codable {
    let jsonrpc: String = "2.0"
    let id: String?  // Optional for notifications (system.initialized)
    let method: String
    let params: MCPParams?

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)  // Optional decode
        self.method = try container.decode(String.self, forKey: .method)

        if container.contains(.params) {
            let paramsDecoder = try container.superDecoder(forKey: .params)
            self.params = try MCPParams(from: paramsDecoder, method: self.method)
        } else {
            self.params = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("2.0", forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)  // Encode if present
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

enum MCPParams: Codable {
    case logMessage(LogMessageParams)
    case getEntries(GetEntriesParams)
    case clearLogs(ClearLogsParams)
    case setLogLevel(SetLogLevelParams)
    case none  // For methods that don't require params (system.*, etc)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.message) {
            let params = try LogMessageParams(from: decoder)
            self = .logMessage(params)
        } else if container.contains(.loggerId) {
            let params = try GetEntriesParams(from: decoder)
            self = .getEntries(params)
        } else if container.contains(.level) {
            let params = try SetLogLevelParams(from: decoder)
            self = .setLogLevel(params)
        } else {
            let params = try ClearLogsParams(from: decoder)
            self = .clearLogs(params)
        }
    }

    init(from decoder: Decoder, method: String) throws {
        switch method {
        case "log.message":
            let params = try LogMessageParams(from: decoder)
            self = .logMessage(params)
        case "log.getEntries":
            let params = try GetEntriesParams(from: decoder)
            self = .getEntries(params)
        case "log.setLevel":
            let params = try SetLogLevelParams(from: decoder)
            self = .setLogLevel(params)
        case "log.clear":
            let params = try ClearLogsParams(from: decoder)
            self = .clearLogs(params)
        case "system.initialize", "system.capabilities", "system.initialized":
            // These methods don't require params
            self = .none
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown method type for params"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .logMessage(let params):
            try params.encode(to: encoder)
        case .getEntries(let params):
            try params.encode(to: encoder)
        case .clearLogs(let params):
            try params.encode(to: encoder)
        case .setLogLevel(let params):
            try params.encode(to: encoder)
        case .none:
            // No params to encode
            break
        }
    }

    enum CodingKeys: String, CodingKey {
        case message
        case loggerId
        case level
    }
}

struct LogMessageParams: Codable {
    let loggerId: String
    let level: LogLevel
    let message: String
}

struct GetEntriesParams: Codable {
    let loggerId: String
    let level: LogLevel?
}

struct ClearLogsParams: Codable {
    let loggerId: String
}

struct SetLogLevelParams: Codable {
    let loggerId: String
    let level: LogLevel
}

struct MCPResponse: Codable {
    let jsonrpc: String = "2.0"
    let id: String?  // Optional for notifications
    let result: MCPResult?
    let error: MCPError?

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }
}

enum MCPResult: Codable {
    case success(SuccessResult)
    case entries([LogEntry])
    case initialize(InitializeResult)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.entries) {
            let entries = try container.decode([LogEntry].self, forKey: .entries)
            self = .entries(entries)
        } else if container.contains(.protocolVersion) {
            let result = try InitializeResult(from: decoder)
            self = .initialize(result)
        } else {
            let result = try SuccessResult(from: decoder)
            self = .success(result)
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .success(let result):
            try result.encode(to: encoder)
        case .entries(let entries):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(entries, forKey: .entries)
        case .initialize(let result):
            try result.encode(to: encoder)
        }
    }

    enum CodingKeys: String, CodingKey {
        case success
        case entries
        case protocolVersion
        case capabilities
        case serverInfo
    }
}

struct InitializeResult: Codable {
    let protocolVersion: String
    let capabilities: MCPCapabilities
    let serverInfo: ServerInfo
}

struct SuccessResult: Codable {
    let success: Bool
}

struct MCPError: Codable {
    let code: Int
    let message: String
}
