import Foundation
import Observation
import simd

/// Observable simulation runner for force-directed graph layout.
/// Uses SwiftUI's TimelineView for animation timing.
@Observable
@MainActor
public final class GraphSimulation {
    // Published state for SwiftUI
    public private(set) var state: SimulationState
    public var config: SimulationConfig

    // Simulation control
    public private(set) var isRunning: Bool = false

    // Reference to nodes for lookups (optional, for convenience methods)
    private var nodes: [Node] = []

    public var isStable: Bool {
        state.alpha < config.alphaMin
    }

    public init(config: SimulationConfig = .default) {
        self.state = SimulationState(nodeCount: 0)
        self.config = config
    }

    // MARK: - Graph Loading

    /// Load a complete graph (nodes and active edge set).
    /// Positions are randomized; previous state is discarded.
    public func load(_ graph: PopulationGraph) {
        self.nodes = graph.nodes
        state = SimulationState(nodeCount: graph.nodeCount)
        state.edges = graph.edges
        randomizePositions()
    }

    /// Set up nodes only (for manual edge management).
    /// Positions are randomized; previous state is discarded.
    public func setNodes(_ nodes: [Node]) {
        self.nodes = nodes
        state = SimulationState(nodeCount: nodes.count)
        randomizePositions()
    }

    /// Set up with a specific node count (for programmatic use).
    /// Positions are randomized; previous state is discarded.
    public func setNodeCount(_ count: Int) {
        self.nodes = []
        state = SimulationState(nodeCount: count)
        randomizePositions()
    }

    // MARK: - Edge Management

    /// Set the edges directly (index-based).
    /// Preserves node positions - use for switching edge sets.
    public func setEdges(_ edges: [Edge]) {
        state.edges = edges
    }

    /// Update edges from an EdgeSet.
    /// Preserves node positions - use for switching edge sets.
    public func updateEdgeSet(_ edgeSet: EdgeSet) {
        state.edges = edgeSet.edges
    }

    // MARK: - Node Lookup

    /// Get the index of a node by reference (requires nodes to be set via load or setNodes)
    public func index(of node: Node) -> Int? {
        nodes.firstIndex(of: node)
    }

    /// Get the index of a node by label (requires nodes to be set via load or setNodes)
    public func index(forLabel label: String) -> Int? {
        nodes.firstIndex { $0.label == label }
    }

    // MARK: - Simulation Control

    /// Start the simulation. Call tick() from TimelineView's update.
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        // Reheat if stable
        if state.alpha < GraphConstants.reheatAlphaThreshold {
            state.alpha = GraphConstants.reheatAlphaValue
        }
    }

    /// Stop the simulation.
    public func stop() {
        isRunning = false
    }

    /// Perform one simulation step. Call this from TimelineView.
    public func tick() {
        guard isRunning, state.alpha >= config.alphaMin else {
            if isRunning && state.alpha < config.alphaMin {
                stop()
            }
            return
        }

        // Apply forces
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

        // Integrate velocities -> positions
        integrate()

        // Decay alpha
        state.alpha += (config.alphaTarget - state.alpha) * config.alphaDecay
    }

    private func integrate() {
        for i in 0..<state.nodeCount {
            // Apply fixation
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

    /// Pin a node to a fixed position.
    public func pin(nodeAt index: Int, to position: SIMD2<Float>) {
        guard index >= 0 && index < state.nodeCount else { return }
        state.fixedX[index] = position.x
        state.fixedY[index] = position.y
        state.x[index] = position.x
        state.y[index] = position.y

        // Reheat simulation
        if state.alpha < GraphConstants.reheatAlphaValue {
            state.alpha = GraphConstants.reheatAlphaValue
        }
    }

    /// Unpin a node, allowing it to move freely.
    public func unpin(nodeAt index: Int) {
        guard index >= 0 && index < state.nodeCount else { return }
        state.fixedX[index] = nil
        state.fixedY[index] = nil
    }

    /// Reheat the simulation to restart movement.
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
