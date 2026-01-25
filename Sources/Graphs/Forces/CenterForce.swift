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

/// Applies a centering force that pulls the graph's centroid toward a target point.
///
/// This force prevents the graph from drifting away from the visible area by
/// gently nudging all nodes so their centroid moves toward the center.
///
/// ## Overview
///
/// The center force computes the centroid (average position) of all nodes and
/// applies a velocity adjustment to move that centroid toward the target center.
/// This keeps the graph roughly centered in the view.
///
/// ## Behavior
///
/// Unlike other forces that operate on individual nodes, the center force operates
/// on the graph as a whole. It doesn't change the relative positions of nodes;
/// it only translates the entire graph.
///
/// ## Complexity
///
/// O(N) where N is the number of nodes.
///
/// - Parameters:
///   - state: The simulation state to modify. Velocities are updated in place.
///   - center: The target center point. Defaults to the origin (0, 0).
///   - strength: How strongly to pull toward the center. Higher values cause
///     faster centering but may cause oscillation. Defaults to 0.1.
///
/// ## Example
///
/// ```swift
/// // Center at origin with default strength
/// applyCenterForce(to: &state)
///
/// // Center at a specific point
/// applyCenterForce(to: &state, center: SIMD2(100, 100))
///
/// // Stronger centering
/// applyCenterForce(to: &state, strength: 0.3)
/// ```
public func applyCenterForce(
    to state: inout SimulationState,
    center: SIMD2<Float> = .zero,
    strength: Float = 0.1
) {
    let n = state.nodeCount
    guard n > 0 else { return }

    // Compute centroid
    var cx: Float = 0
    var cy: Float = 0
    for i in 0..<n {
        cx += state.x[i]
        cy += state.y[i]
    }
    cx = (cx / Float(n) - center.x) * strength * state.alpha
    cy = (cy / Float(n) - center.y) * strength * state.alpha

    // Shift all nodes
    for i in 0..<n {
        state.vx[i] -= cx
        state.vy[i] -= cy
    }
}
