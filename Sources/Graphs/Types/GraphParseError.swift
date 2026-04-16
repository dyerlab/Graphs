//                      _                 _       _
//                   __| |_   _  ___ _ __| | __ _| |__
//                  / _` | | | |/ _ \ '__| |/ _` | '_ \
//                 | (_| | |_| |  __/ |  | | (_| | |_) |
//                  \__,_|\__, |\___|_|  |_|\__,_|_.__/
//                        |_ _/
//
//         Making Population Genetic Software That Doesn't Suck
//
//  Copyright (c) 2021-2026 Administravia LLC.  All Rights Reserved.
//

import Foundation

/// Errors that can occur when parsing a graph file.
///
/// `GraphParseError` provides detailed information about parsing failures,
/// including line numbers and content where applicable. All cases provide
/// localized error descriptions.
///
/// ## Overview
///
/// Graph files use a simple text format:
/// 1. Header line with node count and edge count
/// 2. Node lines with label, size, and color code
/// 3. Edge lines with source label, target label, and distance
///
/// ## Example
///
/// ```swift
/// do {
///     let graph = try parseGraph(content)
/// } catch let error as GraphParseError {
///     print(error.errorDescription ?? "Unknown error")
/// }
/// ```
///
/// ## Topics
///
/// ### Error Cases
/// - ``invalidHeader``
/// - ``invalidNodeLine(_:_:)``
/// - ``invalidEdgeLine(_:_:)``
/// - ``nodeMismatch(expected:found:)``
/// - ``edgeMismatch(expected:found:)``
/// - ``fileNotFound(_:)``
/// - ``invalidJSON(_:)``
public enum GraphParseError: Error, LocalizedError {

    /// The file header is missing or malformed.
    ///
    /// The header must contain at least two whitespace-separated integers:
    /// the node count and edge count.
    case invalidHeader

    /// A node definition line is malformed.
    ///
    /// - Parameters:
    ///   - line: The 1-based line number where the error occurred.
    ///   - content: The content of the malformed line.
    ///
    /// Node lines must contain: `label size colorCode`
    case invalidNodeLine(Int, String)

    /// An edge definition line is malformed.
    ///
    /// - Parameters:
    ///   - line: The 1-based line number where the error occurred.
    ///   - content: The content of the malformed line.
    ///
    /// Edge lines must contain: `sourceLabel targetLabel distance`
    case invalidEdgeLine(Int, String)

    /// The actual node count doesn't match the header.
    ///
    /// - Parameters:
    ///   - expected: The count declared in the header.
    ///   - found: The actual number of node lines found.
    case nodeMismatch(expected: Int, found: Int)

    /// The actual edge count doesn't match the header.
    ///
    /// - Parameters:
    ///   - expected: The count declared in the header.
    ///   - found: The actual number of edge lines found.
    case edgeMismatch(expected: Int, found: Int)

    /// The specified file could not be found.
    ///
    /// - Parameter path: The path or identifier of the missing file.
    case fileNotFound(String)

    /// The JSON content is malformed or missing required structure.
    ///
    /// - Parameter message: A description of what was wrong with the JSON.
    case invalidJSON(String)

    /// A localized description of the error.
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
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        }
    }
}
