import Foundation

enum MCPServerError: Error {
    case invalidRequest(message: String)
    case methodNotFound(method: String)
    case invalidParams(message: String)
    case internalError(message: String)
    case parseError(message: String)

    var errorCode: Int {
        switch self {
        case .parseError:
            return -32700
        case .invalidRequest:
            return -32600
        case .methodNotFound:
            return -32601
        case .invalidParams:
            return -32602
        case .internalError:
            return -32603
        }
    }

    var errorMessage: String {
        switch self {
        case .parseError(let msg):
            return "Parse error: \(msg)"
        case .invalidRequest(let msg):
            return "Invalid request: \(msg)"
        case .methodNotFound(let method):
            return "Method not found: \(method)"
        case .invalidParams(let msg):
            return "Invalid params: \(msg)"
        case .internalError(let msg):
            return "Internal error: \(msg)"
        }
    }
}

struct ErrorResponse: Codable {
    let jsonrpc: String = "2.0"
    let id: String
    let error: ErrorInfo

    struct ErrorInfo: Codable {
        let code: Int
        let message: String
        let data: String?

        init(code: Int, message: String, data: String? = nil) {
            self.code = code
            self.message = message
            self.data = data
        }
    }
}
