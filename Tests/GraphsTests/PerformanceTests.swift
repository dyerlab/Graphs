import Testing
import Foundation
@testable import Graphs

@Test @MainActor func performanceVCUGraph() async throws {
    let pgraphData = try loadBundledPGraph(named: "vcu")
    let graphNodes = pgraphData.graphNodes()
    let edges = pgraphData.graphEdges()

    let simulation = GraphSimulation()
    simulation.setNodes(graphNodes.map(\.id))
    simulation.setLinks(edges)
    simulation.start()

    // Warm up
    for _ in 0..<10 {
        simulation.tick()
    }

    // Reset alpha for consistent measurement
    simulation.reheat(to: 1.0)

    // Measure time for 100 ticks
    let tickCount = 100
    let start = CFAbsoluteTimeGetCurrent()

    for _ in 0..<tickCount {
        simulation.tick()
    }

    let elapsed = CFAbsoluteTimeGetCurrent() - start
    let perTick = elapsed / Double(tickCount) * 1_000_000 // microseconds

    print("VCU Graph Performance (44 nodes, 78 edges):")
    print("  Total time for \(tickCount) ticks: \(String(format: "%.2f", elapsed * 1000)) ms")
    print("  Per tick: \(String(format: "%.1f", perTick)) µs")

    // Sanity check: should be well under 1ms per tick for 44 nodes
    #expect(perTick < 1000, "Expected < 1ms per tick, got \(perTick) µs")
}

@Test @MainActor func performanceScaling() async throws {
    // Test with synthetic graphs of various sizes
    let sizes = [50, 100, 200, 500]

    print("\nPerformance Scaling Test:")
    print("Nodes\tEdges\tµs/tick")

    for nodeCount in sizes {
        // Create a synthetic graph with ~2 edges per node on average
        let edgeCount = nodeCount * 2
        let ids = (0..<nodeCount).map { "node_\($0)" }

        var edges: [(source: String, target: String, distance: Float)] = []
        for _ in 0..<edgeCount {
            let i = Int.random(in: 0..<nodeCount)
            var j = Int.random(in: 0..<nodeCount)
            while j == i { j = Int.random(in: 0..<nodeCount) }
            edges.append((ids[i], ids[j], Float.random(in: 10...50)))
        }

        let simulation = GraphSimulation()
        simulation.setNodes(ids)
        simulation.setLinks(edges)
        simulation.start()

        // Warm up
        for _ in 0..<5 {
            simulation.tick()
        }
        simulation.reheat(to: 1.0)

        // Measure
        let tickCount = 50
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<tickCount {
            simulation.tick()
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perTick = elapsed / Double(tickCount) * 1_000_000

        print("\(nodeCount)\t\(edgeCount)\t\(String(format: "%.0f", perTick))")

        // At 500 nodes in release mode, should be under 2ms
        // Debug mode is much slower, so we use a higher threshold
        #if DEBUG
        let threshold: Double = 50_000 // 50ms for debug
        #else
        let threshold: Double = 2_000 // 2ms for release
        #endif

        if nodeCount == 500 {
            #expect(perTick < threshold, "Expected < \(threshold/1000)ms per tick at 500 nodes, got \(perTick/1000)ms")
        }
    }
}
