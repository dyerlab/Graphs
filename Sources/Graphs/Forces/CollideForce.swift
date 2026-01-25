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

/// Applies a collision force to prevent node overlap.
///
/// This force detects when nodes are closer than a specified radius and pushes
/// them apart. Unlike the many-body force, it only acts on very close nodes,
/// making it suitable for preventing visual overlap.
///
/// ## Overview
///
/// The collision force helps keep the visualization readable by ensuring nodes
/// don't overlap. It's particularly useful when nodes have varying sizes or
/// when the many-body repulsion alone isn't sufficient to prevent overlap.
///
/// ## Behavior
///
/// When two nodes are within twice the collision radius (i.e., their "circles"
/// overlap), a separating force is applied. The force is proportional to the
/// overlap amount.
///
/// ## Complexity
///
/// O(N²) where N is the number of nodes. For better performance with many nodes,
/// consider using a spatial data structure (not implemented in this version).
///
/// - Parameters:
///   - state: The simulation state to modify. Velocities are updated in place.
///   - radius: The collision radius for each node. Nodes within 2× this distance
///     are considered overlapping.
///   - strength: How strongly to push overlapping nodes apart. A value of 1.0
///     fully resolves overlaps; smaller values allow some overlap. Defaults to 0.7.
///
/// ## Example
///
/// ```swift
/// // Default collision detection
/// applyCollideForce(to: &state, radius: 5.0)
///
/// // Stronger collision response
/// applyCollideForce(to: &state, radius: 10.0, strength: 1.0)
/// ```
public func applyCollideForce(
    to state: inout SimulationState,
    radius: Float,
    strength: Float = 0.7
) {
    let n = state.nodeCount
    let radiusSq = radius * radius * 4 // diameter squared

    for i in 0..<n {
        for j in (i + 1)..<n {
            var dx = state.x[j] - state.x[i]
            var dy = state.y[j] - state.y[i]
            let distSq = dx * dx + dy * dy

            if distSq < radiusSq && distSq > GraphConstants.minDistanceSquared {
                let dist = sqrt(distSq)
                let overlap = (radius * 2 - dist) / dist * strength * GraphConstants.forceDistributionFactor
                dx *= overlap
                dy *= overlap

                state.vx[j] += dx
                state.vy[j] += dy
                state.vx[i] -= dx
                state.vy[i] -= dy
            }
        }
    }
}
