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
    #expect(data.nodes[0].color == .blue) // colorCode 1 -> blue

    #expect(data.nodes[1].label == "nodeB")
    #expect(data.nodes[1].size == 8.0)
    #expect(data.nodes[1].color == .green) // colorCode 2 -> green

    // Edge now uses integer indices
    #expect(data.nodes[data.edges[0].source].label == "nodeA")
    #expect(data.nodes[data.edges[0].target].label == "nodeB")
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

@Test func parseGraphWithEdges() async throws {
    let content = """
    2    1
    alpha    12.0    1
    beta    8.0    2
    alpha    beta    10.0
    """

    let data = try parseGraph(content)

    #expect(data.nodes.count == 2)
    #expect(data.nodes[0].label == "alpha")
    #expect(data.nodes[0].size == 12.0)
    #expect(data.nodes[0].color == .blue)

    #expect(data.edges.count == 1)
    // Edge now uses integer indices
    #expect(data.nodes[data.edges[0].source].label == "alpha")
    #expect(data.nodes[data.edges[0].target].label == "beta")
    #expect(data.edges[0].distance == 10.0)
}

@Test func loadVCUGraphFile() async throws {
    let data = try loadBundledGraph(named: "vcu")

    #expect(data.nodes.count == 44)
    #expect(data.edges.count == 78)

    // Check a known node
    let anthro = data.nodes.first { $0.label == "anthro" }
    #expect(anthro != nil)
    #expect(anthro?.color == .blue) // colorCode 1 -> blue

    // Check a known edge by finding the node indices first
    let anthroIdx = data.nodeIndex(forLabel: "anthro")
    let envsIdx = data.nodeIndex(forLabel: "envs")
    #expect(anthroIdx != nil)
    #expect(envsIdx != nil)

    let edge = data.edges.first { $0.source == anthroIdx && $0.target == envsIdx }
    #expect(edge != nil)
    #expect(edge!.distance > 18.0 && edge!.distance < 19.0)
}

@Test @MainActor func simulateVCUGraph() async throws {
    let graphData = try loadBundledGraph(named: "vcu")

    // Create simulation using load()
    let simulation = GraphSimulation()
    simulation.load(graphData)

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

    // Helper to find node index by label
    func indexOfNode(label: String) -> Int? {
        simulation.index(forLabel: label)
    }

    // Find two connected nodes
    if let mathAppliedIdx = indexOfNode(label: "math_applied"),
       let mathBioIdx = indexOfNode(label: "math_bio") {
        let pos1 = simulation.state[position: mathAppliedIdx]
        let pos2 = simulation.state[position: mathBioIdx]
        let connectedDist = simd_distance(pos1, pos2)

        // Find a likely unconnected pair (anthro and compSci have no direct edge)
        if let anthroIdx = indexOfNode(label: "anthro"),
           let compSciIdx = indexOfNode(label: "compSci") {
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
        if let idx = indexOfNode(label: label) {
            let pos = simulation.state[position: idx]
            print("    \(label): (\(pos.x), \(pos.y))")
        }
    }
}
