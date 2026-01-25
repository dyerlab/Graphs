import Foundation
import SwiftUI

/// Result of parsing a graph file.
public struct GraphData: Sendable {
    public let nodes: [Node]
    public let edges: [(source: String, target: String, distance: Float)]

    public init(nodes: [Node], edges: [(source: String, target: String, distance: Float)]) {
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
