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

/// Inspector panel for adjusting graph display and simulation settings.
public struct GraphInspectorView: View {
    @Bindable var settings: GraphDisplaySettings
    var onApplySimulationChanges: (() -> Void)?

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

    /// Binding that converts optional Color to non-optional for ColorPicker
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
