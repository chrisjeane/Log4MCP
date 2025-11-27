import Foundation
import MCPServer

/// Log4 specific MCP request handler delegate that implements logging domain methods
public struct Log4MCPDelegate: MCPRequestHandlerDelegate, Sendable {
    private let registry: LoggerRegistry

    public init(config: ServerConfig) {
        self.registry = LoggerRegistry(config: config)
    }

    public func getServerInfo() -> ServerInfo {
        return ServerInfo(name: "Log4MCP", version: "2.0.0")
    }

    public func buildToolDefinitions() -> [Tool] {
        let logLevelEnum = ["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"]

        let logMessageTool = Tool(
            name: "log.message",
            description: "Log a message to a specific logger",
            inputSchema: ToolInputSchema(
                properties: [
                    "loggerId": PropertySchema(
                        type: "string",
                        description: "The unique identifier for the logger instance"
                    ),
                    "level": PropertySchema(
                        type: "string",
                        description: "The log level for this message",
                        enum: logLevelEnum
                    ),
                    "message": PropertySchema(
                        type: "string",
                        description: "The log message content"
                    )
                ],
                required: ["loggerId", "level", "message"]
            )
        )

        let getEntriesTool = Tool(
            name: "log.getEntries",
            description: "Retrieve logged entries, optionally filtered by log level",
            inputSchema: ToolInputSchema(
                properties: [
                    "loggerId": PropertySchema(
                        type: "string",
                        description: "The unique identifier for the logger instance"
                    ),
                    "level": PropertySchema(
                        type: "string",
                        description: "Optional filter to only return entries at this log level or higher",
                        enum: logLevelEnum
                    )
                ],
                required: ["loggerId"]
            )
        )

        let clearTool = Tool(
            name: "log.clear",
            description: "Clear all log entries for a specific logger",
            inputSchema: ToolInputSchema(
                properties: [
                    "loggerId": PropertySchema(
                        type: "string",
                        description: "The unique identifier for the logger instance to clear"
                    )
                ],
                required: ["loggerId"]
            )
        )

        let setLevelTool = Tool(
            name: "log.setLevel",
            description: "Change the log level for a specific logger",
            inputSchema: ToolInputSchema(
                properties: [
                    "loggerId": PropertySchema(
                        type: "string",
                        description: "The unique identifier for the logger instance"
                    ),
                    "level": PropertySchema(
                        type: "string",
                        description: "The new log level to set for this logger",
                        enum: logLevelEnum
                    )
                ],
                required: ["loggerId", "level"]
            )
        )

        return [logMessageTool, getEntriesTool, clearTool, setLevelTool]
    }

    public func handleDomainSpecificRequest(_ request: MCPRequest) async throws -> MCPResponse? {
        // Handle logging methods
        switch request.method {
        case "log.message":
            return try await handleLogMessage(request)

        case "log.getEntries":
            return try await handleGetEntries(request)

        case "log.clear":
            return try await handleClearLogs(request)

        case "log.setLevel":
            return try await handleSetLogLevel(request)

        default:
            guard let id = request.id else {
                return nil  // Don't respond to unknown notifications
            }
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32601, message: "Method not found: \(request.method)")
            )
        }
    }

    // MARK: - Log Domain Methods

    private func handleLogMessage(_ request: MCPRequest) async throws -> MCPResponse {
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Log message request must have an id"))
        }

        // Validate and decode params
        guard case .logMessage(let params) = request.params else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid params for log.message")
            )
        }

        // Validate non-empty loggerId
        guard !params.loggerId.isEmpty else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "loggerId cannot be empty")
            )
        }

        // Get logger and log message
        let logger = await registry.getLogger(id: params.loggerId)
        await logger.log(level: params.level, message: params.message)

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleGetEntries(_ request: MCPRequest) async throws -> MCPResponse {
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Get entries request must have an id"))
        }

        // Validate and decode params
        guard case .getEntries(let params) = request.params else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid params for log.getEntries")
            )
        }

        // Validate non-empty loggerId
        guard !params.loggerId.isEmpty else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "loggerId cannot be empty")
            )
        }

        // Get logger and retrieve entries
        let logger = await registry.getLogger(id: params.loggerId)
        let entries = await logger.getEntries(level: params.level)

        // Encode entries as results
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var resultsDict: [String: AnyCodable] = [:]
        if let entriesData = try? encoder.encode(entries),
           let entriesJson = try? JSONSerialization.jsonObject(with: entriesData) as? [[String: Any]] {
            let entriesArray = entriesJson.compactMap { dict -> AnyCodable? in
                convertToAnyCodable(dict)
            }
            resultsDict["entries"] = .array(entriesArray)
            resultsDict["count"] = .int(entries.count)
        } else {
            resultsDict["entries"] = .array([])
            resultsDict["count"] = .int(0)
        }

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true, results: resultsDict)),
            error: nil
        )
    }

    // Helper to convert JSON dictionary to AnyCodable
    private func convertToAnyCodable(_ value: Any) -> AnyCodable {
        if value is NSNull {
            return .null
        } else if let bool = value as? Bool {
            return .bool(bool)
        } else if let int = value as? Int {
            return .int(int)
        } else if let double = value as? Double {
            return .double(double)
        } else if let string = value as? String {
            return .string(string)
        } else if let array = value as? [Any] {
            return .array(array.map { convertToAnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            return .object(dict.mapValues { convertToAnyCodable($0) })
        } else {
            return .null
        }
    }

    private func handleClearLogs(_ request: MCPRequest) async throws -> MCPResponse {
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Clear logs request must have an id"))
        }

        // Validate and decode params
        guard case .clearLogs(let params) = request.params else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid params for log.clear")
            )
        }

        // Validate non-empty loggerId
        guard !params.loggerId.isEmpty else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "loggerId cannot be empty")
            )
        }

        // Get logger and clear entries
        let logger = await registry.getLogger(id: params.loggerId)
        await logger.clear()

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleSetLogLevel(_ request: MCPRequest) async throws -> MCPResponse {
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Set level request must have an id"))
        }

        // Validate and decode params
        guard case .setLogLevel(let params) = request.params else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid params for log.setLevel")
            )
        }

        // Validate non-empty loggerId
        guard !params.loggerId.isEmpty else {
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32602, message: "loggerId cannot be empty")
            )
        }

        // Get logger and set level
        let logger = await registry.getLogger(id: params.loggerId)
        await logger.setLogLevel(params.level)

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }
}

/// Convenience alias for Log4MCPRequestHandler using the delegate pattern
public typealias Log4MCPRequestHandler = MCPRequestHandler
