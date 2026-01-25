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

/// Configuration parameters for the force simulation.
public struct SimulationConfig: Sendable, Equatable {
    // Alpha (activity) parameters
    public var alphaTarget: Float = 0.0
    public var alphaDecay: Float = 0.02
    public var alphaMin: Float = 0.001
    public var velocityDecay: Float = 0.6

    // ManyBody force parameters
    public var manyBodyStrength: Float = -30.0
    public var manyBodyMinDistance: Float = 1.0

    // Center force parameters
    public var centerStrength: Float = 0.1

    // Collide force parameters
    public var collideRadius: Float = 5.0
    public var collideStrength: Float = 0.7

    public init(
        alphaTarget: Float = 0.0,
        alphaDecay: Float = 0.02,
        alphaMin: Float = 0.001,
        velocityDecay: Float = 0.6,
        manyBodyStrength: Float = -30.0,
        manyBodyMinDistance: Float = 1.0,
        centerStrength: Float = 0.1,
        collideRadius: Float = 5.0,
        collideStrength: Float = 0.7
    ) {
        self.alphaTarget = alphaTarget
        self.alphaDecay = alphaDecay
        self.alphaMin = alphaMin
        self.velocityDecay = velocityDecay
        self.manyBodyStrength = manyBodyStrength
        self.manyBodyMinDistance = manyBodyMinDistance
        self.centerStrength = centerStrength
        self.collideRadius = collideRadius
        self.collideStrength = collideStrength
    }

    public static let `default` = SimulationConfig()
}
