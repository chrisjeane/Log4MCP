import Foundation

/// Simple test framework for environments without XCTest
public class SimpleTestCase {
    public var testResults: [(name: String, passed: Bool, error: String?)] = []

    public func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if actual != expected {
            recordFailure("Expected \(expected) but got \(actual). \(message)", file: file, line: line)
        }
    }

    public func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if !condition {
            recordFailure("Condition was false. \(message)", file: file, line: line)
        }
    }

    public func assertFalse(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if condition {
            recordFailure("Condition was true. \(message)", file: file, line: line)
        }
    }

    public func assertNil(_ value: Any?, _ message: String = "", file: String = #file, line: Int = #line) {
        if value != nil {
            recordFailure("Expected nil but got value. \(message)", file: file, line: line)
        }
    }

    public func assertNotNil(_ value: Any?, _ message: String = "", file: String = #file, line: Int = #line) {
        if value == nil {
            recordFailure("Expected non-nil value. \(message)", file: file, line: line)
        }
    }

    public func assertGreaterThan<T: Comparable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if actual <= expected {
            recordFailure("Expected \(actual) > \(expected). \(message)", file: file, line: line)
        }
    }

    public func assertGreaterThanOrEqual<T: Comparable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if actual < expected {
            recordFailure("Expected \(actual) >= \(expected). \(message)", file: file, line: line)
        }
    }

    public func assertLessThan<T: Comparable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if actual >= expected {
            recordFailure("Expected \(actual) < \(expected). \(message)", file: file, line: line)
        }
    }

    private var lastTestName: String = ""
    private var lastTestFailed: Bool = false

    private func recordFailure(_ message: String, file: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let failureMessage = "\(fileName):\(line): \(message)"
        if !lastTestName.isEmpty {
            testResults.append((name: lastTestName, passed: false, error: failureMessage))
        }
        lastTestFailed = true
    }

    public func runTest(_ name: String, _ block: () throws -> Void) {
        lastTestName = name
        lastTestFailed = false
        do {
            try block()
            testResults.append((name: name, passed: !lastTestFailed, error: nil))
        } catch {
            testResults.append((name: name, passed: false, error: error.localizedDescription))
        }
    }

    public func runAsyncTest(_ name: String, _ block: () async throws -> Void) async {
        lastTestName = name
        lastTestFailed = false
        do {
            try await block()
            testResults.append((name: name, passed: !lastTestFailed, error: nil))
        } catch {
            testResults.append((name: name, passed: false, error: error.localizedDescription))
        }
    }
}
