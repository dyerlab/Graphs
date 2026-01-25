import simd

/// Simulation state using Structure-of-Arrays layout for cache efficiency.
/// This is a value type that can be copied for undo/snapshots.
public struct SimulationState: Sendable, Equatable {
    // Positions (separate arrays for SIMD-friendly operations)
    public var x: [Float]
    public var y: [Float]

    // Velocities
    public var vx: [Float]
    public var vy: [Float]

    // Fixed positions (nil = free to move)
    public var fixedX: [Float?]
    public var fixedY: [Float?]

    // Graph structure
    public var edges: [Edge]

    // Simulation activity level
    public var alpha: Float

    public var nodeCount: Int { x.count }

    public init(nodeCount: Int) {
        x = [Float](repeating: 0, count: nodeCount)
        y = [Float](repeating: 0, count: nodeCount)
        vx = [Float](repeating: 0, count: nodeCount)
        vy = [Float](repeating: 0, count: nodeCount)
        fixedX = [Float?](repeating: nil, count: nodeCount)
        fixedY = [Float?](repeating: nil, count: nodeCount)
        edges = []
        alpha = 1.0
    }

    /// Access position as SIMD2 for convenience
    public subscript(position index: Int) -> SIMD2<Float> {
        get { SIMD2(x[index], y[index]) }
        set { x[index] = newValue.x; y[index] = newValue.y }
    }

    /// Access velocity as SIMD2 for convenience
    public subscript(velocity index: Int) -> SIMD2<Float> {
        get { SIMD2(vx[index], vy[index]) }
        set { vx[index] = newValue.x; vy[index] = newValue.y }
    }
}
