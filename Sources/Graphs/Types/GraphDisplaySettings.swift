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
import Observation

/// Observable settings for graph display and simulation parameters.
@Observable
public final class GraphDisplaySettings {
    // Display settings
    public var showLabels: Bool = true
    public var nodeScaleFactor: CGFloat = 1.0
    public var fontScaleFactor: CGFloat = 1.0
    public var edgeScaleFactor: CGFloat = 1.0
    public var nodeColorOverride: Color? = nil

    // Simulation force settings
    public var repulsionStrength: Float = -30.0
    public var linkStrength: Float = 1.0
    public var centerStrength: Float = 0.1

    // Pan and zoom (for reset)
    public var panOffset: CGSize = .zero
    public var scale: CGFloat = 1.0

    public init() {}

    /// Reset display settings to defaults
    public func resetDisplay() {
        nodeScaleFactor = 1.0
        fontScaleFactor = 1.0
        edgeScaleFactor = 1.0
    }

    /// Reset simulation settings to defaults
    public func resetSimulation() {
        repulsionStrength = -30.0
        linkStrength = 1.0
        centerStrength = 0.1
    }

    /// Reset pan and zoom to defaults
    public func resetView() {
        panOffset = .zero
        scale = 1.0
    }

    /// Reset everything to defaults
    public func resetAll() {
        resetDisplay()
        resetSimulation()
        resetView()
        showLabels = true
        nodeColorOverride = nil
    }
}
