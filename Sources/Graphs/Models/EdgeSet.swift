import Foundation

/// A named collection of edges representing a connectivity pattern.
/// Multiple EdgeSets can share the same node set, enabling quick switching
/// between different graph representations.
public struct EdgeSet: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var edges: [Edge]

    /// Optional metadata for this edge set (e.g., generation, algorithm, timestamp)
    public var metadata: [String: String]

    public init(
        id: UUID = UUID(),
        name: String = "",
        edges: [Edge] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.edges = edges
        self.metadata = metadata
    }

    /// Check if all edges reference valid node indices
    public func isValid(for nodeCount: Int) -> Bool {
        edges.allSatisfy { edge in
            edge.source >= 0 && edge.source < nodeCount &&
            edge.target >= 0 && edge.target < nodeCount
        }
    }

    /// Number of edges in this set
    public var count: Int { edges.count }

    /// Whether this edge set is empty
    public var isEmpty: Bool { edges.isEmpty }
}
