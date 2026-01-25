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

/// Applies a many-body force between all pairs of nodes.
///
/// This force causes nodes to repel (with negative strength) or attract (with
/// positive strength) each other. It's the primary force that spreads nodes apart
/// in a force-directed layout.
///
/// ## Overview
///
/// The force follows an inverse-square law similar to gravity or electrostatic
/// force. The magnitude scales with the simulation's alpha value, causing the
/// force to decrease as the simulation settles.
///
/// ## Complexity
///
/// O(N²) where N is the number of nodes. This implementation is optimized for
/// small graphs (< 500 nodes) with a simple memory access pattern.
///
/// ## Coincident Nodes
///
/// When two nodes occupy the same position, a small random offset ("jiggle")
/// is applied to break the symmetry and allow the nodes to separate.
///
/// - Parameters:
///   - state: The simulation state to modify. Velocities are updated in place.
///   - strength: The force strength. Negative values cause repulsion (typical),
///     positive values cause attraction. Default is set via ``SimulationConfig``.
///   - minDistance: Minimum distance for force calculations. Prevents extremely
///     large forces when nodes are very close. Defaults to 1.0.
///
/// ## Example
///
/// ```swift
/// applyManyBodyForce(to: &state, strength: -30.0)
/// ```
public func applyManyBodyForce(
    to state: inout SimulationState,
    strength: Float,
    minDistance: Float = 1.0
) {
    let n = state.nodeCount
    let minDistSq = minDistance * minDistance

    for i in 0..<n {
        let xi = state.x[i]
        let yi = state.y[i]
        var dvx: Float = 0
        var dvy: Float = 0

        for j in 0..<n where j != i {
            var dx = state.x[j] - xi
            var dy = state.y[j] - yi
            var distSq = dx * dx + dy * dy

            // Jiggle coincident nodes
            if distSq < GraphConstants.minDistanceSquared {
                dx = (Float.random(in: 0..<1) - 0.5) * GraphConstants.jiggleMagnitude
                dy = (Float.random(in: 0..<1) - 0.5) * GraphConstants.jiggleMagnitude
                distSq = dx * dx + dy * dy
            }

            // Apply minimum distance (softening)
            if distSq < minDistSq {
                distSq = sqrt(distSq * minDistSq)
            }

            let factor = strength * state.alpha / distSq
            dvx += dx * factor
            dvy += dy * factor
        }

        state.vx[i] += dvx
        state.vy[i] += dvy
    }
}
