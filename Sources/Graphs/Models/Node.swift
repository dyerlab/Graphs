import SwiftUI

/// A node in the graph with visual properties.
public struct Node<ID: Hashable>: Identifiable, Sendable, Equatable, Hashable where ID: Sendable {
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

