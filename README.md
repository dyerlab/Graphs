# Graphs Package

![](https://www.flickr.com/photo_download.gne?id=55060655654&secret=b9fc63ff3f&size=c&source=photoPageEngagement)

A minimal, Swift-native **force-directed graph library** optimized for interactive use cases with small graphs (≤500 nodes). 

Documentation is [here](https://dyerlab.github.io/Graphs/documentation/graphs/)



Unlike standard graph libraries that use object-graph connections, **Graphs** uses a high-performance simulation engine built on cache-efficient data structures, making it ideal for fluid, real-time SwiftUI applications.

## Key Features

* **Switchable Connectivity:** Manage multiple `EdgeSet` collections within a single `PopulationGraph` to represent different connectivity patterns.
* **Performance-First Architecture:** Utilizes a **Structure-of-Arrays (SoA)** layout for simulation states, ensuring CPU cache efficiency during high-frequency physics updates.
* **SwiftUI Integration:** Native `@Observable` and `@MainActor` support via `GraphSimulation` for seamless rendering in `GraphView`.
* **Integer-Based Edges:** Edges reference nodes by integer indices (source/target) for $O(1)$ lookups, avoiding the overhead of object-reference traversal.
* **Per-Component Centering:** Disconnected subgraphs each pull toward the global centroid independently, with inter-cluster repulsion to keep components from collapsing together.
* **Off-Screen Indicator:** A "Nodes off screen" badge fades in automatically when any node drifts outside the visible canvas area.
* **JSON Graph Format (JGF):** Import graphs from the standard [JSON Graph Format](https://jsongraphformat.info), including an extended form with multiple named edge sets.

## Project Structure

The package is organized into specialized modules to separate data modeling from physics calculations:

* **Models**: Core types like `Node`, `Edge`, and `PopulationGraph`.
* **Simulation**: Management of the `SimulationState` and `GraphSimulation` runner.
* **Forces**: Specialized functions for Many-Body, Edge, Center, and Collision physics.
* **Views**: SwiftUI components including `GraphView` and `GraphInspectorView`.

## Physics Engine

The library implements a classic force-directed layout using standalone force functions applied each tick in order:

1.  **Many-Body Force**: $O(N^2)$ N-body repulsion.
2.  **Edge Force**: $O(E)$ spring forces along edges.
3.  **Component Center Force**: per-component pull toward the global centroid, plus inverse-square repulsion between component centroids to prevent clusters from collapsing. Delegates to a simple center force for single-component graphs.
4.  **Collision Force**: $O(N^2)$ prevents node overlap.

Simulation energy is controlled by an alpha value (1.0 → 0.0). Call `simulation.reheat(to:)` to restart layout after graph mutations or drag interactions. The `GraphInspectorView` exposes sliders for repulsion, link strength, center pull, and component separation.

## Quick Start

```swift
import Graphs

// 1. Initialize your graph
var graph = PopulationGraph()
let nodeA = graph.addNode(label: "Alpha")
let nodeB = graph.addNode(label: "Beta")

// 2. Connect nodes within an EdgeSet
graph.connect(nodeA, to: nodeB, distance: 30.0, weight: 1.0)

// 3. Start the simulation for your SwiftUI View
@State private var simulation = GraphSimulation(graph: graph)

var body: some View {
    GraphView(simulation: simulation)
}
```


## Design Patterns & Conventions

DocC Documentation: All public APIs are fully documented for Swift DocC.

- Standalone Forces: Force calculations are implemented as standalone functions rather than methods to maintain a clean separation of concerns.
- Centralized Constants: Simulation and display defaults are managed in GraphConstants.
- File Formats: Supports the custom `.pgraph` specification via `GraphImporter` (see the [popgraph](https://github.com/dyerlab/popgraph) R library) and the standard [JSON Graph Format (JGF)](https://jsongraphformat.info) via `JGFImporter`, including an extended multi-edge-set variant.


## Updates 

To update DocC content for GitHub, run the following and push the updates

```bash
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target Graphs \        
    --output-path ./docs \
    --transform-for-static-hosting \
    --hosting-base-path Graphs  
```

