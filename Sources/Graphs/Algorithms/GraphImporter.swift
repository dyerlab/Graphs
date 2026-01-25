import Foundation
import SwiftUI

/// Import a .pgraph file from a string.
public func parseGraph(
    _ content: String,
    colorMapping: (Int) -> Color = defaultColorMapping
) throws -> GraphData {
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

    var nodes: [Node<String>] = []
    var edges: [(source: String, target: String, distance: Float)] = []

    // Parse nodes (lines 1 to nodeCount)
    for i in 1...nodeCount {
        guard i < lines.count else {
            throw GraphParseError.nodeMismatch(expected: nodeCount, found: nodes.count)
        }

        let parts = lines[i].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let size = Double(parts[1]),
              let colorCode = Int(parts[2]) else {
            throw GraphParseError.invalidNodeLine(i + 1, lines[i])
        }

        let label = String(parts[0])
        nodes.append(Node(
            id: label,
            label: label,
            size: size,
            color: colorMapping(colorCode)
        ))
    }

    // Parse edges (lines nodeCount+1 to end)
    let edgeStartIndex = nodeCount + 1
    for i in 0..<edgeCount {
        let lineIndex = edgeStartIndex + i
        guard lineIndex < lines.count else {
            throw GraphParseError.edgeMismatch(expected: edgeCount, found: edges.count)
        }

        let parts = lines[lineIndex].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let distance = Float(parts[2]) else {
            throw GraphParseError.invalidEdgeLine(lineIndex + 1, lines[lineIndex])
        }

        let source = String(parts[0])
        let target = String(parts[1])
        edges.append((source: source, target: target, distance: distance))
    }

    return GraphData(nodes: nodes, edges: edges)
}

/// Import a graph file from a URL.
public func loadGraph(
    from url: URL,
    colorMapping: (Int) -> Color = defaultColorMapping
) throws -> GraphData {
    let content = try String(contentsOf: url, encoding: .utf8)
    return try parseGraph(content, colorMapping: colorMapping)
}

/// Import a graph file from a file path.
public func loadGraph(
    fromPath path: String,
    colorMapping: (Int) -> Color = defaultColorMapping
) throws -> GraphData {
    let url = URL(fileURLWithPath: path)
    return try loadGraph(from: url, colorMapping: colorMapping)
}

/// Load a graph file bundled with the Graphs module.
/// - Parameter name: The filename without extension (e.g., "vcu" for "vcu.pgraph")
public func loadBundledGraph(
    named name: String,
    colorMapping: (Int) -> Color = defaultColorMapping
) throws -> GraphData {
    guard let url = Bundle.module.url(forResource: name, withExtension: "pgraph", subdirectory: "Data") else {
        throw GraphParseError.fileNotFound("\(name).pgraph in bundle")
    }
    return try loadGraph(from: url, colorMapping: colorMapping)
}
