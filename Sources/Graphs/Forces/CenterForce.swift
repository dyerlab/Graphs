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

/// Pulls nodes toward center to prevent drift.
/// Computes the centroid of all nodes and shifts velocities to move toward center.
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
