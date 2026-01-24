import Foundation

/// Represents a parsed edge from a .pgraph file.
public struct PGraphEdge: Sendable, Equatable {
    public let source: String
    public let target: String
    public let distance: Float

    public init(source: String, target: String, distance: Float) {
        self.source = source
        self.target = target
        self.distance = distance
    }
}
