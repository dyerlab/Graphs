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

/// Applies spring forces along edges to pull connected nodes together.
///
/// Each edge acts as a spring with a rest length (``Edge/distance``) and strength
/// (``Edge/weight``). Nodes closer than the rest length are pushed apart; nodes
/// farther than the rest length are pulled together.
///
/// ## Overview
///
/// The edge force is essential for creating structure in the graph. Without it,
/// the many-body repulsion would push all nodes apart indefinitely. The edge
/// springs counteract this repulsion for connected nodes.
///
/// ## Physics Model
///
/// The force uses Hooke's law (F = -kx) where:
/// - k is the spring constant (``Edge/weight``)
/// - x is the displacement from rest length (current distance - ``Edge/distance``)
///
/// The force is scaled by the simulation's alpha value.
///
/// ## Complexity
///
/// O(E) where E is the number of edges.
///
/// - Parameter state: The simulation state to modify. Velocities are updated in place.
///
/// ## Example
///
/// ```swift
/// applyEdgeForce(to: &state)
/// ```
public func applyEdgeForce(to state: inout SimulationState) {
    for edge in state.edges {
        let i = edge.source
        let j = edge.target

        var dx = state.x[j] - state.x[i]
        var dy = state.y[j] - state.y[i]
        var dist = sqrt(dx * dx + dy * dy)

        if dist < GraphConstants.minDistance { dist = GraphConstants.minDistance }

        let displacement = (dist - edge.distance) / dist * edge.weight * state.alpha
        dx *= displacement
        dy *= displacement

        // Apply half to each endpoint
        state.vx[j] -= dx * GraphConstants.forceDistributionFactor
        state.vy[j] -= dy * GraphConstants.forceDistributionFactor
        state.vx[i] += dx * GraphConstants.forceDistributionFactor
        state.vy[i] += dy * GraphConstants.forceDistributionFactor
    }
}
