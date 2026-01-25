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
public enum GraphParseError: Error, LocalizedError {
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
