import Foundation

/// Applies spring forces along edges.
/// Each link acts as a spring with a rest length (distance) and strength.
public func applyLinkForce(to state: inout SimulationState) {
    for link in state.links {
        let i = link.source
        let j = link.target

        var dx = state.x[j] - state.x[i]
        var dy = state.y[j] - state.y[i]
        var dist = sqrt(dx * dx + dy * dy)

        if dist < 1e-6 { dist = 1e-6 }

        let displacement = (dist - link.distance) / dist * link.strength * state.alpha
        dx *= displacement
        dy *= displacement

        // Apply half to each endpoint
        state.vx[j] -= dx * 0.5
        state.vy[j] -= dy * 0.5
        state.vx[i] += dx * 0.5
        state.vy[i] += dy * 0.5
    }
}
