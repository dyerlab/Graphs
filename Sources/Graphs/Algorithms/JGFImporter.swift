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

// MARK: - Public API

/// Parses a graph from JSON data in JSON Graph Format (JGF).
///
/// JGF is a standard JSON format for representing graphs. This function supports both
/// the standard single-edge-set form and an extended form with multiple named edge sets.
///
/// ## Standard JGF (single edge set)
///
/// ```json
/// {
///   "graph": {
///     "label": "My Graph",
///     "nodes": {
///       "n1": { "label": "Alpha", "metadata": { "size": 20, "color": "#FF0000" } },
///       "n2": { "label": "Beta",  "metadata": { "size": 15, "color": "blue" } }
///     },
///     "edges": [
///       { "source": "n1", "target": "n2", "metadata": { "distance": 30, "weight": 1.0 } }
///     ]
///   }
/// }
/// ```
///
/// ## Extended JGF (multiple edge sets)
///
/// When the `edgeSets` key is present, the `edges` key is ignored. Each edge set
/// becomes a ``EdgeSet`` in the resulting ``PopulationGraph``.
///
/// ```json
/// {
///   "graph": {
///     "nodes": { ... },
///     "edgeSets": [
///       {
///         "name": "Generation 1",
///         "metadata": { "year": "1920" },
///         "edges": [ { "source": "n1", "target": "n2", "metadata": { "distance": 30 } } ]
///       },
///       {
///         "name": "Generation 2",
///         "edges": []
///       }
///     ]
///   }
/// }
/// ```
///
/// ## Node Metadata
///
/// The following keys in a node's `metadata` object are mapped to ``Node`` properties:
/// - `"size"`: A number (e.g. `20`) mapped to ``Node/size``.
/// - `"color"`: A CSS color name (e.g. `"red"`) or hex string (e.g. `"#FF0000"`, `"#F00"`)
///   mapped to ``Node/color``. Unrecognized values fall back to `.blue`.
///
/// ## Edge Metadata
///
/// The following keys in an edge's `metadata` object are mapped to ``Edge`` properties:
/// - `"distance"`: A number mapped to ``Edge/distance``. Defaults to 30.0.
/// - `"weight"`: A number mapped to ``Edge/weight``. Defaults to 1.0.
///
/// ## Node Ordering
///
/// Because JSON objects are inherently unordered, nodes are sorted alphabetically
/// by their JSON key before being assigned indices. Edges reference nodes by their
/// JSON key, so the resulting graph is always consistent regardless of input order.
///
/// ## Multi-graph Format
///
/// When a `"graphs"` array is present instead of a single `"graph"` object,
/// only the first graph in the array is parsed.
///
/// - Parameter data: The JSON data to parse.
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edge sets.
/// - Throws: ``GraphParseError/invalidJSON(_:)`` if the JSON is malformed or missing required structure.
public func parseJGF(_ data: Data) throws -> PopulationGraph {
    let document: JGFDocument
    do {
        document = try JSONDecoder().decode(JGFDocument.self, from: data)
    } catch {
        throw GraphParseError.invalidJSON(error.localizedDescription)
    }

    guard let jgfGraph = document.graph ?? document.graphs?.first else {
        throw GraphParseError.invalidJSON("No 'graph' or 'graphs' key found at the top level")
    }

    return buildPopulationGraph(from: jgfGraph)
}

/// Parses a graph from a JSON string in JSON Graph Format (JGF).
///
/// - Parameter content: The JSON string to parse.
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edge sets.
/// - Throws: ``GraphParseError/invalidJSON(_:)`` if the string is not valid UTF-8 or the JSON is malformed.
public func parseJGF(_ content: String) throws -> PopulationGraph {
    guard let data = content.data(using: .utf8) else {
        throw GraphParseError.invalidJSON("Could not encode string as UTF-8")
    }
    return try parseJGF(data)
}

/// Loads a graph from a URL pointing to a JSON Graph Format (JGF) file.
///
/// - Parameter url: The URL of the `.json` JGF file to load.
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edge sets.
/// - Throws: ``GraphParseError/invalidJSON(_:)`` if the JSON is malformed, or a file system
///   error if the file cannot be read.
public func loadJGF(from url: URL) throws -> PopulationGraph {
    let data = try Data(contentsOf: url)
    return try parseJGF(data)
}

/// Loads a graph from a file path pointing to a JSON Graph Format (JGF) file.
///
/// - Parameter path: The file system path to the `.json` JGF file.
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edge sets.
/// - Throws: ``GraphParseError/invalidJSON(_:)`` if the JSON is malformed, or a file system
///   error if the file cannot be read.
public func loadJGF(fromPath path: String) throws -> PopulationGraph {
    let url = URL(fileURLWithPath: path)
    return try loadJGF(from: url)
}

/// Loads a JGF graph file bundled with the Graphs module.
///
/// Use this to load sample graph data included with the library.
///
/// - Parameter name: The filename without extension (e.g., "vcu" for "vcu.json").
/// - Returns: A ``PopulationGraph`` containing the parsed nodes and edge sets.
/// - Throws: ``GraphParseError/fileNotFound(_:)`` if the file is not in the bundle,
///   or other ``GraphParseError`` cases if the file is malformed.
///
/// ## Example
///
/// ```swift
/// let graph = try loadBundledJGF(named: "vcu")
/// ```
public func loadBundledJGF(named name: String) throws -> PopulationGraph {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Data") else {
        throw GraphParseError.fileNotFound("\(name).json in bundle")
    }
    return try loadJGF(from: url)
}

// MARK: - Private JSON Types

/// A JSON value that may be a string, number, bool, or null.
///
/// Used to decode open-ended `metadata` objects in JGF without requiring all values
/// to be strings.
private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let d = try? container.decode(Double.self) { self = .number(d); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value type")
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .number(let n): return String(n)
        case .bool(let b): return String(b)
        case .null: return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .number(let n): return n
        case .string(let s): return Double(s)
        default: return nil
        }
    }
}

private struct JGFDocument: Decodable {
    let graph: JGFGraph?
    let graphs: [JGFGraph]?
}

private struct JGFGraph: Decodable {
    let label: String?
    let nodes: [String: JGFNode]?
    let edges: [JGFEdge]?
    let edgeSets: [JGFEdgeSet]?
}

private struct JGFNode: Decodable {
    let label: String?
    let metadata: [String: JSONValue]?
}

private struct JGFEdge: Decodable {
    let source: String
    let target: String
    let metadata: [String: JSONValue]?
}

private struct JGFEdgeSet: Decodable {
    let id: String?
    let name: String?
    let metadata: [String: JSONValue]?
    let edges: [JGFEdge]?
}

// MARK: - Graph Building

private func buildPopulationGraph(from jgfGraph: JGFGraph) -> PopulationGraph {
    // Sort node pairs alphabetically by key for deterministic index assignment.
    let sortedNodePairs = (jgfGraph.nodes ?? [:]).sorted { $0.key < $1.key }
    let nodeIndexMap = Dictionary(uniqueKeysWithValues: sortedNodePairs.enumerated().map { ($1.key, $0) })
    let nodes = sortedNodePairs.map { buildNode(key: $0.key, from: $0.value) }

    let edgeSets: [EdgeSet]

    if let jgfEdgeSets = jgfGraph.edgeSets, !jgfEdgeSets.isEmpty {
        // Extended format: multiple named edge sets.
        edgeSets = jgfEdgeSets.map { buildEdgeSet(from: $0, nodeIndexMap: nodeIndexMap) }
    } else if let jgfEdges = jgfGraph.edges {
        // Standard JGF: single edge set named after the graph label.
        let edges = buildEdges(from: jgfEdges, nodeIndexMap: nodeIndexMap)
        edgeSets = [EdgeSet(name: jgfGraph.label ?? "Default", edges: edges)]
    } else {
        edgeSets = []
    }

    return PopulationGraph(nodes: nodes, edgeSets: edgeSets)
}

private func buildNode(key: String, from jgfNode: JGFNode) -> Node {
    let label = jgfNode.label ?? key
    let size = jgfNode.metadata?["size"]?.doubleValue ?? 10.0
    let color = jgfNode.metadata?["color"]?.stringValue.flatMap { parseColor($0) } ?? .blue
    return Node(label: label, size: size, color: color)
}

private func buildEdgeSet(from jgfEdgeSet: JGFEdgeSet, nodeIndexMap: [String: Int]) -> EdgeSet {
    let name = jgfEdgeSet.name ?? jgfEdgeSet.id ?? "Edge Set"
    let edges = buildEdges(from: jgfEdgeSet.edges ?? [], nodeIndexMap: nodeIndexMap)
    let metadata = (jgfEdgeSet.metadata ?? [:]).compactMapValues { $0.stringValue }
    return EdgeSet(name: name, edges: edges, metadata: metadata)
}

private func buildEdges(from jgfEdges: [JGFEdge], nodeIndexMap: [String: Int]) -> [Edge] {
    jgfEdges.compactMap { jgfEdge in
        guard let sourceIdx = nodeIndexMap[jgfEdge.source],
              let targetIdx = nodeIndexMap[jgfEdge.target] else { return nil }

        let distance = Float(jgfEdge.metadata?["distance"]?.doubleValue ?? 30.0)
        let weight = Float(jgfEdge.metadata?["weight"]?.doubleValue ?? 1.0)

        return Edge(source: sourceIdx, target: targetIdx, weight: weight, distance: distance)
    }
}

// MARK: - Color Parsing

/// Parses a CSS color name or hex string into a SwiftUI `Color`.
///
/// Supported forms:
/// - CSS color names: `"red"`, `"blue"`, `"green"`, etc.
/// - 3-digit hex: `"#F00"` (expanded to `#FF0000`)
/// - 6-digit hex: `"#FF0000"`
/// - 8-digit hex: `"#FF0000FF"` (with alpha)
///
/// Returns `nil` for unrecognized values.
private func parseColor(_ string: String) -> Color? {
    let s = string.trimmingCharacters(in: .whitespaces).lowercased()

    switch s {
    case "red":    return .red
    case "blue":   return .blue
    case "green":  return .green
    case "orange": return .orange
    case "yellow": return .yellow
    case "purple": return .purple
    case "pink":   return .pink
    case "gray", "grey": return .gray
    case "black":  return .black
    case "white":  return .white
    case "cyan":   return .cyan
    case "mint":   return .mint
    case "teal":   return .teal
    case "indigo": return .indigo
    case "brown":  return .brown
    default: break
    }

    var hex = s.hasPrefix("#") ? String(s.dropFirst()) : s

    // Expand 3-digit shorthand to 6 digits.
    if hex.count == 3 {
        hex = hex.map { String(repeating: String($0), count: 2) }.joined()
    }

    switch hex.count {
    case 6:
        guard let value = UInt64(hex, radix: 16) else { return nil }
        return Color(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    case 8:
        guard let value = UInt64(hex, radix: 16) else { return nil }
        return Color(
            red:     Double((value >> 24) & 0xFF) / 255,
            green:   Double((value >> 16) & 0xFF) / 255,
            blue:    Double((value >>  8) & 0xFF) / 255,
            opacity: Double( value        & 0xFF) / 255
        )
    default:
        return nil
    }
}
