/// Represents an edge in the graph with spring properties.
public struct Link: Sendable, Equatable, Hashable {
    /// Index of the source node
    public var source: Int

    /// Index of the target node
    public var target: Int

    /// Spring strength (how strongly nodes are pulled together)
    public var strength: Float

    /// Rest length of the spring (target distance between nodes)
    public var distance: Float

    public init(source: Int, target: Int, strength: Float = 1.0, distance: Float = 30.0) {
        self.source = source
        self.target = target
        self.strength = strength
        self.distance = distance
    }
}
