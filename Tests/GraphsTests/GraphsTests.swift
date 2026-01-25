import Testing
@testable import Graphs

@Test func simulationStateInitialization() async throws {
    let state = SimulationState(nodeCount: 5)

    #expect(state.nodeCount == 5)
    #expect(state.x.count == 5)
    #expect(state.y.count == 5)
    #expect(state.vx.count == 5)
    #expect(state.vy.count == 5)
    #expect(state.edges.isEmpty)
    #expect(state.alpha == 1.0)
}

@Test func simulationStatePositionSubscript() async throws {
    var state = SimulationState(nodeCount: 3)

    state[position: 0] = SIMD2(10, 20)
    state[position: 1] = SIMD2(-5, 15)

    #expect(state.x[0] == 10)
    #expect(state.y[0] == 20)
    #expect(state[position: 1].x == -5)
    #expect(state[position: 1].y == 15)
}

@Test func edgeInitialization() async throws {
    let edge = Edge(source: 0, target: 1, strength: 0.5, distance: 50.0)

    #expect(edge.source == 0)
    #expect(edge.target == 1)
    #expect(edge.strength == 0.5)
    #expect(edge.distance == 50.0)
}

@Test func edgeDefaultValues() async throws {
    let edge = Edge(source: 2, target: 3)

    #expect(edge.strength == 1.0)
    #expect(edge.distance == 30.0)
}

@Test func manyBodyForceRepulsion() async throws {
    var state = SimulationState(nodeCount: 2)
    state[position: 0] = SIMD2(0, 0)
    state[position: 1] = SIMD2(10, 0)
    state.alpha = 1.0

    applyManyBodyForce(to: &state, strength: -30.0)

    // With negative strength, nodes should repel
    // Node 0 should get negative vx (pushed left)
    // Node 1 should get positive vx (pushed right)
    #expect(state.vx[0] < 0)
    #expect(state.vx[1] > 0)
}

@Test func edgeForceAttraction() async throws {
    var state = SimulationState(nodeCount: 2)
    state[position: 0] = SIMD2(0, 0)
    state[position: 1] = SIMD2(100, 0) // Far apart
    state.alpha = 1.0
    state.edges = [Edge(source: 0, target: 1, distance: 30.0)]

    applyEdgeForce(to: &state)

    // Nodes should be pulled together
    // Node 0 should get positive vx (pulled right toward node 1)
    // Node 1 should get negative vx (pulled left toward node 0)
    #expect(state.vx[0] > 0)
    #expect(state.vx[1] < 0)
}

@Test func centerForceMovesTowardCenter() async throws {
    var state = SimulationState(nodeCount: 2)
    state[position: 0] = SIMD2(100, 100)
    state[position: 1] = SIMD2(100, 100)
    state.alpha = 1.0

    applyCenterForce(to: &state, center: .zero, strength: 1.0)

    // Both nodes at (100, 100), centroid is (100, 100)
    // Should get negative velocity to move toward (0, 0)
    #expect(state.vx[0] < 0)
    #expect(state.vy[0] < 0)
}

@Test func collideForcePreventOverlap() async throws {
    var state = SimulationState(nodeCount: 2)
    state[position: 0] = SIMD2(0, 0)
    state[position: 1] = SIMD2(5, 0) // Very close, within collision radius
    state.alpha = 1.0

    applyCollideForce(to: &state, radius: 10.0, strength: 1.0)

    // Nodes should be pushed apart
    #expect(state.vx[0] < 0) // Pushed left
    #expect(state.vx[1] > 0) // Pushed right
}

@Test @MainActor func graphSimulationNodeManagement() async throws {
    let simulation = GraphSimulation()

    simulation.setNodes(["a", "b", "c"])

    #expect(simulation.state.nodeCount == 3)
    #expect(simulation.index(of: "a") == 0)
    #expect(simulation.index(of: "b") == 1)
    #expect(simulation.index(of: "c") == 2)
    #expect(simulation.index(of: "d") == nil)
}

@Test @MainActor func graphSimulationEdgeManagement() async throws {
    let simulation = GraphSimulation()

    simulation.setNodes(["a", "b", "c"])
    simulation.setEdges([
        (source: "a", target: "b", distance: Float(50.0)),
        (source: "b", target: "c", distance: Float(30.0))
    ])

    #expect(simulation.state.edges.count == 2)
    #expect(simulation.state.edges[0].source == 0)
    #expect(simulation.state.edges[0].target == 1)
    #expect(simulation.state.edges[0].distance == 50.0)
}

@Test @MainActor func graphSimulationPinUnpin() async throws {
    let simulation = GraphSimulation()
    simulation.setNodes(["a", "b"])

    simulation.pin(nodeAt: 0, to: SIMD2(100, 200))

    #expect(simulation.state.fixedX[0] == 100)
    #expect(simulation.state.fixedY[0] == 200)
    #expect(simulation.state.x[0] == 100)
    #expect(simulation.state.y[0] == 200)

    simulation.unpin(nodeAt: 0)

    #expect(simulation.state.fixedX[0] == nil)
    #expect(simulation.state.fixedY[0] == nil)
}

@Test @MainActor func graphSimulationAlphaDecays() async throws {
    let simulation = GraphSimulation()
    simulation.setNodes(["a", "b", "c"])
    simulation.setEdges([(source: "a", target: "b")])

    let initialAlpha = simulation.state.alpha
    simulation.start()

    // Run a few ticks
    for _ in 0..<10 {
        simulation.tick()
    }

    #expect(simulation.state.alpha < initialAlpha)
}
