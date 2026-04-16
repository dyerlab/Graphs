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

/// Configuration parameters for the force-directed graph simulation.
///
/// `SimulationConfig` controls how the simulation behaves, including force strengths,
/// decay rates, and stopping conditions. Modify these values to tune the simulation
/// for your specific use case.
///
/// ## Overview
///
/// The configuration is divided into several groups:
/// - **Alpha parameters**: Control how the simulation gains and loses energy
/// - **Many-body force**: Controls node repulsion (or attraction)
/// - **Center force**: Pulls the graph toward the origin
/// - **Collide force**: Prevents node overlap
///
/// ## Example
///
/// ```swift
/// // Create a custom configuration
/// var config = SimulationConfig()
/// config.manyBodyStrength = -50  // Stronger repulsion
/// config.centerStrength = 0.2    // Stronger centering
///
/// let simulation = GraphSimulation(config: config)
/// ```
///
/// ## Topics
///
/// ### Creating Configurations
/// - ``init(alphaTarget:alphaDecay:alphaMin:velocityDecay:manyBodyStrength:manyBodyMinDistance:centerStrength:collideRadius:collideStrength:componentSeparationStrength:)``
/// - ``default``
///
/// ### Alpha Parameters
/// - ``alphaTarget``
/// - ``alphaDecay``
/// - ``alphaMin``
/// - ``velocityDecay``
///
/// ### Many-Body Force
/// - ``manyBodyStrength``
/// - ``manyBodyMinDistance``
///
/// ### Center Force
/// - ``centerStrength``
///
/// ### Collide Force
/// - ``collideRadius``
/// - ``collideStrength``
/// - ``componentSeparationStrength``
public struct SimulationConfig: Sendable, Equatable {

    /// The target alpha value that the simulation decays toward.
    ///
    /// Alpha represents the simulation's energy level. Setting this to a value
    /// greater than 0 keeps the simulation running indefinitely (useful for
    /// interactive applications).
    ///
    /// The default value is 0.0 (simulation eventually stops).
    public var alphaTarget: Float = 0.0

    /// The rate at which alpha decays toward the target.
    ///
    /// Higher values cause the simulation to settle faster but may result in
    /// less optimal layouts. Lower values allow more time for nodes to find
    /// good positions.
    ///
    /// The default value is 0.02.
    public var alphaDecay: Float = 0.02

    /// The minimum alpha value before the simulation stops.
    ///
    /// When alpha falls below this threshold, the simulation automatically stops.
    /// Use ``GraphSimulation/reheat(to:)`` to restart.
    ///
    /// The default value is 0.001.
    public var alphaMin: Float = 0.001

    /// The velocity decay factor applied each tick.
    ///
    /// Values closer to 1.0 preserve more momentum (smoother but slower settling).
    /// Values closer to 0.0 provide more damping (quicker settling but jerkier).
    ///
    /// The default value is 0.6.
    public var velocityDecay: Float = 0.6

    /// The strength of the many-body force.
    ///
    /// Negative values cause nodes to repel each other (typical for graph layout).
    /// Positive values cause attraction. The magnitude controls the force strength.
    ///
    /// The default value is -30.0 (moderate repulsion).
    public var manyBodyStrength: Float = -30.0

    /// The minimum distance for many-body force calculations.
    ///
    /// This softening parameter prevents extremely large forces when nodes are
    /// very close together. Larger values create "softer" repulsion.
    ///
    /// The default value is 1.0.
    public var manyBodyMinDistance: Float = 1.0

    /// The strength of the center force.
    ///
    /// This force pulls the centroid of all nodes toward the origin, preventing
    /// the graph from drifting. Higher values keep the graph more centered.
    ///
    /// The default value is 0.1.
    public var centerStrength: Float = 0.1

    /// The collision radius for the collide force.
    ///
    /// Nodes within twice this radius of each other experience a repulsive force.
    /// This prevents node overlap in the visualization.
    ///
    /// The default value is 5.0.
    public var collideRadius: Float = 5.0

    /// The strength of the collide force.
    ///
    /// Higher values cause stronger separation when nodes overlap.
    /// A value of 1.0 fully resolves overlaps; values less than 1.0
    /// allow some overlap.
    ///
    /// The default value is 0.7.
    public var collideStrength: Float = 0.7

    /// The strength of the repulsion force between disconnected components.
    ///
    /// When the graph has multiple disconnected components, this force pushes
    /// their centroids apart to prevent them from collapsing onto each other.
    /// Higher values increase the spacing between components.
    ///
    /// The default value is 1.0.
    public var componentSeparationStrength: Float = 1.0

    /// Creates a new configuration with the specified parameters.
    ///
    /// All parameters have sensible defaults for typical graph visualization.
    ///
    /// - Parameters:
    ///   - alphaTarget: Target alpha value. Defaults to 0.0.
    ///   - alphaDecay: Alpha decay rate. Defaults to 0.02.
    ///   - alphaMin: Minimum alpha before stopping. Defaults to 0.001.
    ///   - velocityDecay: Velocity damping factor. Defaults to 0.6.
    ///   - manyBodyStrength: Repulsion strength (negative) or attraction (positive). Defaults to -30.0.
    ///   - manyBodyMinDistance: Minimum distance for force calculations. Defaults to 1.0.
    ///   - centerStrength: Centering force strength. Defaults to 0.1.
    ///   - collideRadius: Collision detection radius. Defaults to 5.0.
    ///   - collideStrength: Collision response strength. Defaults to 0.7.
    ///   - componentSeparationStrength: Repulsion between disconnected components. Defaults to 1.0.
    public init(
        alphaTarget: Float = 0.0,
        alphaDecay: Float = 0.02,
        alphaMin: Float = 0.001,
        velocityDecay: Float = 0.6,
        manyBodyStrength: Float = -30.0,
        manyBodyMinDistance: Float = 1.0,
        centerStrength: Float = 0.1,
        collideRadius: Float = 5.0,
        collideStrength: Float = 0.7,
        componentSeparationStrength: Float = 1.0
    ) {
        self.alphaTarget = alphaTarget
        self.alphaDecay = alphaDecay
        self.alphaMin = alphaMin
        self.velocityDecay = velocityDecay
        self.manyBodyStrength = manyBodyStrength
        self.manyBodyMinDistance = manyBodyMinDistance
        self.centerStrength = centerStrength
        self.collideRadius = collideRadius
        self.collideStrength = collideStrength
        self.componentSeparationStrength = componentSeparationStrength
    }

    /// The default simulation configuration.
    ///
    /// Uses sensible defaults suitable for most graph visualizations:
    /// - Moderate repulsion (-30)
    /// - Gentle centering (0.1)
    /// - Collision prevention enabled
    public static let `default` = SimulationConfig()
}
