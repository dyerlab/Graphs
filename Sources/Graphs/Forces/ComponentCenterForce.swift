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
import simd

// MARK: - Component Finding

/// Returns the connected components of the graph as arrays of node indices.
///
/// Uses breadth-first search on the undirected adjacency list implied by `edges`.
/// Isolated nodes (no edges) each form their own single-node component.
///
/// - Complexity: O(N + E)
private func findComponents(edges: [Edge], nodeCount: Int) -> [[Int]] {
    guard nodeCount > 0 else { return [] }

    // Build undirected adjacency list
    var adj = Array(repeating: [Int](), count: nodeCount)
    for edge in edges {
        let s = edge.source, t = edge.target
        guard s >= 0, t >= 0, s < nodeCount, t < nodeCount else { continue }
        adj[s].append(t)
        adj[t].append(s)
    }

    var visited = Array(repeating: false, count: nodeCount)
    var components: [[Int]] = []

    for start in 0..<nodeCount {
        guard !visited[start] else { continue }
        var component: [Int] = []
        var queue = [start]
        visited[start] = true
        while !queue.isEmpty {
            let node = queue.removeFirst()
            component.append(node)
            for neighbor in adj[node] where !visited[neighbor] {
                visited[neighbor] = true
                queue.append(neighbor)
            }
        }
        components.append(component)
    }
    return components
}

// MARK: - Force

/// Applies per-component centering and inter-component separation forces.
///
/// For graphs with a single connected component, this behaves identically to
/// ``applyCenterForce(to:center:strength:)``. For graphs with multiple disconnected
/// components, it applies two additional behaviors:
///
/// 1. **Per-component centering** — each component's centroid is individually
///    attracted toward the global centroid of all nodes. This prevents isolated
///    components from drifting off screen while the main cluster remains centered.
///
/// 2. **Inter-component separation** — an inverse-square repulsion force acts
///    between component centroids, scaled by the combined bounding radii of the
///    two components. This keeps components from collapsing onto each other even
///    as the centering force pulls them together.
///
/// ## Tuning
///
/// - Increase `centerStrength` to keep components closer to center (tighter grouping).
/// - Increase `separationStrength` to push components further apart from each other.
/// - The equilibrium spacing between components is determined by the balance of
///   these two forces and the many-body repulsion within each component.
///
/// ## Complexity
///
/// O(N + E + C²) per tick, where C is the number of connected components.
/// For sparse graphs with few components, this is effectively O(N + E).
///
/// - Parameters:
///   - state: The simulation state to modify. Velocities are updated in place.
///   - centerStrength: How strongly each component is pulled toward the global
///     centroid. Defaults to 0.1.
///   - separationStrength: The magnitude of the repulsion between component
///     centroids. Defaults to 1.0.
public func applyComponentCenterForce(
    to state: inout SimulationState,
    centerStrength: Float = 0.1,
    separationStrength: Float = 1.0
) {
    let n = state.nodeCount
    guard n > 0 else { return }

    let components = findComponents(edges: state.edges, nodeCount: n)

    // Single component — use the simpler global center force
    if components.count <= 1 {
        applyCenterForce(to: &state, strength: centerStrength)
        return
    }

    // Compute per-component centroids and bounding radii
    var centroids = [SIMD2<Float>](repeating: .zero, count: components.count)
    var radii = [Float](repeating: 0, count: components.count)

    for (ci, component) in components.enumerated() {
        var cx: Float = 0, cy: Float = 0
        for i in component {
            cx += state.x[i]
            cy += state.y[i]
        }
        let count = Float(component.count)
        cx /= count
        cy /= count
        centroids[ci] = SIMD2<Float>(cx, cy)

        var maxR: Float = 0
        for i in component {
            let dx = state.x[i] - cx
            let dy = state.y[i] - cy
            maxR = max(maxR, sqrt(dx * dx + dy * dy))
        }
        radii[ci] = max(maxR, 5.0)
    }

    // Global centroid (mean of all node positions, not mean of component centroids,
    // so large components carry more weight)
    var globalX: Float = 0, globalY: Float = 0
    for i in 0..<n {
        globalX += state.x[i]
        globalY += state.y[i]
    }
    globalX /= Float(n)
    globalY /= Float(n)

    // Pull each component toward the global centroid
    for (ci, component) in components.enumerated() {
        let dvx = (centroids[ci].x - globalX) * centerStrength * state.alpha
        let dvy = (centroids[ci].y - globalY) * centerStrength * state.alpha
        for i in component {
            state.vx[i] -= dvx
            state.vy[i] -= dvy
        }
    }

    // Inter-component separation: inverse-square repulsion between component centroids,
    // scaled by the sum of their bounding radii so that larger components repel at
    // greater distances.
    let nc = components.count
    for a in 0..<nc {
        for b in (a + 1)..<nc {
            let ca = centroids[a]
            let cb = centroids[b]
            var dx = cb.x - ca.x
            var dy = cb.y - ca.y
            var dist = sqrt(dx * dx + dy * dy)

            // Break symmetry for coincident centroids
            if dist < GraphConstants.minDistance {
                dx = (Float.random(in: 0..<1) - 0.5) * GraphConstants.jiggleMagnitude
                dy = (Float.random(in: 0..<1) - 0.5) * GraphConstants.jiggleMagnitude
                dist = sqrt(dx * dx + dy * dy)
            }

            // Combined bounding radius determines the "personal space" for each pair
            let minDist = radii[a] + radii[b]
            let force = separationStrength * state.alpha * minDist * minDist / (dist * dist)
            let fx = (dx / dist) * force
            let fy = (dy / dist) * force

            // Distribute the force equally across all nodes in each component
            let sizeA = Float(components[a].count)
            let sizeB = Float(components[b].count)
            for i in components[a] {
                state.vx[i] -= fx / sizeA
                state.vy[i] -= fy / sizeA
            }
            for i in components[b] {
                state.vx[i] += fx / sizeB
                state.vy[i] += fy / sizeB
            }
        }
    }
}
