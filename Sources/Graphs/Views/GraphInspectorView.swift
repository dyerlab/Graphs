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

import SwiftUI

/// An inspector panel for adjusting graph display and simulation settings.
///
/// `GraphInspectorView` provides a form-based interface for modifying
/// ``GraphDisplaySettings``. It's typically shown as a sidebar or sheet
/// alongside a ``GraphView``.
///
/// ## Overview
///
/// The inspector is organized into sections:
/// - **Display**: Visual settings like node size, labels, and colors
/// - **Physics**: Simulation parameters like repulsion and centering
/// - **Reset**: Buttons to restore default values
///
/// ## Usage
///
/// The inspector is automatically integrated into ``GraphView`` and can be
/// shown via the toolbar button. You can also use it standalone:
///
/// ```swift
/// struct MyView: View {
///     @State private var settings = GraphDisplaySettings()
///
///     var body: some View {
///         HStack {
///             GraphInspectorView(settings: settings) {
///                 // Apply settings to simulation
///                 simulation.config.manyBodyStrength = settings.repulsionStrength
///                 simulation.reheat()
///             }
///             // Your graph view
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Inspectors
/// - ``init(settings:onApplySimulationChanges:)``
public struct GraphInspectorView: View {

    /// The settings to display and modify.
    @Bindable var settings: GraphDisplaySettings

    /// Optional callback invoked when physics settings change.
    ///
    /// Use this to apply changes to the simulation, such as updating
    /// ``SimulationConfig`` values and reheating.
    var onApplySimulationChanges: (() -> Void)?

    /// Creates a new inspector view.
    ///
    /// - Parameters:
    ///   - settings: The settings to display and modify.
    ///   - onApplySimulationChanges: Optional callback invoked when physics
    ///     settings change. Use this to apply changes to the simulation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// GraphInspectorView(settings: settings) {
    ///     simulation.config.manyBodyStrength = settings.repulsionStrength
    ///     simulation.reheat(to: 0.5)
    /// }
    /// ```
    public init(settings: GraphDisplaySettings, onApplySimulationChanges: (() -> Void)? = nil) {
        self.settings = settings
        self.onApplySimulationChanges = onApplySimulationChanges
    }

    public var body: some View {
        Form {
            // MARK: - Display Section
            Section("Display") {
                Toggle("Show Labels", isOn: $settings.showLabels)

                HStack {
                    Text("Node Size")
                    Spacer()
                    Text(String(format: "%.1fx", settings.nodeScaleFactor))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.nodeScaleFactor, in: 0.2...3.0, step: 0.1)

                HStack {
                    Text("Label Size")
                    Spacer()
                    Text(String(format: "%.1fx", settings.fontScaleFactor))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.fontScaleFactor, in: 0.5...2.0, step: 0.1)

                HStack {
                    Text("Edge Width")
                    Spacer()
                    Text(String(format: "%.1fx", settings.edgeScaleFactor))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.edgeScaleFactor, in: 0.2...3.0, step: 0.1)

                ColorPicker("Node Color Override", selection: nodeColorBinding, supportsOpacity: false)

                if settings.nodeColorOverride != nil {
                    Button("Clear Color Override") {
                        settings.nodeColorOverride = nil
                    }
                    .foregroundStyle(.secondary)
                }
            }

            // MARK: - Physics Section
            Section("Physics") {
                HStack {
                    Text("Repulsion")
                    Spacer()
                    Text(String(format: "%.0f", settings.repulsionStrength))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.repulsionStrength, in: -100...0, step: 5)
                    .onChange(of: settings.repulsionStrength) { _, _ in
                        onApplySimulationChanges?()
                    }

                HStack {
                    Text("Link Strength")
                    Spacer()
                    Text(String(format: "%.1f", settings.linkStrength))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.linkStrength, in: 0.1...2.0, step: 0.1)
                    .onChange(of: settings.linkStrength) { _, _ in
                        onApplySimulationChanges?()
                    }

                HStack {
                    Text("Center Pull")
                    Spacer()
                    Text(String(format: "%.2f", settings.centerStrength))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.centerStrength, in: 0...0.5, step: 0.05)
                    .onChange(of: settings.centerStrength) { _, _ in
                        onApplySimulationChanges?()
                    }

                HStack {
                    Text("Component Separation")
                    Spacer()
                    Text(String(format: "%.1f", settings.componentSeparationStrength))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.componentSeparationStrength, in: 0...5.0, step: 0.5)
                    .onChange(of: settings.componentSeparationStrength) { _, _ in
                        onApplySimulationChanges?()
                    }
            }

            // MARK: - Reset Section
            Section {
                Button("Reset Display") {
                    settings.resetDisplay()
                }

                Button("Reset Physics") {
                    settings.resetSimulation()
                    onApplySimulationChanges?()
                }

                Button("Reset View") {
                    settings.resetView()
                }

                Button("Reset All", role: .destructive) {
                    settings.resetAll()
                    onApplySimulationChanges?()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var nodeColorBinding: Binding<Color> {
        Binding(
            get: { settings.nodeColorOverride ?? .blue },
            set: { settings.nodeColorOverride = $0 }
        )
    }
}

#Preview("Inspector") {
    GraphInspectorView(settings: GraphDisplaySettings())
        .frame(width: 300)
}
