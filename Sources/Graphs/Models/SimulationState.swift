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

import simd

/// The mutable state of a force-directed graph simulation.
///
/// `SimulationState` uses a Structure-of-Arrays (SoA) layout for cache-efficient
/// access during force calculations. This is a value type that can be copied for
/// undo/redo functionality or creating snapshots.
///
/// ## Overview
///
/// The simulation state contains:
/// - Node positions (x, y coordinates)
/// - Node velocities (for physics integration)
/// - Fixed position constraints (for pinned nodes)
/// - The edge list defining connections
/// - The simulation's energy level (alpha)
///
/// ## Structure of Arrays
///
/// Rather than storing node data as an array of structs, this type uses separate
/// arrays for each property. This improves cache utilization when iterating over
/// a single property across all nodes, which is the common pattern in force calculations.
///
/// ```swift
/// // Accessing positions for all nodes is cache-friendly
/// for i in 0..<state.nodeCount {
///     let pos = SIMD2(state.x[i], state.y[i])
///     // Process position...
/// }
/// ```
///
/// ## Topics
///
/// ### Creating State
/// - ``init(nodeCount:)``
///
/// ### Node Properties
/// - ``nodeCount``
/// - ``x``
/// - ``y``
/// - ``vx``
/// - ``vy``
/// - ``fixedX``
/// - ``fixedY``
///
/// ### Graph Structure
/// - ``edges``
///
/// ### Simulation Energy
/// - ``alpha``
///
/// ### Convenience Accessors
/// - ``subscript(position:)``
/// - ``subscript(velocity:)``
public struct SimulationState: Sendable, Equatable {

    /// X coordinates of all nodes.
    ///
    /// Values are in simulation units, centered around 0. Positive values are to the right.
    public var x: [Float]

    /// Y coordinates of all nodes.
    ///
    /// Values are in simulation units, centered around 0. Positive values are downward
    /// (following screen coordinate conventions).
    public var y: [Float]

    /// X velocity components for all nodes.
    ///
    /// Updated by force calculations and integrated into positions each tick.
    /// Velocities decay over time based on ``SimulationConfig/velocityDecay``.
    public var vx: [Float]

    /// Y velocity components for all nodes.
    ///
    /// Updated by force calculations and integrated into positions each tick.
    /// Velocities decay over time based on ``SimulationConfig/velocityDecay``.
    public var vy: [Float]

    /// Fixed X positions for pinned nodes.
    ///
    /// When not `nil`, the node at this index is constrained to this X position.
    /// Pinned nodes don't respond to forces but still affect other nodes.
    public var fixedX: [Float?]

    /// Fixed Y positions for pinned nodes.
    ///
    /// When not `nil`, the node at this index is constrained to this Y position.
    /// Pinned nodes don't respond to forces but still affect other nodes.
    public var fixedY: [Float?]

    /// The edges connecting nodes in the simulation.
    ///
    /// Each edge references nodes by index and has spring properties (distance, weight)
    /// that affect the ``applyEdgeForce(to:)`` calculation.
    public var edges: [Edge]

    /// The simulation's energy level.
    ///
    /// Alpha starts at 1.0 and decays toward ``SimulationConfig/alphaTarget`` each tick.
    /// When alpha falls below ``SimulationConfig/alphaMin``, the simulation stops.
    /// Force magnitudes are scaled by alpha, so the simulation naturally settles.
    ///
    /// - Note: Use ``GraphSimulation/reheat(to:)`` to increase alpha and restart movement.
    public var alpha: Float

    /// The number of nodes in the simulation.
    public var nodeCount: Int { x.count }

    /// Creates a new simulation state for the specified number of nodes.
    ///
    /// All positions and velocities are initialized to zero. Alpha starts at 1.0.
    /// The edges array is empty.
    ///
    /// - Parameter nodeCount: The number of nodes in the simulation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var state = SimulationState(nodeCount: 10)
    /// state.edges = [Edge(source: 0, target: 1)]
    /// state.alpha = 1.0
    /// ```
    public init(nodeCount: Int) {
        x = [Float](repeating: 0, count: nodeCount)
        y = [Float](repeating: 0, count: nodeCount)
        vx = [Float](repeating: 0, count: nodeCount)
        vy = [Float](repeating: 0, count: nodeCount)
        fixedX = [Float?](repeating: nil, count: nodeCount)
        fixedY = [Float?](repeating: nil, count: nodeCount)
        edges = []
        alpha = 1.0
    }

    /// Accesses the position of a node as a SIMD2 vector.
    ///
    /// This subscript provides convenient access to node positions without
    /// manually combining x and y arrays.
    ///
    /// - Parameter index: The node index.
    /// - Returns: The position as a SIMD2<Float> vector.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let position = state[position: 0]
    /// state[position: 1] = SIMD2(100, 50)
    /// ```
    public subscript(position index: Int) -> SIMD2<Float> {
        get { SIMD2(x[index], y[index]) }
        set { x[index] = newValue.x; y[index] = newValue.y }
    }

    /// Accesses the velocity of a node as a SIMD2 vector.
    ///
    /// This subscript provides convenient access to node velocities without
    /// manually combining vx and vy arrays.
    ///
    /// - Parameter index: The node index.
    /// - Returns: The velocity as a SIMD2<Float> vector.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let velocity = state[velocity: 0]
    /// state[velocity: 1] = SIMD2(0, 0)  // Stop node movement
    /// ```
    public subscript(velocity index: Int) -> SIMD2<Float> {
        get { SIMD2(vx[index], vy[index]) }
        set { vx[index] = newValue.x; vy[index] = newValue.y }
    }
}
