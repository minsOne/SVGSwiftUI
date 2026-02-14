public enum SVGElementKind: String, Sendable, Equatable {
    case svg
    case group = "g"
    case path
    case rect
    case circle
    case ellipse
    case line
    case polyline
    case polygon
}

public struct SVGBaseNode: Sendable, Equatable {
    public var id: String?
    public var syntheticID: String
    public var style: SVGStyle
    public var transform: SVGTransform
    public var attributes: [String: String]

    public init(
        id: String? = nil,
        syntheticID: String,
        style: SVGStyle = .init(),
        transform: SVGTransform = .identity,
        attributes: [String: String] = [:]
    ) {
        self.id = id
        self.syntheticID = syntheticID
        self.style = style
        self.transform = transform
        self.attributes = attributes
    }
}

public struct SVGGroupNode: Sendable, Equatable {
    public var base: SVGBaseNode
    public var children: [SVGNode]

    public init(base: SVGBaseNode, children: [SVGNode]) {
        self.base = base
        self.children = children
    }
}

public struct SVGPathNode: Sendable, Equatable {
    public var base: SVGBaseNode
    public var pathData: String
    public var commands: [SVGPathCommand]

    public init(base: SVGBaseNode, pathData: String, commands: [SVGPathCommand] = []) {
        self.base = base
        self.pathData = pathData
        self.commands = commands
    }
}

public struct SVGShapeNode: Sendable, Equatable {
    public var base: SVGBaseNode
    public var kind: SVGElementKind
    public var values: [String: Double]
    public var points: [SVGPoint]

    public init(
        base: SVGBaseNode,
        kind: SVGElementKind,
        values: [String: Double] = [:],
        points: [SVGPoint] = []
    ) {
        self.base = base
        self.kind = kind
        self.values = values
        self.points = points
    }
}

public enum SVGNode: Sendable, Equatable {
    case group(SVGGroupNode)
    case path(SVGPathNode)
    case shape(SVGShapeNode)

    public var elementKind: SVGElementKind {
        switch self {
        case .group:
            return .group
        case .path:
            return .path
        case .shape(let node):
            return node.kind
        }
    }

    public var nodeID: String {
        switch self {
        case .group(let node):
            return node.base.id ?? node.base.syntheticID
        case .path(let node):
            return node.base.id ?? node.base.syntheticID
        case .shape(let node):
            return node.base.id ?? node.base.syntheticID
        }
    }
}
