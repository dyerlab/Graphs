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

/// A node in the graph with visual properties.
public struct Node: Identifiable, Sendable, Equatable, Hashable {
    public var id = UUID()
    public var label: String
    public var size: Double
    public var color: Color

    public init(label: String, size: Double = 10, color: Color = .blue) {
        self.label = label
        self.size = size
        self.color = color
    }
}

