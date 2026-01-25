import Foundation
import SwiftUI

/// Result of parsing a graph file.
public struct GraphData: Sendable {
    public let nodes: [Node<String>]
    public let edges: [(source: String, target: String, distance: Float)]

    public init(nodes: [Node<String>], edges: [(source: String, target: String, distance: Float)]) {
        self.nodes = nodes
        self.edges = edges
    }
}
