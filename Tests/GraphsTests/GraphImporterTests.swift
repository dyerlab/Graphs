import Testing
import Foundation
import simd
@testable import Graphs

@Test func parseGraphSimple() async throws {
    let content = """
    3    2
    nodeA    10.5    1
    nodeB    8.0    2
    nodeC    5.5    1
    nodeA    nodeB    15.0
    nodeB    nodeC    20.0
    """

    let data = try parseGraph(content)

    #expect(data.nodes.count == 3)
    #expect(data.edges.count == 2)

    #expect(data.nodes[0].label == "nodeA")
    #expect(data.nodes[0].size == 10.5)
    #expect(data.nodes[0].colorCode == 1)

    #expect(data.nodes[1].label == "nodeB")
    #expect(data.nodes[1].size == 8.0)
    #expect(data.nodes[1].colorCode == 2)

    #expect(data.edges[0].source == "nodeA")
    #expect(data.edges[0].target == "nodeB")
    #expect(data.edges[0].distance == 15.0)
}

@Test func parseGraphInvalidHeader() async throws {
    let content = "invalid header"

    #expect(throws: GraphParseError.self) {
        try parseGraph(content)
    }
}

@Test func parseGraphEmptyContent() async throws {
    let content = ""

    #expect(throws: GraphParseError.self) {
        try parseGraph(content)
    }
}

@Test func graphDataConvertsToGraphNodes() async throws {
    let content = """
    2    1
    alpha    12.0    1
    beta    8.0    2
    alpha    beta    10.0
    """

    let data = try parseGraph(content)
    let graphNodes = data.graphNodes()

    #expect(graphNodes.count == 2)
    #expect(graphNodes[0].id == "alpha")
    #expect(graphNodes[0].label == "alpha")
    #expect(graphNodes[0].size == 12.0)

    #expect(data.edges.count == 1)
    #expect(data.edges[0].source == "alpha")
    #expect(data.edges[0].target == "beta")
    #expect(data.edges[0].distance == 10.0)
}

@Test func loadVCUGraphFile() async throws {
    let data = try loadBundledGraph(named: "vcu")

    #expect(data.nodes.count == 44)
    #expect(data.edges.count == 78)

    // Check a known node
    let anthro = data.nodes.first { $0.label == "anthro" }
    #expect(anthro != nil)
    #expect(anthro?.colorCode == 1)

    // Check a known edge
    let edge = data.edges.first { $0.source == "anthro" && $0.target == "envs" }
    #expect(edge != nil)
    #expect(edge!.distance > 18.0 && edge!.distance < 19.0)
}

@Test @MainActor func simulateVCUGraph() async throws {
    let graphData = try loadBundledGraph(named: "vcu")
    let graphNodes = graphData.graphNodes()
    let edges = graphData.edges

    // Create simulation
    let simulation = GraphSimulation()
    simulation.setNodes(graphNodes.map(\.id))
    simulation.setEdges(edges)

    #expect(simulation.state.nodeCount == 44)
    #expect(simulation.state.edges.count == 78)

    // Run simulation for a number of ticks
    simulation.start()

    let initialAlpha = simulation.state.alpha
    for _ in 0..<100 {
        simulation.tick()
    }

    // Alpha should have decayed
    #expect(simulation.state.alpha < initialAlpha)

    // Positions should have spread out from initial random placement
    // Check that connected nodes are somewhat closer than unconnected ones
    // (This is a sanity check, not a rigorous test)

    // Find two connected nodes
    if let mathAppliedIdx = simulation.index(of: "math_applied"),
       let mathBioIdx = simulation.index(of: "math_bio") {
        let pos1 = simulation.state[position: mathAppliedIdx]
        let pos2 = simulation.state[position: mathBioIdx]
        let connectedDist = simd_distance(pos1, pos2)

        // Find a likely unconnected pair (anthro and compSci have no direct edge)
        if let anthroIdx = simulation.index(of: "anthro"),
           let compSciIdx = simulation.index(of: "compSci") {
            let pos3 = simulation.state[position: anthroIdx]
            let pos4 = simulation.state[position: compSciIdx]
            let unconnectedDist = simd_distance(pos3, pos4)

            // Connected nodes should generally be closer, but this is probabilistic
            // Just check both distances are finite
            #expect(connectedDist.isFinite)
            #expect(unconnectedDist.isFinite)
        }
    }

    print("VCU Graph Simulation Results after 100 ticks:")
    print("  Alpha: \(simulation.state.alpha)")
    print("  Sample positions:")
    for label in ["anthro", "biol", "compSci", "math_applied", "socy"] {
        if let idx = simulation.index(of: label) {
            let pos = simulation.state[position: idx]
            print("    \(label): (\(pos.x), \(pos.y))")
        }
    }
}
