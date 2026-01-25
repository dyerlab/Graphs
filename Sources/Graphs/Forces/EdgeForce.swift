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

        if dist < 1e-6 { dist = 1e-6 }

        let displacement = (dist - edge.distance) / dist * edge.strength * state.alpha
        dx *= displacement
        dy *= displacement

        // Apply half to each endpoint
        state.vx[j] -= dx * 0.5
        state.vy[j] -= dy * 0.5
        state.vx[i] += dx * 0.5
        state.vy[i] += dy * 0.5
    }
}
