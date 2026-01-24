import Foundation

/// Import a .pgraph file from a string.
public func parsePGraph(_ content: String) throws -> PGraphData {
    let lines = content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

    guard !lines.isEmpty else {
        throw PGraphParseError.invalidHeader
    }

    // Parse header
    let headerParts = lines[0].split(whereSeparator: \.isWhitespace)
    guard headerParts.count >= 2,
          let nodeCount = Int(headerParts[0]),
          let edgeCount = Int(headerParts[1]) else {
        throw PGraphParseError.invalidHeader
    }

    var nodes: [PGraphNode] = []
    var edges: [PGraphEdge] = []

    // Parse nodes (lines 1 to nodeCount)
    for i in 1...nodeCount {
        guard i < lines.count else {
            throw PGraphParseError.nodeMismatch(expected: nodeCount, found: nodes.count)
        }

        let parts = lines[i].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let size = Double(parts[1]),
              let colorCode = Int(parts[2]) else {
            throw PGraphParseError.invalidNodeLine(i + 1, lines[i])
        }

        let label = String(parts[0])
        nodes.append(PGraphNode(label: label, size: size, colorCode: colorCode))
    }

    // Parse edges (lines nodeCount+1 to end)
    let edgeStartIndex = nodeCount + 1
    for i in 0..<edgeCount {
        let lineIndex = edgeStartIndex + i
        guard lineIndex < lines.count else {
            throw PGraphParseError.edgeMismatch(expected: edgeCount, found: edges.count)
        }

        let parts = lines[lineIndex].split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3,
              let distance = Float(parts[2]) else {
            throw PGraphParseError.invalidEdgeLine(lineIndex + 1, lines[lineIndex])
        }

        let source = String(parts[0])
        let target = String(parts[1])
        edges.append(PGraphEdge(source: source, target: target, distance: distance))
    }

    return PGraphData(nodes: nodes, edges: edges)
}

/// Import a .pgraph file from a URL.
public func loadPGraph(from url: URL) throws -> PGraphData {
    let content = try String(contentsOf: url, encoding: .utf8)
    return try parsePGraph(content)
}

/// Import a .pgraph file from a file path.
public func loadPGraph(fromPath path: String) throws -> PGraphData {
    let url = URL(fileURLWithPath: path)
    return try loadPGraph(from: url)
}

/// Load a .pgraph file bundled with the Graphs module.
/// - Parameter name: The filename without extension (e.g., "vcu" for "vcu.pgraph")
public func loadBundledPGraph(named name: String) throws -> PGraphData {
    guard let url = Bundle.module.url(forResource: name, withExtension: "pgraph", subdirectory: "Data") else {
        throw PGraphParseError.fileNotFound("\(name).pgraph in bundle")
    }
    return try loadPGraph(from: url)
}
