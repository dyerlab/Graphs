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
/// Designed for use cases where the same nodes have many different connectivity patterns.
public struct PopulationGraph: Sendable {
    // MARK: - Properties

    /// The fixed set of nodes in this graph
    public var nodes: [Node]

    /// Collection of edge sets (different connectivity patterns)
    public var edgeSets: [EdgeSet]

    /// Index of the currently active edge set
    public var activeEdgeSetIndex: Int

    // MARK: - Computed Properties

    /// Number of nodes in the graph
    public var nodeCount: Int { nodes.count }

    /// The currently active edge set, or nil if no edge sets exist
    public var activeEdgeSet: EdgeSet? {
        guard edgeSets.indices.contains(activeEdgeSetIndex) else { return nil }
        return edgeSets[activeEdgeSetIndex]
    }

    /// Convenience accessor for edges in the active edge set
    public var edges: [Edge] {
        activeEdgeSet?.edges ?? []
    }

    // MARK: - Initialization

    public init(nodes: [Node] = [], edgeSets: [EdgeSet] = [], activeEdgeSetIndex: Int = 0) {
        self.nodes = nodes
        self.edgeSets = edgeSets
        self.activeEdgeSetIndex = edgeSets.isEmpty ? 0 : min(activeEdgeSetIndex, edgeSets.count - 1)
    }

    /// Convenience initializer with a single edge set
    public init(nodes: [Node], edges: [Edge], edgeSetName: String = "Default") {
        self.nodes = nodes
        self.edgeSets = [EdgeSet(name: edgeSetName, edges: edges)]
        self.activeEdgeSetIndex = 0
    }

    // MARK: - Node Management

    /// Add a node to the graph
    public mutating func addNode(_ node: Node) {
        nodes.append(node)
    }

    /// Find the index of a node by reference
    public func nodeIndex(of node: Node) -> Int? {
        nodes.firstIndex(of: node)
    }

    /// Find the index of a node by label
    public func nodeIndex(forLabel label: String) -> Int? {
        nodes.firstIndex { $0.label == label }
    }

    // MARK: - EdgeSet Management

    /// Add a new edge set to the graph
    public mutating func addEdgeSet(_ edgeSet: EdgeSet) {
        edgeSets.append(edgeSet)
        // If this is the first edge set, make it active
        if edgeSets.count == 1 {
            activeEdgeSetIndex = 0
        }
    }

    /// Remove an edge set at the given index
    public mutating func removeEdgeSet(at index: Int) {
        guard edgeSets.indices.contains(index) else { return }
        edgeSets.remove(at: index)
        // Adjust active index if needed
        if activeEdgeSetIndex >= edgeSets.count {
            activeEdgeSetIndex = max(0, edgeSets.count - 1)
        }
    }

    /// Set the active edge set by index
    public mutating func setActiveEdgeSet(_ index: Int) {
        guard edgeSets.indices.contains(index) else { return }
        activeEdgeSetIndex = index
    }

    /// Set the active edge set by finding its ID
    public mutating func setActiveEdgeSet(_ edgeSet: EdgeSet) {
        if let index = edgeSets.firstIndex(where: { $0.id == edgeSet.id }) {
            activeEdgeSetIndex = index
        }
    }

    /// Move to the next edge set (wraps around)
    public mutating func nextEdgeSet() {
        guard !edgeSets.isEmpty else { return }
        activeEdgeSetIndex = (activeEdgeSetIndex + 1) % edgeSets.count
    }

    /// Move to the previous edge set (wraps around)
    public mutating func previousEdgeSet() {
        guard !edgeSets.isEmpty else { return }
        activeEdgeSetIndex = (activeEdgeSetIndex - 1 + edgeSets.count) % edgeSets.count
    }

    // MARK: - Edge Creation Helpers

    /// Connect two nodes by their labels in the active edge set
    public mutating func connect(_ label1: String, to label2: String, distance: Float = 30.0, weight: Float = 1.0) {
        guard let idx1 = nodeIndex(forLabel: label1),
              let idx2 = nodeIndex(forLabel: label2) else { return }

        addEdge(Edge(source: idx1, target: idx2, weight: weight, distance: distance))
    }

    /// Connect two nodes by reference in the active edge set
    public mutating func connect(_ node1: Node, to node2: Node, distance: Float = 30.0, weight: Float = 1.0) {
        guard let idx1 = nodeIndex(of: node1),
              let idx2 = nodeIndex(of: node2) else { return }

        addEdge(Edge(source: idx1, target: idx2, weight: weight, distance: distance))
    }

    /// Add an edge to the active edge set
    public mutating func addEdge(_ edge: Edge) {
        guard edgeSets.indices.contains(activeEdgeSetIndex) else {
            // Create a default edge set if none exists
            edgeSets.append(EdgeSet(name: "Default", edges: [edge]))
            activeEdgeSetIndex = 0
            return
        }
        edgeSets[activeEdgeSetIndex].edges.append(edge)
    }
}

// MARK: - Sample Graphs for Testing/Previews

public extension PopulationGraph {

    /// A simple triangle graph for testing/previews
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

    /// A star graph for testing/previews
    static let starGraph: PopulationGraph = {
        let center = Node(label: "Center", size: 30, color: .orange)
        let satellites = (1...6).map { i in
            Node(label: "N\(i)", size: 15, color: .blue)
        }
        let nodes = [center] + satellites
        // Center is index 0, satellites are indices 1-6
        let edges: [Edge] = (1...6).map { i in
            Edge(source: 0, target: i, distance: 40)
        }
        return PopulationGraph(nodes: nodes, edges: edges, edgeSetName: "Star")
    }()

    /// Load the VCU sample graph from bundle
    static var vcuGraph: PopulationGraph {
        if let graph = try? loadBundledGraph(named: "vcu") {
            return graph
        } else {
            return PopulationGraph()
        }
    }
}
