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

import Foundation

/// Represents an edge in the graph with spring properties.
/// Uses integer indices into the node array for efficiency.
public struct Edge: Sendable, Equatable, Hashable {
    /// Index of the source node in the nodes array
    public var source: Int

    /// Index of the target node in the nodes array
    public var target: Int

    /// Spring strength (how strongly nodes are pulled together)
    public var weight: Float

    /// Rest length of the spring (target distance between nodes)
    public var distance: Float

    public init(source: Int, target: Int, weight: Float = 1.0, distance: Float = 30.0) {
        self.source = source
        self.target = target
        self.weight = weight
        self.distance = distance
    }
}
