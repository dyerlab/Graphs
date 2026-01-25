//
//  defaultColorMapping.swift
//  Graphs
//
//  Created by Rodney Dyer on 1/24/26.
//

import SwiftUI

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
