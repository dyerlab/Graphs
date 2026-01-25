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

    // Node ID mapping (user IDs to internal indices)
    private var nodeIndex: [AnyHashable: Int] = [:]

    public var isStable: Bool {
        state.alpha < config.alphaMin
    }

    public init(config: SimulationConfig = .default) {
        self.state = SimulationState(nodeCount: 0)
        self.config = config
    }

    // MARK: - Graph Mutation

    /// Set the nodes in the graph by their IDs.
    /// Positions are randomized; previous state is discarded.
    public func setNodes<ID: Hashable>(_ ids: [ID]) {
        nodeIndex.removeAll()
        for (index, id) in ids.enumerated() {
            nodeIndex[AnyHashable(id)] = index
        }
        state = SimulationState(nodeCount: ids.count)
        randomizePositions()
    }

    /// Set the edges between nodes.
    /// Edges reference nodes by their IDs; invalid references are ignored.
    public func setEdges<ID: Hashable>(
        _ edges: [(source: ID, target: ID, distance: Float)]
    ) {
        state.edges = edges.compactMap { edge in
            guard let source = nodeIndex[AnyHashable(edge.source)],
                  let target = nodeIndex[AnyHashable(edge.target)] else {
                return nil
            }
            return Edge(source: source, target: target, distance: edge.distance)
        }
    }

    /// Set edges with default distance.
    public func setEdges<ID: Hashable>(_ edges: [(source: ID, target: ID)]) {
        state.edges = edges.compactMap { edge in
            guard let source = nodeIndex[AnyHashable(edge.source)],
                  let target = nodeIndex[AnyHashable(edge.target)] else {
                return nil
            }
            return Edge(source: source, target: target)
        }
    }

    /// Get the internal index for a node ID.
    public func index<ID: Hashable>(of id: ID) -> Int? {
        nodeIndex[AnyHashable(id)]
    }

    // MARK: - Simulation Control

    /// Start the simulation. Call tick() from TimelineView's update.
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        // Reheat if stable
        if state.alpha < 0.1 {
            state.alpha = 0.3
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
        if state.alpha < 0.3 {
            state.alpha = 0.3
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

    private func randomizePositions(radius: Float = 100) {
        for i in 0..<state.nodeCount {
            let angle = Float.random(in: 0..<(2 * .pi))
            let r = Float.random(in: 0..<radius)
            state.x[i] = cos(angle) * r
            state.y[i] = sin(angle) * r
        }
    }
}
