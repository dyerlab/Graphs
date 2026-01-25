import Foundation

/// Represents a parsed node from a graph file.
public struct Node: Sendable, Equatable, Hashable, Identifiable {
    public var id: String { label }
    public let label: String
    public let size: Double
    public let colorCode: Int

    public init(label: String, size: Double, colorCode: Int) {
        self.label = label
        self.size = size
        self.colorCode = colorCode
    }
}
