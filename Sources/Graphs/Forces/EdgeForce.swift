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

/// Applies spring forces along edges.
/// Each edge acts as a spring with a rest length (distance) and strength.
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
