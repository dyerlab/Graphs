//                      _                 _       _
//                   __| |_   _  ___ _ __| | __ _| |__
//                  / _` | | | |/ _ \ '__| |/ _` | '_ \
//                 | (_| | |_| |  __/ |  | | (_| | |_) |
//                  \__,_|\__, |\___|_|  |_|\__,_|_.__/
//                        |_ _/
//
//         Making Population Genetic Software That Doesn't Suck
//
//  Copyright (c) 2021-2026 Administravia LLC.  All Rights Reserved.
//

import Foundation

/// A named collection of edges representing a connectivity pattern.
///
/// `EdgeSet` groups related edges together with a name and optional metadata.
/// Multiple edge sets can share the same node set in a ``PopulationGraph``,
/// enabling quick switching between different graph connectivity patterns.
///
/// ## Overview
///
/// Edge sets are useful when you have a fixed set of nodes but want to visualize
/// different relationships between them. For example, you might have:
/// - Different generations of a genetic algorithm
/// - Various threshold levels for edge inclusion
/// - Comparison between different network inference methods
///
/// ## Example
///
/// ```swift
/// // Create an edge set representing close relationships
/// let closeConnections = EdgeSet(
///     name: "Strong Connections",
///     edges: [
///         Edge(source: 0, target: 1, distance: 20),
///         Edge(source: 1, target: 2, distance: 25)
///     ],
///     metadata: ["threshold": "0.8", "algorithm": "correlation"]
/// )
///
/// // Create another set with all relationships
/// let allConnections = EdgeSet(
///     name: "All Connections",
///     edges: [
///         Edge(source: 0, target: 1, distance: 20),
///         Edge(source: 1, target: 2, distance: 25),
///         Edge(source: 0, target: 2, distance: 60)
///     ],
///     metadata: ["threshold": "0.3"]
/// )
/// ```
///
/// ## Topics
///
/// ### Creating Edge Sets
/// - ``init(id:name:edges:metadata:)``
///
/// ### Edge Set Properties
/// - ``id``
/// - ``name``
/// - ``edges``
/// - ``metadata``
///
/// ### Inspecting Edge Sets
/// - ``count``
/// - ``isEmpty``
/// - ``isValid(for:)``
public struct EdgeSet: Identifiable, Sendable, Equatable {

    /// The unique identifier for this edge set.
    ///
    /// This UUID distinguishes edge sets even if they have the same name or edges.
    public let id: UUID

    /// A human-readable name for this edge set.
    ///
    /// Use descriptive names that help identify the connectivity pattern, such as
    /// "Generation 1", "High Confidence", or "Genetic Distance".
    public var name: String

    /// The collection of edges in this set.
    ///
    /// Each edge references nodes by their index in the ``PopulationGraph/nodes`` array.
    /// Use ``isValid(for:)`` to verify all edge indices are within bounds.
    public var edges: [Edge]

    /// Optional key-value metadata for this edge set.
    ///
    /// Use this to store additional information about the edge set, such as:
    /// - Algorithm parameters used to generate the edges
    /// - Timestamp of creation
    /// - Statistical measures
    /// - Source data identifiers
    ///
    /// ## Example
    ///
    /// ```swift
    /// let edgeSet = EdgeSet(
    ///     name: "Filtered",
    ///     edges: edges,
    ///     metadata: [
    ///         "created": "2024-01-15",
    ///         "threshold": "0.75",
    ///         "method": "correlation"
    ///     ]
    /// )
    /// ```
    public var metadata: [String: String]

    /// Creates a new edge set with the specified properties.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this edge set. Defaults to a new UUID.
    ///   - name: A human-readable name for this edge set. Defaults to empty string.
    ///   - edges: The collection of edges in this set. Defaults to empty array.
    ///   - metadata: Optional key-value metadata. Defaults to empty dictionary.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let edgeSet = EdgeSet(
    ///     name: "Primary Network",
    ///     edges: [
    ///         Edge(source: 0, target: 1),
    ///         Edge(source: 1, target: 2)
    ///     ]
    /// )
    /// ```
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

    /// Validates that all edges reference valid node indices.
    ///
    /// Call this method to verify that all edge source and target indices are
    /// within the bounds of the node array.
    ///
    /// - Parameter nodeCount: The number of nodes in the graph.
    /// - Returns: `true` if all edges have valid indices, `false` otherwise.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let edgeSet = EdgeSet(edges: [Edge(source: 0, target: 5)])
    ///
    /// edgeSet.isValid(for: 10)  // true - indices 0 and 5 are valid
    /// edgeSet.isValid(for: 3)   // false - index 5 is out of bounds
    /// ```
    public func isValid(for nodeCount: Int) -> Bool {
        edges.allSatisfy { edge in
            edge.source >= 0 && edge.source < nodeCount &&
            edge.target >= 0 && edge.target < nodeCount
        }
    }

    /// The number of edges in this set.
    public var count: Int { edges.count }

    /// A Boolean value indicating whether this edge set contains no edges.
    public var isEmpty: Bool { edges.isEmpty }
}
