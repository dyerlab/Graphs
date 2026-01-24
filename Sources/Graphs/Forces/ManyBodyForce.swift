import Foundation

/// Applies repulsion (negative strength) or attraction (positive) between all node pairs.
/// O(N^2) but fast for N < 500 due to simple memory access pattern.
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
            if distSq < 1e-6 {
                dx = (Float.random(in: 0..<1) - 0.5) * 1e-3
                dy = (Float.random(in: 0..<1) - 0.5) * 1e-3
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
