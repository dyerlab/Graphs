import SwiftUI

/// A node in the graph with visual properties.
public struct Node: Identifiable, Sendable, Equatable, Hashable {
    public var id = UUID()
    public var label: String
    public var size: Double
    public var color: Color

    public init(label: String, size: Double = 10, color: Color = .blue) {
        self.label = label
        self.size = size
        self.color = color
    }
}

