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

import SwiftUI

/// A vertex in a graph with visual properties for rendering.
///
/// `Node` represents a single vertex in a ``PopulationGraph``. Each node has a unique
/// identifier, a display label, and visual properties (size and color) used when
/// rendering the graph.
///
/// ## Overview
///
/// Nodes are the fundamental building blocks of a graph. They are connected by
/// ``Edge`` instances to form the graph structure. The visual properties of nodes
/// (size and color) are used by ``GraphView`` when rendering.
///
/// ## Example
///
/// ```swift
/// // Create nodes with default styling
/// let nodeA = Node(label: "Population A")
/// let nodeB = Node(label: "Population B")
///
/// // Create a node with custom visual properties
/// let hub = Node(label: "Hub", size: 30, color: .orange)
/// ```
///
/// ## Identity
///
/// Nodes are identified by their ``id`` property, which is a UUID generated automatically
/// at initialization. Two nodes with the same label are considered different entities
/// if they have different IDs.
///
/// ## Topics
///
/// ### Creating Nodes
/// - ``init(label:size:color:)``
///
/// ### Node Properties
/// - ``id``
/// - ``label``
/// - ``size``
/// - ``color``
public struct Node: Identifiable, Sendable, Equatable, Hashable {

    /// The unique identifier for this node.
    ///
    /// This UUID is generated automatically when the node is created and is used
    /// to distinguish nodes with identical labels.
    public var id = UUID()

    /// The display label for this node.
    ///
    /// This text is shown next to the node when labels are enabled in ``GraphView``.
    /// Labels should be concise but descriptive.
    public var label: String

    /// The visual diameter of this node in points.
    ///
    /// The node is rendered as a circle with this diameter. Larger values create
    /// more prominent nodes. The default value is 10 points.
    ///
    /// - Note: The actual rendered size may be affected by the ``GraphDisplaySettings/nodeScaleFactor``
    ///   setting in the graph view.
    public var size: Double

    /// The fill color of this node.
    ///
    /// This color is used to fill the circular node shape. The default value is `.blue`.
    ///
    /// - Note: This color may be overridden by ``GraphDisplaySettings/nodeColorOverride``
    ///   if set in the graph view settings.
    public var color: Color

    /// Creates a new node with the specified properties.
    ///
    /// - Parameters:
    ///   - label: The display label for this node. This text is shown when labels are enabled.
    ///   - size: The visual diameter of this node in points. Defaults to 10.
    ///   - color: The fill color of this node. Defaults to `.blue`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a simple node
    /// let node = Node(label: "Alpha")
    ///
    /// // Create a large red node
    /// let important = Node(label: "Central", size: 25, color: .red)
    /// ```
    public init(label: String, size: Double = 10, color: Color = .blue) {
        self.label = label
        self.size = size
        self.color = color
    }
}
