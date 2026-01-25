import SwiftUI

/// A node in the graph with visual properties.
public struct GraphNode<ID: Hashable>: Identifiable {
    public var id: ID
    public var label: String
    public var size: Double
    public var color: Color

    public init(id: ID, label: String, size: Double = 10, color: Color = .blue) {
        self.id = id
        self.label = label
        self.size = size
        self.color = color
    }
}
