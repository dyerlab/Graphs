import Foundation

/// Prevents node overlap via velocity adjustment.
/// O(N^2) collision detection between all node pairs.
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
