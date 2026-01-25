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
//  GraphConstants.swift
//  Graphs
//
//  Created by Rodney Dyer on 1/25/26.
//

import Foundation

/// Centralized constants for the graph simulation library.
public enum GraphConstants {

    
    // MARK: - Distance Thresholds

    /// Minimum distance squared to detect coincident nodes (prevents division by zero)
    public static let minDistanceSquared: Float = 1e-6

    /// Minimum distance for force calculations (prevents division by zero)
    public static let minDistance: Float = 1e-6

    /// Magnitude of random jiggle applied to coincident nodes
    public static let jiggleMagnitude: Float = 1e-3

    
    
    // MARK: - Alpha (Simulation Energy)

    /// Alpha threshold below which simulation should reheat on start
    public static let reheatAlphaThreshold: Float = 0.1

    /// Default alpha value when reheating simulation
    public static let reheatAlphaValue: Float = 0.3

    /// Alpha value for moderate reheat (e.g., applying settings changes)
    public static let moderateReheatAlpha: Float = 0.5

    
    
    // MARK: - Position Initialization

    /// Default radius for random position initialization
    public static let initialPositionRadius: Float = 100

    
    
    
    // MARK: - Force Distribution

    /// Factor for distributing forces equally between two nodes
    public static let forceDistributionFactor: Float = 0.5

    
    
    
    // MARK: - View Constants

    /// Target frame rate for animation (frames per second)
    public static let targetFrameRate: Double = 60.0

    /// Frame interval derived from target frame rate
    public static let frameInterval: Double = 1.0 / targetFrameRate

    /// Default threshold distance for finding nodes near a point
    public static let defaultNodeFindThreshold: Float = 20

    /// Default distance for edges when not specified
    public static let defaultEdgeDistance: Float = 30.0

    /// Base font size for node labels
    public static let baseLabelFontSize: CGFloat = 10

    /// Offset from node edge for label positioning
    public static let labelOffset: CGFloat = 2
}
