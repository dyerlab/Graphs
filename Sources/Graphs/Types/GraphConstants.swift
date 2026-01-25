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

/// Centralized constants for the graph simulation library.
///
/// `GraphConstants` provides named constants used throughout the library.
/// These values control numerical thresholds, default behaviors, and
/// rendering parameters.
///
/// ## Overview
///
/// Constants are organized into groups:
/// - **Distance Thresholds**: Prevent division by zero in force calculations
/// - **Alpha Values**: Control simulation energy levels
/// - **Position Initialization**: Default values for node placement
/// - **Force Distribution**: How forces are split between nodes
/// - **View Constants**: Rendering parameters
///
/// ## Topics
///
/// ### Distance Thresholds
/// - ``minDistanceSquared``
/// - ``minDistance``
/// - ``jiggleMagnitude``
///
/// ### Alpha (Simulation Energy)
/// - ``reheatAlphaThreshold``
/// - ``reheatAlphaValue``
/// - ``moderateReheatAlpha``
///
/// ### Position Initialization
/// - ``initialPositionRadius``
///
/// ### Force Distribution
/// - ``forceDistributionFactor``
///
/// ### View Constants
/// - ``targetFrameRate``
/// - ``frameInterval``
/// - ``defaultNodeFindThreshold``
/// - ``defaultEdgeDistance``
/// - ``baseLabelFontSize``
/// - ``labelOffset``
public enum GraphConstants {

    // MARK: - Distance Thresholds

    /// Minimum squared distance to detect coincident nodes.
    ///
    /// When two nodes are closer than this threshold, a small random offset
    /// is applied to prevent division by zero in force calculations.
    ///
    /// The value is 1e-6.
    public static let minDistanceSquared: Float = 1e-6

    /// Minimum distance for force calculations.
    ///
    /// Used as a floor value to prevent extremely large forces when
    /// nodes are very close together.
    ///
    /// The value is 1e-6.
    public static let minDistance: Float = 1e-6

    /// Magnitude of random offset applied to coincident nodes.
    ///
    /// When two nodes occupy the same position, this small random offset
    /// breaks the symmetry and allows forces to separate them.
    ///
    /// The value is 1e-3.
    public static let jiggleMagnitude: Float = 1e-3

    // MARK: - Alpha (Simulation Energy)

    /// Alpha threshold below which the simulation should reheat on start.
    ///
    /// If the simulation's alpha is below this value when ``GraphSimulation/start()``
    /// is called, it will be reheated to ``reheatAlphaValue``.
    ///
    /// The value is 0.1.
    public static let reheatAlphaThreshold: Float = 0.1

    /// Default alpha value when reheating the simulation.
    ///
    /// This provides a moderate amount of energy, enough to settle
    /// local changes without completely randomizing the layout.
    ///
    /// The value is 0.3.
    public static let reheatAlphaValue: Float = 0.3

    /// Alpha value for moderate reheat operations.
    ///
    /// Used when applying settings changes that need the simulation
    /// to readjust without a full restart.
    ///
    /// The value is 0.5.
    public static let moderateReheatAlpha: Float = 0.5

    // MARK: - Position Initialization

    /// Default radius for random position initialization.
    ///
    /// When nodes are first added to the simulation, their positions
    /// are randomized within a circle of this radius.
    ///
    /// The value is 100.
    public static let initialPositionRadius: Float = 100

    // MARK: - Force Distribution

    /// Factor for distributing forces between two interacting nodes.
    ///
    /// When a force is calculated between two nodes, each node receives
    /// this fraction of the total force (0.5 = equal distribution).
    ///
    /// The value is 0.5.
    public static let forceDistributionFactor: Float = 0.5

    // MARK: - View Constants

    /// Target frame rate for animation in frames per second.
    ///
    /// The value is 60.0.
    public static let targetFrameRate: Double = 60.0

    /// Frame interval derived from the target frame rate.
    ///
    /// This is the time between frames in seconds (1/60 ≈ 0.0167).
    public static let frameInterval: Double = 1.0 / targetFrameRate

    /// Default threshold distance for finding nodes near a point.
    ///
    /// When detecting which node is under the cursor for dragging,
    /// this is the maximum distance to consider a node as "hit".
    ///
    /// The value is 20.
    public static let defaultNodeFindThreshold: Float = 20

    /// Default distance for edges when not specified.
    ///
    /// The value is 30.0.
    public static let defaultEdgeDistance: Float = 30.0

    /// Base font size for node labels in points.
    ///
    /// This is multiplied by ``GraphDisplaySettings/fontScaleFactor``
    /// when rendering labels.
    ///
    /// The value is 10.
    public static let baseLabelFontSize: CGFloat = 10

    /// Offset from node edge for label positioning in points.
    ///
    /// Labels are positioned this many points away from the node's edge.
    ///
    /// The value is 2.
    public static let labelOffset: CGFloat = 2
}
