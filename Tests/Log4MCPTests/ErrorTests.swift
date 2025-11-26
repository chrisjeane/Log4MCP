import XCTest
@testable import Log4MCPLib

final class ErrorTests: XCTestCase {

    // T1.4.1: Parse error code
    func testParseErrorCode() {
        let error = MCPServerError.parseError
        XCTAssertEqual(error.errorCode, -32700)
    }

    // T1.4.2: Invalid request error code
    func testInvalidRequestErrorCode() {
        let error = MCPServerError.invalidRequest
        XCTAssertEqual(error.errorCode, -32600)
    }

    // T1.4.3: Method not found error code
    func testMethodNotFoundErrorCode() {
        let error = MCPServerError.methodNotFound
        XCTAssertEqual(error.errorCode, -32601)
    }

    // T1.4.4: Invalid params error code
    func testInvalidParamsErrorCode() {
        let error = MCPServerError.invalidParams
        XCTAssertEqual(error.errorCode, -32602)
    }

    // T1.4.5: Internal error code
    func testInternalErrorCode() {
        let error = MCPServerError.internalError
        XCTAssertEqual(error.errorCode, -32603)
    }

    // Test error messages
    func testParseErrorMessage() {
        let error = MCPServerError.parseError
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func testInvalidRequestErrorMessage() {
        let error = MCPServerError.invalidRequest
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func testMethodNotFoundErrorMessage() {
        let error = MCPServerError.methodNotFound
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func testInvalidParamsErrorMessage() {
        let error = MCPServerError.invalidParams
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func testInternalErrorMessage() {
        let error = MCPServerError.internalError
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    // Test ErrorResponse
    func testErrorResponse() {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = ErrorResponse(
            jsonrpc: "2.0",
            id: "1",
            error: error
        )

        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertEqual(response.id, "1")
        XCTAssertEqual(response.error.code, -32601)
        XCTAssertEqual(response.error.message, "Method not found")
    }

    // Test ErrorInfo nested struct
    func testErrorInfo() {
        let errorInfo = ErrorResponse.ErrorInfo(
            code: -32700,
            message: "Parse error",
            data: nil
        )

        XCTAssertEqual(errorInfo.code, -32700)
        XCTAssertEqual(errorInfo.message, "Parse error")
        XCTAssertNil(errorInfo.data)
    }

    // Test all error codes are distinct
    func testErrorCodesAreDistinct() {
        let errors = [
            MCPServerError.parseError,
            MCPServerError.invalidRequest,
            MCPServerError.methodNotFound,
            MCPServerError.invalidParams,
            MCPServerError.internalError
        ]

        let errorCodes = errors.map { $0.errorCode }
        let uniqueCodes = Set(errorCodes)

        XCTAssertEqual(uniqueCodes.count, errorCodes.count, "Error codes should be unique")
    }

    // Test error response encoding
    func testErrorResponseEncoding() throws {
        let error = MCPError(code: -32601, message: "Method not found")
        let response = ErrorResponse(
            jsonrpc: "2.0",
            id: "1",
            error: error
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("-32601"))
        XCTAssertTrue(jsonString.contains("Method not found"))
    }

    // Test error response decoding
    func testErrorResponseDecoding() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "error": {
                "code": -32601,
                "message": "Method not found",
                "data": null
            }
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonString.data(using: .utf8)!)

        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertEqual(response.id, "1")
        XCTAssertEqual(response.error.code, -32601)
        XCTAssertEqual(response.error.message, "Method not found")
    }
}
