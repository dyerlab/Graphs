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

/// Observable settings for controlling graph display and physics parameters.
///
/// `GraphDisplaySettings` provides a central place to manage all visual and
/// physics settings for a ``GraphView``. The class is observable, so changes
/// automatically update the view.
///
/// ## Overview
///
/// Settings are organized into three categories:
/// - **Display settings**: Control visual appearance (node size, labels, colors)
/// - **Physics settings**: Control simulation forces (repulsion, centering)
/// - **View settings**: Control pan and zoom state
///
/// ## Example
///
/// ```swift
/// let settings = GraphDisplaySettings()
/// settings.showLabels = false
/// settings.nodeScaleFactor = 1.5
/// settings.repulsionStrength = -50
/// ```
///
/// ## Topics
///
/// ### Creating Settings
/// - ``init()``
///
/// ### Display Settings
/// - ``showLabels``
/// - ``nodeScaleFactor``
/// - ``fontScaleFactor``
/// - ``edgeScaleFactor``
/// - ``nodeColorOverride``
///
/// ### Physics Settings
/// - ``repulsionStrength``
/// - ``linkStrength``
/// - ``centerStrength``
///
/// ### View Settings
/// - ``panOffset``
/// - ``scale``
///
/// ### Resetting
/// - ``resetDisplay()``
/// - ``resetSimulation()``
/// - ``resetView()``
/// - ``resetAll()``
@Observable
public final class GraphDisplaySettings {

    /// Whether to show node labels.
    ///
    /// When `true`, each node's label is displayed next to it.
    /// The default value is `true`.
    public var showLabels: Bool = true

    /// Scale factor for node sizes.
    ///
    /// Multiplies the base ``Node/size`` of each node. Values greater than 1.0
    /// make nodes larger; values less than 1.0 make them smaller.
    ///
    /// The default value is 1.0.
    public var nodeScaleFactor: CGFloat = 1.0

    /// Scale factor for label font sizes.
    ///
    /// Multiplies the base font size for node labels. Adjust this to make
    /// labels more or less prominent.
    ///
    /// The default value is 1.0.
    public var fontScaleFactor: CGFloat = 1.0

    /// Scale factor for edge widths.
    ///
    /// Multiplies the base edge width. Thicker edges are more visible but
    /// may obscure nodes in dense graphs.
    ///
    /// The default value is 1.0.
    public var edgeScaleFactor: CGFloat = 1.0

    /// Optional color to apply to all nodes.
    ///
    /// When set, overrides each node's individual ``Node/color``. Set to `nil`
    /// to use the node's original color.
    ///
    /// The default value is `nil` (use node colors).
    public var nodeColorOverride: Color? = nil

    /// The strength of the repulsion force.
    ///
    /// This value is applied to ``SimulationConfig/manyBodyStrength`` when
    /// physics settings are applied. Negative values cause repulsion.
    ///
    /// The default value is -30.0.
    public var repulsionStrength: Float = -30.0

    /// The strength of edge springs.
    ///
    /// Higher values cause connected nodes to be pulled together more strongly.
    ///
    /// The default value is 1.0.
    public var linkStrength: Float = 1.0

    /// The strength of the centering force.
    ///
    /// This value is applied to ``SimulationConfig/centerStrength`` when
    /// physics settings are applied.
    ///
    /// The default value is 0.1.
    public var centerStrength: Float = 0.1

    /// The current pan offset of the view.
    ///
    /// This tracks how far the user has panned from the initial position.
    ///
    /// The default value is `.zero`.
    public var panOffset: CGSize = .zero

    /// The current zoom scale of the view.
    ///
    /// Values greater than 1.0 zoom in; values less than 1.0 zoom out.
    ///
    /// The default value is 1.0.
    public var scale: CGFloat = 1.0

    /// Creates a new settings instance with default values.
    public init() {}

    /// Resets display settings to their default values.
    ///
    /// Affects ``nodeScaleFactor``, ``fontScaleFactor``, and ``edgeScaleFactor``.
    public func resetDisplay() {
        nodeScaleFactor = 1.0
        fontScaleFactor = 1.0
        edgeScaleFactor = 1.0
    }

    /// Resets physics settings to their default values.
    ///
    /// Affects ``repulsionStrength``, ``linkStrength``, and ``centerStrength``.
    public func resetSimulation() {
        repulsionStrength = -30.0
        linkStrength = 1.0
        centerStrength = 0.1
    }

    /// Resets view settings to their default values.
    ///
    /// Affects ``panOffset`` and ``scale``.
    public func resetView() {
        panOffset = .zero
        scale = 1.0
    }

    /// Resets all settings to their default values.
    ///
    /// This is equivalent to calling ``resetDisplay()``, ``resetSimulation()``,
    /// and ``resetView()``, plus resetting ``showLabels`` and ``nodeColorOverride``.
    public func resetAll() {
        resetDisplay()
        resetSimulation()
        resetView()
        showLabels = true
        nodeColorOverride = nil
    }
}
