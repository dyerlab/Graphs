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
import SwiftUI

/// A data store for graph data with a fixed node set and multiple switchable edge sets.
///
/// `PopulationGraph` is the primary container for graph data in the Graphs library.
/// It manages a fixed set of ``Node`` instances and multiple ``EdgeSet`` collections,
/// allowing quick switching between different connectivity patterns.
///
/// ## Overview
///
/// This design is optimized for use cases where you have a stable set of nodes
/// (such as populations, locations, or entities) but want to visualize different
/// relationships between them. Examples include:
///
/// - Viewing different generations of an evolutionary algorithm
/// - Comparing networks at different statistical thresholds
/// - Switching between different types of relationships (genetic, geographic, etc.)
///
/// ## Basic Usage
///
/// ```swift
/// // Create nodes
/// var graph = PopulationGraph()
/// graph.addNode(Node(label: "Pop A", color: .blue))
/// graph.addNode(Node(label: "Pop B", color: .green))
/// graph.addNode(Node(label: "Pop C", color: .red))
///
/// // Connect nodes by label
/// graph.connect("Pop A", to: "Pop B", distance: 30)
/// graph.connect("Pop B", to: "Pop C", distance: 25)
///
/// // Use with simulation
/// let simulation = GraphSimulation()
/// simulation.load(graph)
/// ```
///
/// ## Multiple Edge Sets
///
/// ```swift
/// // Create multiple connectivity patterns
/// let generation1 = EdgeSet(name: "Gen 1", edges: [...])
/// let generation2 = EdgeSet(name: "Gen 2", edges: [...])
///
/// graph.addEdgeSet(generation1)
/// graph.addEdgeSet(generation2)
///
/// // Switch between them
/// graph.nextEdgeSet()     // Move to next
/// graph.setActiveEdgeSet(0)  // Jump to specific index
///
/// // Update simulation with new edges
/// simulation.updateEdgeSet(graph.activeEdgeSet!)
/// ```
///
/// ## Topics
///
/// ### Creating Graphs
/// - ``init(nodes:edgeSets:activeEdgeSetIndex:)``
/// - ``init(nodes:edges:edgeSetName:)``
///
/// ### Graph Properties
/// - ``nodes``
/// - ``nodeCount``
/// - ``edgeSets``
/// - ``activeEdgeSetIndex``
/// - ``activeEdgeSet``
/// - ``edges``
///
/// ### Managing Nodes
/// - ``addNode(_:)``
/// - ``nodeIndex(of:)``
/// - ``nodeIndex(forLabel:)``
///
/// ### Managing Edge Sets
/// - ``addEdgeSet(_:)``
/// - ``removeEdgeSet(at:)``
/// - ``setActiveEdgeSet(_:)-4j9q0``
/// - ``setActiveEdgeSet(_:)-7vhgx``
/// - ``nextEdgeSet()``
/// - ``previousEdgeSet()``
///
/// ### Creating Edges
/// - ``connect(_:to:distance:weight:)-6z1ld``
/// - ``connect(_:to:distance:weight:)-1epna``
/// - ``addEdge(_:)``
///
/// ### Sample Graphs
/// - ``triangleGraph``
/// - ``starGraph``
/// - ``vcuGraph``
public struct PopulationGraph: Sendable {

    // MARK: - Properties

    /// The fixed set of nodes in this graph.
    ///
    /// Nodes are referenced by their index in this array. Adding or removing nodes
    /// may invalidate existing edges if their indices become out of bounds.
    ///
    /// - Important: Modifying this array after edges have been created may cause
    ///   edge indices to become invalid. Use ``EdgeSet/isValid(for:)`` to verify.
    public var nodes: [Node]

    /// Collection of edge sets representing different connectivity patterns.
    ///
    /// Each edge set contains a complete set of edges for the graph. Only one
    /// edge set is active at a time, determined by ``activeEdgeSetIndex``.
    public var edgeSets: [EdgeSet]

    /// The index of the currently active edge set.
    ///
    /// This determines which ``EdgeSet`` is used when accessing ``edges`` or
    /// ``activeEdgeSet``. Use ``setActiveEdgeSet(_:)-4j9q0``, ``nextEdgeSet()``,
    /// or ``previousEdgeSet()`` to change the active set.
    public var activeEdgeSetIndex: Int

    // MARK: - Computed Properties

    /// The number of nodes in the graph.
    public var nodeCount: Int { nodes.count }

    /// The currently active edge set, or `nil` if no edge sets exist.
    ///
    /// Use this to access the full ``EdgeSet`` including its name and metadata.
    /// For just the edges, use ``edges`` instead.
    public var activeEdgeSet: EdgeSet? {
        guard edgeSets.indices.contains(activeEdgeSetIndex) else { return nil }
        return edgeSets[activeEdgeSetIndex]
    }

    /// The edges in the currently active edge set.
    ///
    /// This is a convenience accessor equivalent to `activeEdgeSet?.edges ?? []`.
    /// Returns an empty array if no edge sets exist.
    public var edges: [Edge] {
        activeEdgeSet?.edges ?? []
    }

    // MARK: - Initialization

    /// Creates a new graph with the specified nodes and edge sets.
    ///
    /// - Parameters:
    ///   - nodes: The fixed set of nodes for this graph. Defaults to empty.
    ///   - edgeSets: Collection of edge sets. Defaults to empty.
    ///   - activeEdgeSetIndex: Index of the initially active edge set. Defaults to 0.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let nodes = [Node(label: "A"), Node(label: "B")]
    /// let edgeSet = EdgeSet(name: "Default", edges: [Edge(source: 0, target: 1)])
    /// let graph = PopulationGraph(nodes: nodes, edgeSets: [edgeSet])
    /// ```
    public init(nodes: [Node] = [], edgeSets: [EdgeSet] = [], activeEdgeSetIndex: Int = 0) {
        self.nodes = nodes
        self.edgeSets = edgeSets
        self.activeEdgeSetIndex = edgeSets.isEmpty ? 0 : min(activeEdgeSetIndex, edgeSets.count - 1)
    }

    /// Creates a new graph with nodes and a single edge set.
    ///
    /// This convenience initializer creates a graph with one edge set containing
    /// the provided edges. Use this when you don't need multiple edge sets.
    ///
    /// - Parameters:
    ///   - nodes: The fixed set of nodes for this graph.
    ///   - edges: The edges connecting the nodes.
    ///   - edgeSetName: Name for the edge set. Defaults to "Default".
    ///
    /// ## Example
    ///
    /// ```swift
    /// let nodes = [Node(label: "A"), Node(label: "B"), Node(label: "C")]
    /// let edges = [
    ///     Edge(source: 0, target: 1),
    ///     Edge(source: 1, target: 2)
    /// ]
    /// let graph = PopulationGraph(nodes: nodes, edges: edges, edgeSetName: "My Network")
    /// ```
    public init(nodes: [Node], edges: [Edge], edgeSetName: String = "Default") {
        self.nodes = nodes
        self.edgeSets = [EdgeSet(name: edgeSetName, edges: edges)]
        self.activeEdgeSetIndex = 0
    }

    // MARK: - Node Management

    /// Adds a node to the graph.
    ///
    /// The new node is appended to the end of the ``nodes`` array. Its index
    /// will be `nodeCount - 1` after this call.
    ///
    /// - Parameter node: The node to add.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var graph = PopulationGraph()
    /// graph.addNode(Node(label: "Population A", color: .blue))
    /// graph.addNode(Node(label: "Population B", color: .green))
    /// ```
    public mutating func addNode(_ node: Node) {
        nodes.append(node)
    }

    /// Finds the index of a node by reference.
    ///
    /// This method compares nodes by identity (using their ``Node/id``).
    ///
    /// - Parameter node: The node to find.
    /// - Returns: The index of the node, or `nil` if not found.
    public func nodeIndex(of node: Node) -> Int? {
        nodes.firstIndex(of: node)
    }

    /// Finds the index of a node by its label.
    ///
    /// - Parameter label: The label to search for.
    /// - Returns: The index of the first node with a matching label, or `nil` if not found.
    ///
    /// - Note: If multiple nodes have the same label, this returns the first match.
    public func nodeIndex(forLabel label: String) -> Int? {
        nodes.firstIndex { $0.label == label }
    }

    // MARK: - EdgeSet Management

    /// Adds a new edge set to the graph.
    ///
    /// If this is the first edge set added, it automatically becomes the active set.
    ///
    /// - Parameter edgeSet: The edge set to add.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let highConfidence = EdgeSet(
    ///     name: "High Confidence",
    ///     edges: [...],
    ///     metadata: ["threshold": "0.9"]
    /// )
    /// graph.addEdgeSet(highConfidence)
    /// ```
    public mutating func addEdgeSet(_ edgeSet: EdgeSet) {
        edgeSets.append(edgeSet)
        if edgeSets.count == 1 {
            activeEdgeSetIndex = 0
        }
    }

    /// Removes an edge set at the specified index.
    ///
    /// If the removed set was active, the active index is adjusted to remain valid.
    ///
    /// - Parameter index: The index of the edge set to remove.
    public mutating func removeEdgeSet(at index: Int) {
        guard edgeSets.indices.contains(index) else { return }
        edgeSets.remove(at: index)
        if activeEdgeSetIndex >= edgeSets.count {
            activeEdgeSetIndex = max(0, edgeSets.count - 1)
        }
    }

    /// Sets the active edge set by index.
    ///
    /// - Parameter index: The index of the edge set to activate.
    ///
    /// - Note: This method does nothing if the index is out of bounds.
    public mutating func setActiveEdgeSet(_ index: Int) {
        guard edgeSets.indices.contains(index) else { return }
        activeEdgeSetIndex = index
    }

    /// Sets the active edge set by matching its ID.
    ///
    /// - Parameter edgeSet: The edge set to activate (matched by ``EdgeSet/id``).
    ///
    /// - Note: This method does nothing if no edge set with a matching ID is found.
    public mutating func setActiveEdgeSet(_ edgeSet: EdgeSet) {
        if let index = edgeSets.firstIndex(where: { $0.id == edgeSet.id }) {
            activeEdgeSetIndex = index
        }
    }

    /// Advances to the next edge set, wrapping to the first if at the end.
    ///
    /// This is useful for cycling through edge sets in a UI, such as with
    /// keyboard shortcuts or navigation buttons.
    public mutating func nextEdgeSet() {
        guard !edgeSets.isEmpty else { return }
        activeEdgeSetIndex = (activeEdgeSetIndex + 1) % edgeSets.count
    }

    /// Moves to the previous edge set, wrapping to the last if at the beginning.
    ///
    /// This is useful for cycling through edge sets in a UI, such as with
    /// keyboard shortcuts or navigation buttons.
    public mutating func previousEdgeSet() {
        guard !edgeSets.isEmpty else { return }
        activeEdgeSetIndex = (activeEdgeSetIndex - 1 + edgeSets.count) % edgeSets.count
    }

    // MARK: - Edge Creation Helpers

    /// Connects two nodes by their labels in the active edge set.
    ///
    /// This is a convenience method that looks up node indices by label and creates
    /// an edge between them. If either label is not found, no edge is created.
    ///
    /// - Parameters:
    ///   - label1: The label of the source node.
    ///   - label2: The label of the target node.
    ///   - distance: The target distance between nodes. Defaults to 30.0.
    ///   - weight: The spring strength. Defaults to 1.0.
    ///
    /// ## Example
    ///
    /// ```swift
    /// graph.addNode(Node(label: "Alpha"))
    /// graph.addNode(Node(label: "Beta"))
    /// graph.connect("Alpha", to: "Beta", distance: 50)
    /// ```
    public mutating func connect(_ label1: String, to label2: String, distance: Float = 30.0, weight: Float = 1.0) {
        guard let idx1 = nodeIndex(forLabel: label1),
              let idx2 = nodeIndex(forLabel: label2) else { return }

        addEdge(Edge(source: idx1, target: idx2, weight: weight, distance: distance))
    }

    /// Connects two nodes by reference in the active edge set.
    ///
    /// This method looks up node indices and creates an edge between them.
    /// If either node is not found in the graph, no edge is created.
    ///
    /// - Parameters:
    ///   - node1: The source node.
    ///   - node2: The target node.
    ///   - distance: The target distance between nodes. Defaults to 30.0.
    ///   - weight: The spring strength. Defaults to 1.0.
    public mutating func connect(_ node1: Node, to node2: Node, distance: Float = 30.0, weight: Float = 1.0) {
        guard let idx1 = nodeIndex(of: node1),
              let idx2 = nodeIndex(of: node2) else { return }

        addEdge(Edge(source: idx1, target: idx2, weight: weight, distance: distance))
    }

    /// Adds an edge to the active edge set.
    ///
    /// If no edge sets exist, a new "Default" edge set is created automatically.
    ///
    /// - Parameter edge: The edge to add.
    ///
    /// - Important: Ensure the edge's source and target indices are valid for this
    ///   graph's node array.
    public mutating func addEdge(_ edge: Edge) {
        guard edgeSets.indices.contains(activeEdgeSetIndex) else {
            edgeSets.append(EdgeSet(name: "Default", edges: [edge]))
            activeEdgeSetIndex = 0
            return
        }
        edgeSets[activeEdgeSetIndex].edges.append(edge)
    }
}

// MARK: - Sample Graphs for Testing/Previews

public extension PopulationGraph {

    /// A simple triangle graph for testing and previews.
    ///
    /// This graph contains three nodes (A, B, C) connected in a triangle formation.
    /// Each node has a distinct color (red, green, blue) and size of 20 points.
    static let triangleGraph: PopulationGraph = {
        let nodes = [
            Node(label: "A", size: 20, color: .red),
            Node(label: "B", size: 20, color: .green),
            Node(label: "C", size: 20, color: .blue)
        ]
        let edges: [Edge] = [
            Edge(source: 0, target: 1, distance: 50),
            Edge(source: 1, target: 2, distance: 50),
            Edge(source: 2, target: 0, distance: 50)
        ]
        return PopulationGraph(nodes: nodes, edges: edges, edgeSetName: "Triangle")
    }()

    /// A star graph for testing and previews.
    ///
    /// This graph contains a central hub node connected to six satellite nodes.
    /// The center is orange and larger (30 points), while satellites are blue
    /// and smaller (15 points).
    static let starGraph: PopulationGraph = {
        let center = Node(label: "Center", size: 30, color: .orange)
        let satellites = (1...6).map { i in
            Node(label: "N\(i)", size: 15, color: .blue)
        }
        let nodes = [center] + satellites
        let edges: [Edge] = (1...6).map { i in
            Edge(source: 0, target: i, distance: 40)
        }
        return PopulationGraph(nodes: nodes, edges: edges, edgeSetName: "Star")
    }()

    /// The VCU sample graph loaded from the bundle.
    ///
    /// This graph contains population data from a real-world dataset.
    /// Returns an empty graph if the bundled file cannot be loaded.
    static var vcuGraph: PopulationGraph {
        if let graph = try? loadBundledGraph(named: "vcu") {
            return graph
        } else {
            return PopulationGraph()
        }
    }
}
