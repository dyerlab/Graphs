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
