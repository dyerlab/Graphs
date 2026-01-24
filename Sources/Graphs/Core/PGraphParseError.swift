import Foundation

/// Errors that can occur when parsing a .pgraph file.
public enum PGraphParseError: Error, LocalizedError {
    case invalidHeader
    case invalidNodeLine(Int, String)
    case invalidEdgeLine(Int, String)
    case nodeMismatch(expected: Int, found: Int)
    case edgeMismatch(expected: Int, found: Int)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidHeader:
            return "Invalid header line: expected 'nodeCount edgeCount'"
        case .invalidNodeLine(let line, let content):
            return "Invalid node at line \(line): '\(content)'"
        case .invalidEdgeLine(let line, let content):
            return "Invalid edge at line \(line): '\(content)'"
        case .nodeMismatch(let expected, let found):
            return "Expected \(expected) nodes but found \(found)"
        case .edgeMismatch(let expected, let found):
            return "Expected \(expected) edges but found \(found)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }
}
