import SwiftUI
import simd

/// A SwiftUI view that renders a force-directed graph.
public struct GraphView<ID: Hashable & Sendable>: View {
    @Bindable var simulation: GraphSimulation
    @State private var isInitialized = false

    // Display settings (observable)
    @State private var settings = GraphDisplaySettings()
    @State private var showInspector = false

    // Pan and zoom state (transient, not in settings)
    @State private var currentPan: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0

    // Node dragging state
    @State private var draggedNodeIndex: Int? = nil
    @State private var canvasSize: CGSize = .zero

    let nodes: [Node<ID>]
    let edges: [(source: ID, target: ID, distance: Float)]

    public init(
        simulation: GraphSimulation,
        nodes: [Node<ID>],
        edges: [(source: ID, target: ID, distance: Float)]
    ) {
        self.simulation = simulation
        self.nodes = nodes
        self.edges = edges
    }

    /// Convenience initializer with default edge distances.
    public init(
        simulation: GraphSimulation,
        nodes: [Node<ID>],
        edges: [(source: ID, target: ID)],
        defaultDistance: Float = 30.0
    ) {
        self.simulation = simulation
        self.nodes = nodes
        self.edges = edges.map { ($0.source, $0.target, defaultDistance) }
    }

    // MARK: - Coordinate Conversion

    /// Convert screen coordinates to simulation coordinates (accounting for pan/zoom)
    private func screenToSimulation(_ point: CGPoint, in size: CGSize) -> SIMD2<Float> {
        let totalScale = settings.scale * currentScale
        let totalPan = CGSize(
            width: settings.panOffset.width + currentPan.width,
            height: settings.panOffset.height + currentPan.height
        )

        // Reverse the transforms: remove pan, then scale, relative to center
        let x = (point.x - size.width / 2) / totalScale + size.width / 2 - totalPan.width
        let y = (point.y - size.height / 2) / totalScale + size.height / 2 - totalPan.height

        // Convert from canvas coords (centered at size/2) to simulation coords (centered at 0)
        return SIMD2<Float>(Float(x) - Float(size.width / 2), Float(y) - Float(size.height / 2))
    }

    /// Find the node index nearest to a simulation position, within a threshold
    private func findNode(near simPos: SIMD2<Float>, threshold: Float = 20) -> Int? {
        var closestIndex: Int? = nil
        var closestDist: Float = threshold

        for node in nodes {
            guard let idx = simulation.index(of: node.id),
                  idx < simulation.state.nodeCount else { continue }

            let nodePos = simulation.state[position: idx]
            let dist = simd_distance(nodePos, simPos)

            // Use the node's radius as part of the hit detection
            let hitRadius = max(Float(node.size / 2), threshold)
            if dist < hitRadius && dist < closestDist {
                closestIndex = idx
                closestDist = dist
            }
        }
        return closestIndex
    }

    // MARK: - Simulation Updates

    private func applySimulationSettings() {
        simulation.config.manyBodyStrength = settings.repulsionStrength
        simulation.config.centerStrength = settings.centerStrength
        // Reheat to apply changes
        simulation.reheat(to: 0.5)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let simPos = screenToSimulation(value.location, in: canvasSize)

                // On first movement, determine if we're dragging a node or panning
                if value.translation == .zero || (draggedNodeIndex == nil && currentPan == .zero) {
                    if let nodeIdx = findNode(near: screenToSimulation(value.startLocation, in: canvasSize)) {
                        draggedNodeIndex = nodeIdx
                        simulation.pin(nodeAt: nodeIdx, to: simPos)
                        if !simulation.isRunning {
                            simulation.start()
                        }
                    }
                }

                if let nodeIdx = draggedNodeIndex {
                    // Dragging a node
                    simulation.pin(nodeAt: nodeIdx, to: simPos)
                } else {
                    // Panning the canvas
                    currentPan = value.translation
                }
            }
            .onEnded { value in
                if let nodeIdx = draggedNodeIndex {
                    // Release the node - unpin and let it settle
                    simulation.unpin(nodeAt: nodeIdx)
                    simulation.reheat(to: 0.3)
                    draggedNodeIndex = nil
                } else {
                    // Commit pan
                    settings.panOffset = CGSize(
                        width: settings.panOffset.width + value.translation.width,
                        height: settings.panOffset.height + value.translation.height
                    )
                    currentPan = .zero
                }
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                currentScale = value.magnification
            }
            .onEnded { value in
                settings.scale *= value.magnification
                currentScale = 1.0
            }
    }

    public var body: some View {
        VStack {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !simulation.isRunning)) { timeline in
                Canvas { context, size in
                    // Capture canvas size for gesture coordinate conversion
                    DispatchQueue.main.async {
                        if canvasSize != size {
                            canvasSize = size
                        }
                    }

                    // Trigger simulation tick
                    simulation.tick()

                    // Apply pan and zoom transforms
                    let totalScale = settings.scale * currentScale
                    let totalPan = CGSize(
                        width: settings.panOffset.width + currentPan.width,
                        height: settings.panOffset.height + currentPan.height
                    )

                    var transformedContext = context
                    // Translate to center, apply scale, translate back, then apply pan
                    transformedContext.translateBy(x: size.width / 2, y: size.height / 2)
                    transformedContext.scaleBy(x: totalScale, y: totalScale)
                    transformedContext.translateBy(x: -size.width / 2, y: -size.height / 2)
                    transformedContext.translateBy(x: totalPan.width, y: totalPan.height)

                    let center = SIMD2<Float>(Float(size.width / 2), Float(size.height / 2))

                    // Draw edges
                    for edge in simulation.state.edges {
                        let from = simulation.state[position: edge.source] + center
                        let to = simulation.state[position: edge.target] + center

                        var path = Path()
                        path.move(to: CGPoint(x: CGFloat(from.x), y: CGFloat(from.y)))
                        path.addLine(to: CGPoint(x: CGFloat(to.x), y: CGFloat(to.y)))

                        let edgeWidth = settings.edgeScaleFactor / totalScale
                        transformedContext.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: edgeWidth)
                    }

                    // Draw nodes and labels
                    for node in nodes {
                        guard let nodeIndex = simulation.index(of: node.id),
                              nodeIndex < simulation.state.nodeCount else { continue }

                        let pos = simulation.state[position: nodeIndex] + center
                        let scaledSize = node.size * settings.nodeScaleFactor
                        let radius = scaledSize / 2
                        let rect = CGRect(
                            x: CGFloat(pos.x) - radius,
                            y: CGFloat(pos.y) - radius,
                            width: scaledSize,
                            height: scaledSize
                        )

                        let nodeColor = settings.nodeColorOverride ?? node.color
                        transformedContext.fill(Circle().path(in: rect), with: .color(nodeColor))

                        // Draw label if enabled
                        if settings.showLabels {
                            let labelOffset: CGFloat = radius + 2
                            let labelPoint = CGPoint(
                                x: CGFloat(pos.x) + labelOffset,
                                y: CGFloat(pos.y) - labelOffset
                            )

                            let fontSize: CGFloat = 10 * settings.fontScaleFactor
                            let text = Text(node.label)
                                .font(.system(size: fontSize))
                                .foregroundColor(.primary)
                            transformedContext.draw(text, at: labelPoint, anchor: .bottomLeading)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .gesture(zoomGesture)
            .onAppear {
                guard !isInitialized else { return }
                isInitialized = true

                simulation.setNodes(nodes.map(\.id))
                simulation.setEdges(edges)
                simulation.start()
            }

            // Toolbar
            /*
            HStack {
                Button(action: {
                    showInspector.toggle()
                }, label: {
                    Image(systemName: "slider.horizontal.3")
                })

                Button(action: {
                    settings.showLabels.toggle()
                }, label: {
                    Image(systemName: settings.showLabels ? "text.bubble.fill" : "text.bubble")
                })

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        settings.resetView()
                    }
                }, label: {
                    Image(systemName: "arrow.counterclockwise")
                })
            }
            .buttonStyle(.borderedProminent)
             */
        }
        .padding()
        .inspector(isPresented: $showInspector) {
            GraphInspectorView(settings: settings) {
                applySimulationSettings()
            }
            .inspectorColumnWidth(min: 280, ideal: 300, max: 350)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showInspector.toggle()
                }, label: {
                    Image(systemName: "slider.horizontal.3")
                })
            }
        }
    }
}

// MARK: - Previews

#Preview("Simple Triangle") {
    let simulation = GraphSimulation()
    let nodes = [
        Node(id: "A", label: "A", size: 20, color: .red),
        Node(id: "B", label: "B", size: 20, color: .green),
        Node(id: "C", label: "C", size: 20, color: .blue)
    ]
    let edges: [(source: String, target: String, distance: Float)] = [
        ("A", "B", 50),
        ("B", "C", 50),
        ("C", "A", 50)
    ]

    return GraphView(
        simulation: simulation,
        nodes: nodes,
        edges: edges
    )
    .frame(width: 400, height: 400)
    .background(Color.black.opacity(0.05))
}

#Preview("Star Graph") {
    let simulation = GraphSimulation()
    let center = Node(id: "center", label: "Center", size: 30, color: .orange)
    let satellites = (1...6).map { i in
        Node(id: "node\(i)", label: "N\(i)", size: 15, color: .blue)
    }
    let nodes = [center] + satellites
    let edges: [(source: String, target: String, distance: Float)] = satellites.map { satellite in
        ("center", satellite.id, Float(40))
    }

    return GraphView(
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
    guard let data = try? loadBundledGraph(named: "vcu") else {
        return AnyView(Text("Failed to load vcu.pgraph"))
    }

    let nodes = data.nodes
    let edges = data.edges

    return AnyView(
        GraphView(
            simulation: simulation,
            nodes: nodes,
            edges: edges
        )
        .frame(width: 800, height: 600)
        .background(Color.black.opacity(0.05))
    )
}

