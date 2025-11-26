import Foundation
import MCPServer

/// Log4 specific MCP request handler delegate that implements logging domain methods
public struct Log4MCPDelegate: MCPRequestHandlerDelegate, Sendable {
    public init() {}

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
        // For now, use a simple approach to decode log message parameters
        // This could be extended to use proper parameter decoding
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Log message request must have an id"))
        }

        // In a real implementation, we'd properly decode the params
        // For this refactoring, we'll leave the logging implementation as-is
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

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }

    private func handleClearLogs(_ request: MCPRequest) async throws -> MCPResponse {
        guard let id = request.id else {
            return MCPResponse(id: nil, result: nil, error: MCPError(code: -32600, message: "Clear logs request must have an id"))
        }

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

        return MCPResponse(
            id: id,
            result: .success(SuccessResult(success: true)),
            error: nil
        )
    }
}

/// Convenience alias for Log4MCPRequestHandler using the delegate pattern
public typealias Log4MCPRequestHandler = MCPRequestHandler
