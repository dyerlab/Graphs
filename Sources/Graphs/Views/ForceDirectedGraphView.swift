import SwiftUI
import simd

/// A SwiftUI view that renders a force-directed graph.
public struct ForceDirectedGraphView<ID: Hashable>: View {
    @Bindable var simulation: GraphSimulation
    @State private var isInitialized = false
    @State var showLabels: Bool = true

    // Pan and zoom state
    @State private var panOffset: CGSize = .zero
    @State private var currentPan: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var currentScale: CGFloat = 1.0

    let nodes: [GraphNode<ID>]
    let edges: [(source: ID, target: ID, distance: Float)]

    
    public init(
        simulation: GraphSimulation,
        nodes: [GraphNode<ID>],
        edges: [(source: ID, target: ID, distance: Float)]
    ) {
        self.simulation = simulation
        self.nodes = nodes
        self.edges = edges
    }

    /// Convenience initializer with default edge distances.
    public init(
        simulation: GraphSimulation,
        nodes: [GraphNode<ID>],
        edges: [(source: ID, target: ID)],
        defaultDistance: Float = 30.0
    ) {
        self.simulation = simulation
        self.nodes = nodes
        self.edges = edges.map { ($0.source, $0.target, defaultDistance) }
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentPan = value.translation
            }
            .onEnded { value in
                panOffset = CGSize(
                    width: panOffset.width + value.translation.width,
                    height: panOffset.height + value.translation.height
                )
                currentPan = .zero
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                currentScale = value.magnification
            }
            .onEnded { value in
                scale *= value.magnification
                currentScale = 1.0
            }
    }

    public var body: some View {
        VStack {
            
            
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !simulation.isRunning)) { timeline in
                Canvas { context, size in
                    // Trigger simulation tick
                    simulation.tick()

                    // Apply pan and zoom transforms
                    let totalScale = scale * currentScale
                    let totalPan = CGSize(
                        width: panOffset.width + currentPan.width,
                        height: panOffset.height + currentPan.height
                    )

                    var transformedContext = context
                    // Translate to center, apply scale, translate back, then apply pan
                    transformedContext.translateBy(x: size.width / 2, y: size.height / 2)
                    transformedContext.scaleBy(x: totalScale, y: totalScale)
                    transformedContext.translateBy(x: -size.width / 2, y: -size.height / 2)
                    transformedContext.translateBy(x: totalPan.width, y: totalPan.height)

                    let center = SIMD2<Float>(Float(size.width / 2), Float(size.height / 2))

                    // Draw links
                    for link in simulation.state.links {
                        let from = simulation.state[position: link.source] + center
                        let to = simulation.state[position: link.target] + center

                        var path = Path()
                        path.move(to: CGPoint(x: CGFloat(from.x), y: CGFloat(from.y)))
                        path.addLine(to: CGPoint(x: CGFloat(to.x), y: CGFloat(to.y)))

                        transformedContext.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1 / totalScale)
                    }

                    // Draw nodes and labels
                    for node in nodes {
                        guard let nodeIndex = simulation.index(of: node.id),
                              nodeIndex < simulation.state.nodeCount else { continue }

                        let pos = simulation.state[position: nodeIndex] + center
                        let radius = node.size / 2
                        let rect = CGRect(
                            x: CGFloat(pos.x) - radius,
                            y: CGFloat(pos.y) - radius,
                            width: node.size,
                            height: node.size
                        )
                        transformedContext.fill(Circle().path(in: rect), with: .color(node.color))

                        // Draw label if enabled
                        if showLabels {
                            let labelOffset: CGFloat = radius + 2
                            let labelPoint = CGPoint(
                                x: CGFloat(pos.x) + labelOffset,
                                y: CGFloat(pos.y) - labelOffset
                            )
                            let text = Text(node.label)
                                .font(.caption2)
                                .foregroundColor(.primary)
                            transformedContext.draw(text, at: labelPoint, anchor: .bottomLeading)
                        }
                    }
                }
            }
            .gesture(panGesture)
            .gesture(zoomGesture)
            .onAppear {
                guard !isInitialized else { return }
                isInitialized = true

                simulation.setNodes(nodes.map(\.id))
                simulation.setLinks(edges)
                simulation.start()
            }
            
            HStack {
                
                Button(action: {
                    showLabels.toggle()
                }, label: {
                    Image(systemName: "text.bubble")
                })

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        panOffset = .zero
                        scale = 1.0
                    }
                }, label: {
                    Image(systemName: "arrow.counterclockwise")
                })
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        

    }
}

// MARK: - Previews

#Preview("Simple Triangle") {
    let simulation = GraphSimulation()
    let nodes = [
        GraphNode(id: "A", label: "A", size: 20, color: .red),
        GraphNode(id: "B", label: "B", size: 20, color: .green),
        GraphNode(id: "C", label: "C", size: 20, color: .blue)
    ]
    let edges: [(source: String, target: String, distance: Float)] = [
        ("A", "B", 50),
        ("B", "C", 50),
        ("C", "A", 50)
    ]

    return ForceDirectedGraphView(
        simulation: simulation,
        nodes: nodes,
        edges: edges
    )
    .frame(width: 400, height: 400)
    .background(Color.black.opacity(0.05))
}

#Preview("Star Graph") {
    let simulation = GraphSimulation()
    let center = GraphNode(id: "center", label: "Center", size: 30, color: .orange)
    let satellites = (1...6).map { i in
        GraphNode(id: "node\(i)", label: "N\(i)", size: 15, color: .blue)
    }
    let nodes = [center] + satellites
    let edges: [(source: String, target: String, distance: Float)] = satellites.map { satellite in
        ("center", satellite.id, Float(40))
    }

    return ForceDirectedGraphView(
        simulation: simulation,
        nodes: nodes,
        edges: edges
    )
    .frame(width: 400, height: 400)
    .background(Color.black.opacity(0.05))
}

#Preview("VCU Network") {
    let simulation = GraphSimulation()

    // Load VCU graph from bundle
    guard let data = try? loadBundledPGraph(named: "vcu") else {
        return AnyView(Text("Failed to load vcu.pgraph"))
    }

    let nodes = data.graphNodes()
    let edges = data.graphEdges()

    return AnyView(
        ForceDirectedGraphView(
            simulation: simulation,
            nodes: nodes,
            edges: edges
        )
        .frame(width: 800, height: 600)
        .background(Color.black.opacity(0.05))
    )
}
