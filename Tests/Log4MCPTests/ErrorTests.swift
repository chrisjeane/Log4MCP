import Foundation
import Testing
@testable import Log4MCPLib

struct ErrorTests {

    // T1.4.1: Parse error code
    @Test
    func parseErrorCode() {
        let error = MCPServerError.parseError(message: "Parse error")
        #expect(error.errorCode == -32700)
    }

    // T1.4.2: Invalid request error code
    @Test
    func invalidRequestErrorCode() {
        let error = MCPServerError.invalidRequest(message: "Invalid request")
        #expect(error.errorCode == -32600)
    }

    // T1.4.3: Method not found error code
    @Test
    func methodNotFoundErrorCode() {
        let error = MCPServerError.methodNotFound(method: "unknown")
        #expect(error.errorCode == -32601)
    }

    // T1.4.4: Invalid params error code
    @Test
    func invalidParamsErrorCode() {
        let error = MCPServerError.invalidParams(message: "Invalid params")
        #expect(error.errorCode == -32602)
    }

    // T1.4.5: Internal error code
    @Test
    func internalErrorCode() {
        let error = MCPServerError.internalError(message: "Internal error")
        #expect(error.errorCode == -32603)
    }

    // Test error messages
    @Test
    func parseErrorMessage() {
        let error = MCPServerError.parseError(message: "Parse error")
        #expect(!error.errorMessage.isEmpty)
    }

    @Test
    func invalidRequestErrorMessage() {
        let error = MCPServerError.invalidRequest(message: "Invalid request")
        #expect(!error.errorMessage.isEmpty)
    }

    @Test
    func methodNotFoundErrorMessage() {
        let error = MCPServerError.methodNotFound(method: "unknown")
        #expect(!error.errorMessage.isEmpty)
    }

    @Test
    func invalidParamsErrorMessage() {
        let error = MCPServerError.invalidParams(message: "Invalid params")
        #expect(!error.errorMessage.isEmpty)
    }

    @Test
    func internalErrorMessage() {
        let error = MCPServerError.internalError(message: "Internal error")
        #expect(!error.errorMessage.isEmpty)
    }

    // Test MCPResponse with error
    @Test
    func mcpResponseWithError() {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = MCPResponse(
            id: "1",
            result: nil,
            error: error
        )

        #expect(response.jsonrpc == "2.0")
        #expect(response.id == "1")
        #expect(response.error?.code == -32601)
        #expect(response.error?.message == "Method not found")
    }

    // Test MCPError structure
    @Test
    func mcpErrorStructure() {
        let error = MCPError(code: -32700, message: "Parse error")

        #expect(error.code == -32700)
        #expect(error.message == "Parse error")
    }

    // Test all error codes are distinct
    @Test
    func errorCodesAreDistinct() {
        let errors = [
            MCPServerError.parseError(message: "Parse error"),
            MCPServerError.invalidRequest(message: "Invalid request"),
            MCPServerError.methodNotFound(method: "unknown"),
            MCPServerError.invalidParams(message: "Invalid params"),
            MCPServerError.internalError(message: "Internal error")
        ]

        let errorCodes = errors.map { $0.errorCode }
        let uniqueCodes = Set(errorCodes)

        #expect(uniqueCodes.count == errorCodes.count)
    }

    // Test error response encoding
    @Test
    func errorResponseEncoding() throws {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = MCPResponse(
            id: "1",
            result: nil,
            error: error
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("-32601"))
        #expect(jsonString.contains("Method not found"))
    }

    // Test error response decoding
    @Test
    func errorResponseDecoding() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "error": {
                "code": -32601,
                "message": "Method not found"
            }
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(MCPResponse.self, from: jsonString.data(using: .utf8)!)

        #expect(response.jsonrpc == "2.0")
        #expect(response.id == "1")
        #expect(response.error?.code == -32601)
        #expect(response.error?.message == "Method not found")
    }
}
