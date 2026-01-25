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
import Observation
import simd

/// An observable simulation runner for force-directed graph layout.
///
/// `GraphSimulation` manages the physics simulation that positions nodes in a graph.
/// It applies various forces (repulsion, edge springs, centering, collision) to
/// iteratively find a visually pleasing layout.
///
/// ## Overview
///
/// The simulation uses a velocity Verlet integration scheme with configurable forces:
/// - **Many-body force**: Repels all nodes from each other (or attracts with positive strength)
/// - **Edge force**: Pulls connected nodes toward their target distance
/// - **Center force**: Pulls the graph's centroid toward the origin
/// - **Collide force**: Prevents node overlap
///
/// ## Basic Usage
///
/// ```swift
/// // Create and load a graph
/// let simulation = GraphSimulation()
/// simulation.load(graph)
///
/// // Start the simulation
/// simulation.start()
///
/// // In your SwiftUI view's TimelineView:
/// TimelineView(.animation(paused: !simulation.isRunning)) { _ in
///     Canvas { context, size in
///         simulation.tick()
///         // Draw nodes using simulation.state positions...
///     }
/// }
/// ```
///
/// ## Switching Edge Sets
///
/// When you have multiple edge sets, you can switch between them without
/// randomizing node positions:
///
/// ```swift
/// // Switch to a different edge set
/// graph.nextEdgeSet()
/// simulation.updateEdgeSet(graph.activeEdgeSet!)
/// simulation.reheat()  // Restart movement with new edges
/// ```
///
/// ## Interaction
///
/// Nodes can be pinned during user interaction (dragging):
///
/// ```swift
/// // Pin a node to follow the cursor
/// simulation.pin(nodeAt: nodeIndex, to: cursorPosition)
///
/// // Release when drag ends
/// simulation.unpin(nodeAt: nodeIndex)
/// simulation.reheat()
/// ```
///
/// ## Topics
///
/// ### Creating Simulations
/// - ``init(config:)``
///
/// ### Loading Data
/// - ``load(_:)``
/// - ``setNodes(_:)``
/// - ``setNodeCount(_:)``
/// - ``setEdges(_:)``
/// - ``updateEdgeSet(_:)``
///
/// ### Simulation Control
/// - ``start()``
/// - ``stop()``
/// - ``tick()``
/// - ``reheat(to:)``
/// - ``isRunning``
/// - ``isStable``
///
/// ### Node Interaction
/// - ``pin(nodeAt:to:)``
/// - ``unpin(nodeAt:)``
///
/// ### Node Lookup
/// - ``index(of:)``
/// - ``index(forLabel:)``
///
/// ### State Access
/// - ``state``
/// - ``config``
@Observable
@MainActor
public final class GraphSimulation {

    /// The current simulation state containing node positions, velocities, and edges.
    ///
    /// Access this property to read node positions for rendering. The state is updated
    /// each time ``tick()`` is called.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Get a node's position for rendering
    /// let pos = simulation.state[position: nodeIndex]
    /// let point = CGPoint(x: CGFloat(pos.x), y: CGFloat(pos.y))
    /// ```
    public private(set) var state: SimulationState

    /// Configuration parameters controlling simulation behavior.
    ///
    /// Modify this to adjust force strengths, decay rates, and other parameters.
    /// Changes take effect on the next ``tick()``.
    public var config: SimulationConfig

    /// Whether the simulation is currently running.
    ///
    /// When `true`, the simulation expects ``tick()`` to be called regularly
    /// (typically from a `TimelineView`). The simulation automatically stops
    /// when it reaches a stable state.
    public private(set) var isRunning: Bool = false

    private var nodes: [Node] = []

    /// Whether the simulation has reached a stable state.
    ///
    /// Returns `true` when the simulation's alpha has decayed below the
    /// minimum threshold (``SimulationConfig/alphaMin``). A stable simulation
    /// can be restarted with ``reheat(to:)``.
    public var isStable: Bool {
        state.alpha < config.alphaMin
    }

    /// Creates a new simulation with the specified configuration.
    ///
    /// The simulation starts empty with no nodes. Call ``load(_:)`` or
    /// ``setNodes(_:)`` to add graph data.
    ///
    /// - Parameter config: Configuration parameters. Defaults to ``SimulationConfig/default``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Default configuration
    /// let simulation = GraphSimulation()
    ///
    /// // Custom configuration with stronger repulsion
    /// var config = SimulationConfig.default
    /// config.manyBodyStrength = -50
    /// let simulation = GraphSimulation(config: config)
    /// ```
    public init(config: SimulationConfig = .default) {
        self.state = SimulationState(nodeCount: 0)
        self.config = config
    }

    // MARK: - Graph Loading

    /// Loads a complete graph into the simulation.
    ///
    /// This method initializes the simulation with the graph's nodes and active edge set.
    /// Node positions are randomized; any previous state is discarded.
    ///
    /// - Parameter graph: The graph to load.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let graph = PopulationGraph(nodes: nodes, edges: edges)
    /// simulation.load(graph)
    /// simulation.start()
    /// ```
    public func load(_ graph: PopulationGraph) {
        self.nodes = graph.nodes
        state = SimulationState(nodeCount: graph.nodeCount)
        state.edges = graph.edges
        randomizePositions()
    }

    /// Sets up the simulation with the specified nodes.
    ///
    /// Positions are randomized; any previous state is discarded. Use ``setEdges(_:)``
    /// to add edges after setting nodes.
    ///
    /// - Parameter nodes: The nodes to simulate.
    ///
    /// ## Example
    ///
    /// ```swift
    /// simulation.setNodes([nodeA, nodeB, nodeC])
    /// simulation.setEdges([Edge(source: 0, target: 1)])
    /// simulation.start()
    /// ```
    public func setNodes(_ nodes: [Node]) {
        self.nodes = nodes
        state = SimulationState(nodeCount: nodes.count)
        randomizePositions()
    }

    /// Sets up the simulation with a specific node count.
    ///
    /// Use this for programmatic simulations where you don't need ``Node`` objects.
    /// Positions are randomized; any previous state is discarded.
    ///
    /// - Parameter count: The number of nodes.
    public func setNodeCount(_ count: Int) {
        self.nodes = []
        state = SimulationState(nodeCount: count)
        randomizePositions()
    }

    // MARK: - Edge Management

    /// Sets the edges directly.
    ///
    /// This method preserves node positions, making it suitable for switching
    /// between edge sets. Call ``reheat(to:)`` afterward to restart movement.
    ///
    /// - Parameter edges: The new edges to use.
    ///
    /// ## Example
    ///
    /// ```swift
    /// simulation.setEdges(newEdges)
    /// simulation.reheat()
    /// ```
    public func setEdges(_ edges: [Edge]) {
        state.edges = edges
    }

    /// Updates the simulation with edges from an edge set.
    ///
    /// This is a convenience method equivalent to `setEdges(edgeSet.edges)`.
    /// Node positions are preserved. Call ``reheat(to:)`` afterward to restart movement.
    ///
    /// - Parameter edgeSet: The edge set containing the new edges.
    ///
    /// ## Example
    ///
    /// ```swift
    /// graph.nextEdgeSet()
    /// simulation.updateEdgeSet(graph.activeEdgeSet!)
    /// simulation.reheat(to: 0.5)
    /// ```
    public func updateEdgeSet(_ edgeSet: EdgeSet) {
        state.edges = edgeSet.edges
    }

    // MARK: - Node Lookup

    /// Finds the index of a node by reference.
    ///
    /// - Parameter node: The node to find.
    /// - Returns: The index of the node, or `nil` if not found.
    ///
    /// - Note: Requires nodes to be set via ``load(_:)`` or ``setNodes(_:)``.
    public func index(of node: Node) -> Int? {
        nodes.firstIndex(of: node)
    }

    /// Finds the index of a node by its label.
    ///
    /// - Parameter label: The label to search for.
    /// - Returns: The index of the first matching node, or `nil` if not found.
    ///
    /// - Note: Requires nodes to be set via ``load(_:)`` or ``setNodes(_:)``.
    public func index(forLabel label: String) -> Int? {
        nodes.firstIndex { $0.label == label }
    }

    // MARK: - Simulation Control

    /// Starts the simulation.
    ///
    /// After calling this method, you should call ``tick()`` regularly from a
    /// `TimelineView` or similar animation driver. If the simulation was stable,
    /// it will be reheated automatically.
    ///
    /// ## Example
    ///
    /// ```swift
    /// simulation.start()
    ///
    /// // In TimelineView:
    /// TimelineView(.animation(paused: !simulation.isRunning)) { _ in
    ///     Canvas { context, size in
    ///         simulation.tick()
    ///         // Render...
    ///     }
    /// }
    /// ```
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        if state.alpha < GraphConstants.reheatAlphaThreshold {
            state.alpha = GraphConstants.reheatAlphaValue
        }
    }

    /// Stops the simulation.
    ///
    /// The simulation preserves its current state and can be restarted with
    /// ``start()`` or ``reheat(to:)``.
    public func stop() {
        isRunning = false
    }

    /// Performs one simulation step.
    ///
    /// Call this method once per animation frame, typically from a `TimelineView`.
    /// Each tick applies all forces, integrates velocities into positions, and
    /// decays the simulation's alpha. The simulation automatically stops when
    /// alpha falls below the minimum threshold.
    ///
    /// - Note: This method does nothing if the simulation is not running or is stable.
    public func tick() {
        guard isRunning, state.alpha >= config.alphaMin else {
            if isRunning && state.alpha < config.alphaMin {
                stop()
            }
            return
        }

        applyManyBodyForce(
            to: &state,
            strength: config.manyBodyStrength,
            minDistance: config.manyBodyMinDistance
        )
        applyEdgeForce(to: &state)
        applyCenterForce(to: &state, strength: config.centerStrength)
        applyCollideForce(
            to: &state,
            radius: config.collideRadius,
            strength: config.collideStrength
        )

        integrate()

        state.alpha += (config.alphaTarget - state.alpha) * config.alphaDecay
    }

    private func integrate() {
        for i in 0..<state.nodeCount {
            if let fx = state.fixedX[i] {
                state.x[i] = fx
                state.vx[i] = 0
            } else {
                state.vx[i] *= config.velocityDecay
                state.x[i] += state.vx[i]
            }

            if let fy = state.fixedY[i] {
                state.y[i] = fy
                state.vy[i] = 0
            } else {
                state.vy[i] *= config.velocityDecay
                state.y[i] += state.vy[i]
            }
        }
    }

    // MARK: - Interaction

    /// Pins a node to a fixed position.
    ///
    /// Pinned nodes are constrained to their fixed position and don't respond to
    /// forces. They still exert forces on other nodes. Use this for dragging
    /// interactions.
    ///
    /// - Parameters:
    ///   - index: The index of the node to pin.
    ///   - position: The position to pin the node to.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // During drag gesture
    /// simulation.pin(nodeAt: draggedIndex, to: cursorPosition)
    /// if !simulation.isRunning {
    ///     simulation.start()
    /// }
    /// ```
    public func pin(nodeAt index: Int, to position: SIMD2<Float>) {
        guard index >= 0 && index < state.nodeCount else { return }
        state.fixedX[index] = position.x
        state.fixedY[index] = position.y
        state.x[index] = position.x
        state.y[index] = position.y

        if state.alpha < GraphConstants.reheatAlphaValue {
            state.alpha = GraphConstants.reheatAlphaValue
        }
    }

    /// Unpins a node, allowing it to move freely.
    ///
    /// Call this when a drag interaction ends to let the node settle naturally.
    ///
    /// - Parameter index: The index of the node to unpin.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // When drag ends
    /// simulation.unpin(nodeAt: draggedIndex)
    /// simulation.reheat(to: 0.3)
    /// ```
    public func unpin(nodeAt index: Int) {
        guard index >= 0 && index < state.nodeCount else { return }
        state.fixedX[index] = nil
        state.fixedY[index] = nil
    }

    /// Reheats the simulation to restart movement.
    ///
    /// Increases the simulation's alpha to the specified value and starts the
    /// simulation if it was stopped. Use this after changing edges or unpinning nodes.
    ///
    /// - Parameter alpha: The new alpha value. Defaults to 1.0 (full energy).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Full reheat for major changes
    /// simulation.reheat()
    ///
    /// // Gentle reheat for minor adjustments
    /// simulation.reheat(to: 0.3)
    /// ```
    public func reheat(to alpha: Float = 1.0) {
        state.alpha = alpha
        if !isRunning {
            start()
        }
    }

    // MARK: - Helpers

    private func randomizePositions(radius: Float = GraphConstants.initialPositionRadius) {
        for i in 0..<state.nodeCount {
            let angle = Float.random(in: 0..<(2 * .pi))
            let r = Float.random(in: 0..<radius)
            state.x[i] = cos(angle) * r
            state.y[i] = sin(angle) * r
        }
    }
}
