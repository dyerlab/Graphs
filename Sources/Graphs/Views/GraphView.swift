import SwiftUI
import simd

/// A SwiftUI view that renders a force-directed graph.
public struct GraphView: View {
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

    let graph: PopulationGraph

    public init(graph: PopulationGraph, simulation: GraphSimulation) {
        self.simulation = simulation
        self.graph = graph
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
    private func findNode(near simPos: SIMD2<Float>, threshold: Float = GraphConstants.defaultNodeFindThreshold) -> Int? {
        var closestIndex: Int? = nil
        var closestDist: Float = threshold

        for (index, node) in graph.nodes.enumerated() {
            guard index < simulation.state.nodeCount else { continue }

            let nodePos = simulation.state[position: index]
            let dist = simd_distance(nodePos, simPos)

            // Use the node's radius as part of the hit detection
            let hitRadius = max(Float(node.size / 2), threshold)
            if dist < hitRadius && dist < closestDist {
                closestIndex = index
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
        simulation.reheat(to: GraphConstants.moderateReheatAlpha)
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
                    simulation.reheat(to: GraphConstants.reheatAlphaValue)
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
            TimelineView(.animation(minimumInterval: GraphConstants.frameInterval, paused: !simulation.isRunning)) { timeline in
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
                    for (index, node) in graph.nodes.enumerated() {
                        guard index < simulation.state.nodeCount else { continue }

                        let pos = simulation.state[position: index] + center
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
                            let labelOffset: CGFloat = radius + GraphConstants.labelOffset
                            let labelPoint = CGPoint(
                                x: CGFloat(pos.x) + labelOffset,
                                y: CGFloat(pos.y) - labelOffset
                            )

                            let fontSize: CGFloat = GraphConstants.baseLabelFontSize * settings.fontScaleFactor
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

                simulation.load(graph)
                simulation.start()
            }
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
    let graph = PopulationGraph.triangleGraph

    GraphView(graph: graph, simulation: simulation)
        .frame(width: 400, height: 400)
        .background(Color.black.opacity(0.05))
}

#Preview("Star Graph") {
    let simulation = GraphSimulation()
    let graph = PopulationGraph.starGraph

    GraphView(graph: graph, simulation: simulation)
        .frame(width: 400, height: 400)
        .background(Color.black.opacity(0.05))
}

#Preview("VCU Network") {
    let simulation = GraphSimulation()

    if let graph = try? loadBundledGraph(named: "vcu") {
        GraphView(graph: graph, simulation: simulation)
            .frame(width: 800, height: 600)
            .background(Color.black.opacity(0.05))
    } else {
        Text("Failed to load VCU graph data.")
    }
}
