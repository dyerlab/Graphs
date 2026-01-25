import Foundation

/// Represents an edge in the graph with spring properties.
/// Uses integer indices into the node array for efficiency.
public struct Edge: Sendable, Equatable, Hashable {
    /// Index of the source node in the nodes array
    public var source: Int

    /// Index of the target node in the nodes array
    public var target: Int

    /// Spring strength (how strongly nodes are pulled together)
    public var weight: Float

    /// Rest length of the spring (target distance between nodes)
    public var distance: Float

    public init(source: Int, target: Int, weight: Float = 1.0, distance: Float = 30.0) {
        self.source = source
        self.target = target
        self.weight = weight
        self.distance = distance
    }
}
