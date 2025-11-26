import Foundation

public enum InitializationState {
    case uninitialized
    case initialized
}

public actor MCPRequestHandler {
    private var loggers: [String: Logger] = [:]
    private var initializationState: InitializationState = .uninitialized
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func handleRequest(_ requestData: Data) async -> Data? {
        do {
            let request = try decoder.decode(MCPRequest.self, from: requestData)
            let response = try await processRequest(request)

            let responseData = try encoder.encode(response)
            return responseData
        } catch {
            let id = extractIdFromData(requestData) ?? "unknown"
            return try? encodeErrorResponse(
                id: id,
                code: -32700,
                message: "Parse error: \(error.localizedDescription)"
            )
        }
    }

    private func extractIdFromData(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["id"] as? String
    }

    public func handleRequest(_ requestString: String) async -> String? {
        guard let requestData = requestString.data(using: .utf8) else {
            return nil
        }

        guard let responseData = await handleRequest(requestData) else {
            return nil
        }

        return String(data: responseData, encoding: .utf8)
    }

    private func processRequest(_ request: MCPRequest) async throws -> MCPResponse? {
        // System protocol methods don't require initialization
        switch request.method {
        case "system.initialize":
            return await handleSystemInitialize(request)

        case "system.initialized":
            // Mark as initialized (notification - no response)
            initializationState = .initialized
            return nil  // Don't send response for notifications

        case "system.capabilities":
            return await handleSystemCapabilities(request)

        case "tools/list":
            return await handleToolsList(request)

        default:
            break
        }

        // All other methods require initialization
        guard case .initialized = initializationState else {
            guard let id = request.id else {
                return nil  // Don't respond to uninitialized notifications
            }
            return MCPResponse(
                id: id,
                result: nil,
                error: MCPError(code: -32600, message: "Invalid Request: server not initialized")
            )
        }

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

    private func handleSystemInitialize(_ request: MCPRequest) async -> MCPResponse {
        let capabilities = MCPCapabilities(
            logging: MCPCapabilities.Logging(),
            tools: MCPCapabilities.Tools(listChanged: false)
        )
        let result = InitializeResult(
            protocolVersion: MCP_PROTOCOL_VERSION,
            capabilities: capabilities,
            serverInfo: ServerInfo()
        )

        return MCPResponse(
            id: request.id,
            result: .initialize(result),
            error: nil
        )
    }

    private func handleSystemCapabilities(_ request: MCPRequest) async -> MCPResponse {
        return MCPResponse(
            id: request.id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleLogMessage(_ request: MCPRequest) async throws -> MCPResponse {
        guard case let .logMessage(params) = request.params else {
            return MCPResponse(
                id: request.id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid parameters")
            )
        }

        let logger = await getOrCreateLogger(params.loggerId)
        await logger.log(level: params.level, message: params.message)

        return MCPResponse(
            id: request.id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleGetEntries(_ request: MCPRequest) async throws -> MCPResponse {
        guard case let .getEntries(params) = request.params else {
            return MCPResponse(
                id: request.id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid parameters")
            )
        }

        let logger = await getOrCreateLogger(params.loggerId)
        let entries = await logger.getEntries(level: params.level)

        return MCPResponse(
            id: request.id,
            result: .entries(entries),
            error: nil
        )
    }

    private func handleClearLogs(_ request: MCPRequest) async throws -> MCPResponse {
        guard case let .clearLogs(params) = request.params else {
            return MCPResponse(
                id: request.id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid parameters")
            )
        }

        let logger = await getOrCreateLogger(params.loggerId)
        await logger.clear()

        return MCPResponse(
            id: request.id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleSetLogLevel(_ request: MCPRequest) async throws -> MCPResponse {
        guard case let .setLogLevel(params) = request.params else {
            return MCPResponse(
                id: request.id,
                result: nil,
                error: MCPError(code: -32602, message: "Invalid parameters")
            )
        }

        let logger = await getOrCreateLogger(params.loggerId)
        await logger.setLogLevel(params.level)

        return MCPResponse(
            id: request.id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleToolsList(_ request: MCPRequest) async -> MCPResponse {
        let tools = buildToolDefinitions()
        let result = ToolsListResult(tools: tools)

        return MCPResponse(
            id: request.id,
            result: .toolsList(result),
            error: nil
        )
    }

    private func buildToolDefinitions() -> [Tool] {
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

    private func getOrCreateLogger(_ id: String) async -> Logger {
        if let logger = loggers[id] {
            return logger
        }

        let logger = Logger(name: id)
        loggers[id] = logger
        return logger
    }

    private func encodeErrorResponse(id: String, code: Int, message: String) throws -> Data {
        let response = MCPResponse(
            id: id,
            result: nil,
            error: MCPError(code: code, message: message)
        )
        return try encoder.encode(response)
    }
}
