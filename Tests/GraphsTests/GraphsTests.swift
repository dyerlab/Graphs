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
    let edge = Edge(source: 0, target: 1, weight: 0.5, distance: 50.0)

    #expect(edge.source == 0)
    #expect(edge.target == 1)
    #expect(edge.weight == 0.5)
    #expect(edge.distance == 50.0)
}

@Test func edgeDefaultValues() async throws {
    let edge = Edge(source: 0, target: 1)

    #expect(edge.weight == 1.0)
    #expect(edge.distance == 30.0)
}

@Test func edgeSetInitialization() async throws {
    let edges = [
        Edge(source: 0, target: 1, distance: 50.0),
        Edge(source: 1, target: 2, distance: 30.0)
    ]
    let edgeSet = EdgeSet(name: "Test Set", edges: edges)

    #expect(edgeSet.name == "Test Set")
    #expect(edgeSet.count == 2)
    #expect(!edgeSet.isEmpty)
    #expect(edgeSet.isValid(for: 3))
    #expect(!edgeSet.isValid(for: 2)) // Edge 1->2 invalid for 2 nodes
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

    let nodeA = Node(label: "a")
    let nodeB = Node(label: "b")
    let nodeC = Node(label: "c")
    let nodeD = Node(label: "d")

    simulation.setNodes([nodeA, nodeB, nodeC])

    #expect(simulation.state.nodeCount == 3)
    #expect(simulation.index(of: nodeA) == 0)
    #expect(simulation.index(of: nodeB) == 1)
    #expect(simulation.index(of: nodeC) == 2)
    #expect(simulation.index(of: nodeD) == nil)
}

@Test @MainActor func graphSimulationEdgeManagement() async throws {
    let simulation = GraphSimulation()

    let nodeA = Node(label: "a")
    let nodeB = Node(label: "b")
    let nodeC = Node(label: "c")

    simulation.setNodes([nodeA, nodeB, nodeC])
    simulation.setEdges([
        Edge(source: 0, target: 1, distance: 50.0),
        Edge(source: 1, target: 2, distance: 30.0)
    ])

    #expect(simulation.state.edges.count == 2)
    #expect(simulation.state.edges[0].source == 0)
    #expect(simulation.state.edges[0].target == 1)
    #expect(simulation.state.edges[0].distance == 50.0)
}

@Test @MainActor func graphSimulationPinUnpin() async throws {
    let simulation = GraphSimulation()

    let nodeA = Node(label: "a")
    let nodeB = Node(label: "b")

    simulation.setNodes([nodeA, nodeB])

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

    let nodeA = Node(label: "a")
    let nodeB = Node(label: "b")
    let nodeC = Node(label: "c")

    simulation.setNodes([nodeA, nodeB, nodeC])
    simulation.setEdges([Edge(source: 0, target: 1)])

    let initialAlpha = simulation.state.alpha
    simulation.start()

    // Run a few ticks
    for _ in 0..<10 {
        simulation.tick()
    }

    #expect(simulation.state.alpha < initialAlpha)
}

@Test func populationGraphEdgeSetManagement() async throws {
    var graph = PopulationGraph()

    // Add nodes
    graph.addNode(Node(label: "A"))
    graph.addNode(Node(label: "B"))
    graph.addNode(Node(label: "C"))

    #expect(graph.nodeCount == 3)
    #expect(graph.edgeSets.isEmpty)

    // Add first edge set
    let edgeSet1 = EdgeSet(name: "Set 1", edges: [
        Edge(source: 0, target: 1, distance: 50.0)
    ])
    graph.addEdgeSet(edgeSet1)

    #expect(graph.edgeSets.count == 1)
    #expect(graph.activeEdgeSetIndex == 0)
    #expect(graph.edges.count == 1)

    // Add second edge set
    let edgeSet2 = EdgeSet(name: "Set 2", edges: [
        Edge(source: 0, target: 2, distance: 30.0),
        Edge(source: 1, target: 2, distance: 40.0)
    ])
    graph.addEdgeSet(edgeSet2)

    #expect(graph.edgeSets.count == 2)
    #expect(graph.activeEdgeSetIndex == 0) // Still on first set
    #expect(graph.edges.count == 1)

    // Switch to second set
    graph.setActiveEdgeSet(1)
    #expect(graph.activeEdgeSetIndex == 1)
    #expect(graph.edges.count == 2)

    // Test next/previous
    graph.nextEdgeSet()
    #expect(graph.activeEdgeSetIndex == 0) // Wraps around

    graph.previousEdgeSet()
    #expect(graph.activeEdgeSetIndex == 1) // Wraps around
}

@Test func staticGraphsHaveValidEdgeIndices() async throws {
    // Test that edge indices are valid for the nodes array
    let triangle = PopulationGraph.triangleGraph

    print("Triangle: \(triangle.nodes.count) nodes, \(triangle.edges.count) edges")

    for (i, edge) in triangle.edges.enumerated() {
        let validSource = edge.source >= 0 && edge.source < triangle.nodeCount
        let validTarget = edge.target >= 0 && edge.target < triangle.nodeCount
        print("Edge \(i): source=\(edge.source) valid=\(validSource), target=\(edge.target) valid=\(validTarget)")
        #expect(validSource, "Edge \(i) source should be valid index")
        #expect(validTarget, "Edge \(i) target should be valid index")
    }

    let star = PopulationGraph.starGraph
    print("\nStar: \(star.nodes.count) nodes, \(star.edges.count) edges")

    for (i, edge) in star.edges.enumerated() {
        let validSource = edge.source >= 0 && edge.source < star.nodeCount
        let validTarget = edge.target >= 0 && edge.target < star.nodeCount
        print("Edge \(i): source=\(edge.source) valid=\(validSource), target=\(edge.target) valid=\(validTarget)")
        #expect(validSource, "Edge \(i) source should be valid index")
        #expect(validTarget, "Edge \(i) target should be valid index")
    }
}

@Test @MainActor func staticGraphsWorkWithSimulation() async throws {
    let triangle = PopulationGraph.triangleGraph
    let simulation = GraphSimulation()

    simulation.load(triangle)

    print("After setup:")
    print("  nodeCount: \(simulation.state.nodeCount)")
    print("  edgeCount: \(simulation.state.edges.count)")

    // Verify we can look up each node
    for node in triangle.nodes {
        let idx = simulation.index(of: node)
        print("  Node '\(node.label)' -> index \(idx ?? -1)")
        #expect(idx != nil, "Should find index for node \(node.label)")
    }

    #expect(simulation.state.nodeCount == 3)
    #expect(simulation.state.edges.count == 3)
}

@Test @MainActor func simulationEdgeSetSwitching() async throws {
    // Create a graph with multiple edge sets
    var graph = PopulationGraph()
    graph.addNode(Node(label: "A"))
    graph.addNode(Node(label: "B"))
    graph.addNode(Node(label: "C"))

    let edgeSet1 = EdgeSet(name: "Linear", edges: [
        Edge(source: 0, target: 1),
        Edge(source: 1, target: 2)
    ])
    let edgeSet2 = EdgeSet(name: "Triangle", edges: [
        Edge(source: 0, target: 1),
        Edge(source: 1, target: 2),
        Edge(source: 2, target: 0)
    ])

    graph.addEdgeSet(edgeSet1)
    graph.addEdgeSet(edgeSet2)

    let simulation = GraphSimulation()
    simulation.load(graph)

    #expect(simulation.state.edges.count == 2) // Linear set

    // Switch to triangle set
    graph.setActiveEdgeSet(1)
    simulation.updateEdgeSet(graph.activeEdgeSet!)

    #expect(simulation.state.edges.count == 3) // Triangle set

    // Positions should be preserved (not randomized)
    // Just verify node count is still correct
    #expect(simulation.state.nodeCount == 3)
}
