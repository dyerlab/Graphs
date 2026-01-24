import Foundation
import SwiftUI

/// Result of parsing a .pgraph file.
public struct PGraphData: Sendable {
    public let nodes: [PGraphNode]
    public let edges: [PGraphEdge]

    public init(nodes: [PGraphNode], edges: [PGraphEdge]) {
        self.nodes = nodes
        self.edges = edges
    }

    /// Convert to GraphNode array with a color mapping function.
    public func graphNodes(colorMapping: (Int) -> Color = defaultColorMapping) -> [GraphNode<String>] {
        nodes.map { node in
            GraphNode(
                id: node.label,
                label: node.label,
                size: node.size,
                color: colorMapping(node.colorCode)
            )
        }
    }

    /// Convert to edge tuples for the simulation.
    public func graphEdges() -> [(source: String, target: String, distance: Float)] {
        edges.map { ($0.source, $0.target, $0.distance) }
    }
}

/// Default color mapping for color codes.
public func defaultColorMapping(_ code: Int) -> Color {
    switch code {
    case 0: return .gray
    case 1: return .blue
    case 2: return .green
    case 3: return .orange
    case 4: return .red
    case 5: return .purple
    case 6: return .pink
    case 7: return .yellow
    case 8: return .cyan
    case 9: return .mint
    default: return .blue
    }
}
