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

/// A connection between two nodes in a graph with spring-like physics properties.
///
/// `Edge` represents a directed connection between two nodes, identified by their
/// indices in the node array. Each edge has physics properties that control how
/// the force-directed simulation treats the connection.
///
/// ## Overview
///
/// Edges connect nodes in a ``PopulationGraph`` and are grouped into ``EdgeSet``
/// collections. Using integer indices rather than node references provides O(1)
/// lookup performance, which is critical when switching between thousands of edge sets.
///
/// ## Physics Model
///
/// Each edge acts as a spring in the force simulation:
/// - The ``distance`` property is the spring's rest length (target distance between nodes)
/// - The ``weight`` property controls the spring strength (how strongly nodes are pulled together)
///
/// ## Example
///
/// ```swift
/// // Connect node 0 to node 1 with default spring properties
/// let edge1 = Edge(source: 0, target: 1)
///
/// // Create a strong, short connection
/// let edge2 = Edge(source: 1, target: 2, weight: 2.0, distance: 20.0)
///
/// // Create a weak, long connection
/// let edge3 = Edge(source: 0, target: 2, weight: 0.5, distance: 80.0)
/// ```
///
/// ## Topics
///
/// ### Creating Edges
/// - ``init(source:target:weight:distance:)``
///
/// ### Node References
/// - ``source``
/// - ``target``
///
/// ### Physics Properties
/// - ``weight``
/// - ``distance``
public struct Edge: Sendable, Equatable, Hashable {

    /// The index of the source node in the ``PopulationGraph/nodes`` array.
    ///
    /// This must be a valid index (0 to nodeCount-1) in the graph's node array.
    /// Use ``PopulationGraph/nodeIndex(forLabel:)`` to find a node's index by its label.
    public var source: Int

    /// The index of the target node in the ``PopulationGraph/nodes`` array.
    ///
    /// This must be a valid index (0 to nodeCount-1) in the graph's node array.
    /// Use ``PopulationGraph/nodeIndex(forLabel:)`` to find a node's index by its label.
    public var target: Int

    /// The spring strength of this edge.
    ///
    /// Higher values cause connected nodes to be pulled together more strongly.
    /// A value of 1.0 represents normal strength. Values greater than 1.0 create
    /// stronger springs, while values less than 1.0 create weaker springs.
    ///
    /// The default value is 1.0.
    public var weight: Float

    /// The target distance between connected nodes in simulation units.
    ///
    /// This is the rest length of the spring. The simulation applies forces to
    /// move connected nodes toward this distance apart. Shorter distances create
    /// tighter clusters, while longer distances spread nodes further apart.
    ///
    /// The default value is 30.0.
    public var distance: Float

    /// Creates a new edge connecting two nodes.
    ///
    /// - Parameters:
    ///   - source: The index of the source node in the nodes array.
    ///   - target: The index of the target node in the nodes array.
    ///   - weight: The spring strength. Higher values pull nodes together more strongly. Defaults to 1.0.
    ///   - distance: The target distance between nodes in simulation units. Defaults to 30.0.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Basic edge with defaults
    /// let edge = Edge(source: 0, target: 1)
    ///
    /// // Custom spring properties
    /// let strongEdge = Edge(source: 0, target: 1, weight: 2.0, distance: 15.0)
    /// ```
    ///
    /// - Important: Ensure that `source` and `target` are valid indices for the
    ///   graph's node array. Use ``EdgeSet/isValid(for:)`` to validate edges.
    public init(source: Int, target: Int, weight: Float = 1.0, distance: Float = 30.0) {
        self.source = source
        self.target = target
        self.weight = weight
        self.distance = distance
    }
}
