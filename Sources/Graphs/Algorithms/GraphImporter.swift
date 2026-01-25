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
import SwiftUI

/// Parses a graph from a string in .pgraph format.
///
/// The .pgraph format is a simple text format for representing graphs:
///
/// ```
/// nodeCount edgeCount
/// label1 size1 colorCode1
/// label2 size2 colorCode2
/// ...
/// sourceLabel1 targetLabel1 distance1
/// sourceLabel2 targetLabel2 distance2
/// ...
/// ```
///
/// ## Format Details
///
/// - **Header**: Two integers separated by whitespace (node count, edge count)
/// - **Nodes**: Each line has: label (string), size (double), color code (int)
/// - **Edges**: Each line has: source label, target label, distance (float)
///
/// ## Example File
///
/// ```
/// 3 2
/// alpha 12.0 1
/// beta 8.0 2
/// gamma 10.0 1
/// alpha beta 25.0
/// beta gamma 30.0
/// ```
///
/// ## Custom Color Mapping
///
/// By default, integer color codes are mapped using ``defaultColorMapping(_:)``.
/// You can provide a custom mapping function:
///
/// ```swift
/// let graph = try parseGraph(content) { code in
///     switch code {
///     case 0: return .black
///     default: return .gray
///     }
/// }
/// ```
///
/// - Parameters:
///   - content: The string content to parse.
///   - colorMapping: Function to map integer codes to colors. Defaults to ``defaultColorMapping(_:)``.
///
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edges.
///
/// - Throws: ``GraphParseError`` if the content is malformed.
public func parseGraph(_ content: String, colorMapping: (Int) -> Color = defaultColorMapping) throws -> PopulationGraph {

    let lines = content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

    guard !lines.isEmpty else {
        throw GraphParseError.invalidHeader
    }

    // Parse header
    let headerParts = lines[0].split(whereSeparator: \.isWhitespace)
    guard headerParts.count >= 2,
          let nodeCount = Int(headerParts[0]),
          let edgeCount = Int(headerParts[1]) else {
        throw GraphParseError.invalidHeader
    }

    var graph = PopulationGraph()

    // Parse nodes (lines 1 to nodeCount)
    for i in 1...nodeCount {

        guard i < lines.count else {
            throw GraphParseError.nodeMismatch(expected: nodeCount, found: graph.nodeCount)
        }

        let parts = lines[i].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let size = Double(parts[1]),
              let colorCode = Int(parts[2]) else {
            throw GraphParseError.invalidNodeLine(i + 1, lines[i])
        }

        let label = String(parts[0])
        graph.addNode(Node(label: label, size: size, color: colorMapping(colorCode)))
    }

    // Parse edges (lines nodeCount+1 to end)
    let edgeStartIndex = nodeCount + 1
    for i in 0..<edgeCount {
        let lineIndex = edgeStartIndex + i
        guard lineIndex < lines.count else {
            throw GraphParseError.edgeMismatch(expected: edgeCount, found: graph.edges.count)
        }

        let parts = lines[lineIndex].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let distance = Float(parts[2]) else {
            throw GraphParseError.invalidEdgeLine(lineIndex + 1, lines[lineIndex])
        }

        graph.connect(String(parts[0]), to: String(parts[1]), distance: distance)
    }

    return graph
}

/// Loads a graph from a URL.
///
/// - Parameters:
///   - url: The URL of the .pgraph file to load.
///   - colorMapping: Function to map integer codes to colors. Defaults to ``defaultColorMapping(_:)``.
///
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edges.
///
/// - Throws: ``GraphParseError`` if the file is malformed, or a file system error if the file cannot be read.
public func loadGraph(from url: URL, colorMapping: (Int) -> Color = defaultColorMapping) throws -> PopulationGraph {
    let content = try String(contentsOf: url, encoding: .utf8)
    return try parseGraph(content, colorMapping: colorMapping)
}

/// Loads a graph from a file path.
///
/// - Parameters:
///   - path: The file system path to the .pgraph file.
///   - colorMapping: Function to map integer codes to colors. Defaults to ``defaultColorMapping(_:)``.
///
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edges.
///
/// - Throws: ``GraphParseError`` if the file is malformed, or a file system error if the file cannot be read.
public func loadGraph(fromPath path: String, colorMapping: (Int) -> Color = defaultColorMapping) throws -> PopulationGraph {
    let url = URL(fileURLWithPath: path)
    return try loadGraph(from: url, colorMapping: colorMapping)
}

/// Loads a graph file bundled with the Graphs module.
///
/// Use this to load sample graph data included with the library.
///
/// - Parameters:
///   - name: The filename without extension (e.g., "vcu" for "vcu.pgraph").
///   - colorMapping: Function to map integer codes to colors. Defaults to ``defaultColorMapping(_:)``.
///
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edges.
///
/// - Throws: ``GraphParseError/fileNotFound(_:)`` if the file is not in the bundle,
///   or other ``GraphParseError`` cases if the file is malformed.
///
/// ## Example
///
/// ```swift
/// let graph = try loadBundledGraph(named: "vcu")
/// ```
public func loadBundledGraph(named name: String, colorMapping: (Int) -> Color = defaultColorMapping) throws -> PopulationGraph {
    guard let url = Bundle.module.url(forResource: name, withExtension: "pgraph", subdirectory: "Data") else {
        throw GraphParseError.fileNotFound("\(name).pgraph in bundle")
    }
    return try loadGraph(from: url, colorMapping: colorMapping)
}
