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
@testable import Graphs

// MARK: - Standard JGF (single edge set)

@Test func jgfParseStandardFormat() async throws {
    let json = """
    {
      "graph": {
        "label": "Test Graph",
        "nodes": {
          "n1": { "label": "Alpha", "metadata": { "size": 20, "color": "red" } },
          "n2": { "label": "Beta",  "metadata": { "size": 15, "color": "#00FF00" } },
          "n3": { "label": "Gamma" }
        },
        "edges": [
          { "source": "n1", "target": "n2", "metadata": { "weight": 40 } },
          { "source": "n2", "target": "n3" }
        ]
      }
    }
    """

    let graph = try parseJGF(json)

    #expect(graph.nodes.count == 3)
    #expect(graph.edgeSets.count == 1)
    #expect(graph.edges.count == 2)

    // Nodes are sorted alphabetically by their JSON key (n1, n2, n3).
    #expect(graph.nodes[0].label == "Alpha")
    #expect(graph.nodes[0].size == 20)
    #expect(graph.nodes[0].color == .red)

    #expect(graph.nodes[1].label == "Beta")
    #expect(graph.nodes[1].size == 15)

    // Gamma has no metadata, so defaults apply.
    #expect(graph.nodes[2].label == "Gamma")
    #expect(graph.nodes[2].size == 10)
    #expect(graph.nodes[2].color == .blue)

    // Edge set is named after the graph label.
    #expect(graph.edgeSets[0].name == "Test Graph")

    // First edge with explicit metadata.
    let e0 = graph.edges[0]
    #expect(graph.nodes[e0.source].label == "Alpha")
    #expect(graph.nodes[e0.target].label == "Beta")
    #expect(e0.distance == 40.0)
    #expect(e0.weight == 1.0)

    // Second edge uses default distance.
    let e1 = graph.edges[1]
    #expect(graph.nodes[e1.source].label == "Beta")
    #expect(graph.nodes[e1.target].label == "Gamma")
    #expect(e1.distance == 30.0)
    #expect(e1.weight == 1.0)
}

@Test func jgfNodeKeyUsedAsLabelWhenMissing() async throws {
    let json = """
    {
      "graph": {
        "nodes": {
          "population_A": {},
          "population_B": { "label": "Pop B" }
        },
        "edges": []
      }
    }
    """

    let graph = try parseJGF(json)
    #expect(graph.nodes[0].label == "population_A")
    #expect(graph.nodes[1].label == "Pop B")
}

// MARK: - Extended format (multiple edge sets)

@Test func jgfParseMultipleEdgeSets() async throws {
    let json = """
    {
      "graph": {
        "nodes": {
          "a": { "label": "A" },
          "b": { "label": "B" },
          "c": { "label": "C" }
        },
        "edgeSets": [
          {
            "name": "Generation 1",
            "metadata": { "year": "1920" },
            "edges": [
              { "source": "a", "target": "b", "metadata": { "weight": 25 } }
            ]
          },
          {
            "name": "Generation 2",
            "edges": [
              { "source": "a", "target": "b", "metadata": { "weight": 50 } },
              { "source": "b", "target": "c" }
            ]
          }
        ]
      }
    }
    """

    let graph = try parseJGF(json)

    #expect(graph.nodes.count == 3)
    #expect(graph.edgeSets.count == 2)

    #expect(graph.edgeSets[0].name == "Generation 1")
    #expect(graph.edgeSets[0].metadata["year"] == "1920")
    #expect(graph.edgeSets[0].edges.count == 1)
    #expect(graph.edgeSets[0].edges[0].distance == 25.0)

    #expect(graph.edgeSets[1].name == "Generation 2")
    #expect(graph.edgeSets[1].edges.count == 2)
    #expect(graph.edgeSets[1].edges[0].distance == 50.0)
    #expect(graph.edgeSets[1].edges[1].distance == 30.0) // default
}

@Test func jgfEdgeSetsKeyTakesPrecedenceOverEdgesKey() async throws {
    // When both "edgeSets" and "edges" are present, "edgeSets" wins.
    let json = """
    {
      "graph": {
        "nodes": {
          "a": { "label": "A" },
          "b": { "label": "B" }
        },
        "edges": [
          { "source": "a", "target": "b" }
        ],
        "edgeSets": [
          { "name": "Set 1", "edges": [] },
          { "name": "Set 2", "edges": [] }
        ]
      }
    }
    """

    let graph = try parseJGF(json)
    #expect(graph.edgeSets.count == 2)
    #expect(graph.edgeSets[0].name == "Set 1")
}

// MARK: - Multi-graph format

@Test func jgfParseMultiGraphFormat() async throws {
    let json = """
    {
      "graphs": [
        {
          "label": "First",
          "nodes": { "x": { "label": "X" } },
          "edges": []
        },
        {
          "label": "Second",
          "nodes": { "y": { "label": "Y" }, "z": { "label": "Z" } },
          "edges": []
        }
      ]
    }
    """

    // Only the first graph is parsed from the "graphs" array.
    let graph = try parseJGF(json)
    #expect(graph.nodes.count == 1)
    #expect(graph.nodes[0].label == "X")
}

// MARK: - Color parsing

@Test func jgfColorParsing() async throws {
    let json = """
    {
      "graph": {
        "nodes": {
          "a": { "metadata": { "color": "red" } },
          "b": { "metadata": { "color": "#0000FF" } },
          "c": { "metadata": { "color": "#F0F" } },
          "d": { "metadata": { "color": "unknown_color" } },
          "e": {}
        },
        "edges": []
      }
    }
    """

    let graph = try parseJGF(json)

    #expect(graph.nodes[0].color == .red)        // "a" – named color
    #expect(graph.nodes[1].color == .blue)        // "b" – 6-digit hex
    #expect(graph.nodes[2].color == .purple)      // "c" – 3-digit hex #F0F -> #FF00FF (magenta/purple)
    #expect(graph.nodes[3].color == .blue)        // "d" – unrecognized, falls back to .blue
    #expect(graph.nodes[4].color == .blue)        // "e" – no metadata, falls back to .blue
}

// MARK: - Error cases

@Test func jgfInvalidJSON() async throws {
    #expect(throws: GraphParseError.self) {
        try parseJGF("not json at all")
    }
}

@Test func jgfMissingTopLevelKey() async throws {
    #expect(throws: GraphParseError.self) {
        try parseJGF(#"{ "something": {} }"#)
    }
}

@Test func jgfEdgesWithUnknownNodeRefsAreDropped() async throws {
    // Edges referencing non-existent node keys are silently dropped.
    let json = """
    {
      "graph": {
        "nodes": { "a": { "label": "A" } },
        "edges": [
          { "source": "a", "target": "missing" }
        ]
      }
    }
    """

    let graph = try parseJGF(json)
    #expect(graph.nodes.count == 1)
    #expect(graph.edges.count == 0)
}

@Test func jgfEmptyGraph() async throws {
    let json = """
    {
      "graph": {}
    }
    """

    let graph = try parseJGF(json)
    #expect(graph.nodes.isEmpty)
    #expect(graph.edgeSets.isEmpty)
}

// MARK: - VCU bundled graph (parity with .pgraph)

@Test func loadVCUGraphJGF() async throws {
    let graph = try loadBundledJGF(named: "vcu")

    #expect(graph.nodes.count == 44)
    #expect(graph.edges.count == 78)

    // Verify a known node exists with the right properties.
    let anthro = graph.nodes.first { $0.label == "anthro" }
    #expect(anthro != nil)
    #expect(anthro?.color == .blue)

    // Verify a known edge by label-based index lookup.
    let anthroIdx = graph.nodeIndex(forLabel: "anthro")
    let envsIdx   = graph.nodeIndex(forLabel: "envs")
    #expect(anthroIdx != nil)
    #expect(envsIdx   != nil)

    let edge = graph.edges.first { $0.source == anthroIdx && $0.target == envsIdx }
    #expect(edge != nil)
    #expect(edge!.distance > 18.0 && edge!.distance < 19.0)
}

// MARK: - Data overload

@Test func jgfParseFromData() async throws {
    let json = #"{ "graph": { "nodes": { "x": { "label": "X" } }, "edges": [] } }"#
    let data = json.data(using: .utf8)!
    let graph = try parseJGF(data)
    #expect(graph.nodes.count == 1)
    #expect(graph.nodes[0].label == "X")
}
