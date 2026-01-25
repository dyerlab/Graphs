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

/// Maps integer color codes to SwiftUI colors.
///
/// This function provides a default color palette for graph files that use
/// integer color codes. It is used by ``parseGraph(_:colorMapping:)`` and
/// related import functions.
///
/// ## Color Mapping
///
/// | Code | Color |
/// |------|-------|
/// | 0 | Gray |
/// | 1 | Blue |
/// | 2 | Green |
/// | 3 | Orange |
/// | 4 | Red |
/// | 5 | Purple |
/// | 6 | Pink |
/// | 7 | Yellow |
/// | 8 | Cyan |
/// | 9 | Mint |
/// | Other | Blue |
///
/// ## Example
///
/// ```swift
/// let color = defaultColorMapping(1)  // Returns .blue
/// let unknown = defaultColorMapping(99)  // Returns .blue (default)
/// ```
///
/// ## Custom Mappings
///
/// You can provide your own color mapping function to the graph import functions:
///
/// ```swift
/// func myColorMapping(_ code: Int) -> Color {
///     switch code {
///     case 0: return .black
///     case 1: return .white
///     default: return .gray
///     }
/// }
///
/// let graph = try parseGraph(content, colorMapping: myColorMapping)
/// ```
///
/// - Parameter code: An integer color code from the graph file.
/// - Returns: A SwiftUI `Color` corresponding to the code, or `.blue` for unknown codes.
public func defaultColorMapping(_ code: Int) -> Color {
    switch code {
    case 0: return .gray
    case 1: return .blue
    case 2: return .green
    case 3: return .orange
    case 4: return .red
    case 5: return .purple
    case 6: return .pink
    case 7: return .yellow
    case 8: return .cyan
    case 9: return .mint
    default: return .blue
    }
}
