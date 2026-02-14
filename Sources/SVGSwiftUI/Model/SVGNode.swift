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

struct SVGBaseNode: Sendable, Equatable {
    var id: String?
    var syntheticID: String
    var style: SVGStyle
    var transform: SVGTransform
    var attributes: [String: String]

    init(
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

struct SVGGroupNode: Sendable, Equatable {
    var base: SVGBaseNode
    var children: [SVGNode]

    init(base: SVGBaseNode, children: [SVGNode]) {
        self.base = base
        self.children = children
    }
}

struct SVGPathNode: Sendable, Equatable {
    var base: SVGBaseNode
    var pathData: String
    var commands: [SVGPathCommand]

    init(base: SVGBaseNode, pathData: String, commands: [SVGPathCommand] = []) {
        self.base = base
        self.pathData = pathData
        self.commands = commands
    }
}

struct SVGShapeNode: Sendable, Equatable {
    var base: SVGBaseNode
    var kind: SVGElementKind
    var values: [String: Double]
    var points: [SVGPoint]

    init(
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

enum SVGNode: Sendable, Equatable {
    case group(SVGGroupNode)
    case path(SVGPathNode)
    case shape(SVGShapeNode)

    var elementKind: SVGElementKind {
        switch self {
        case .group:
            return .group
        case .path:
            return .path
        case .shape(let node):
            return node.kind
        }
    }

    var nodeID: String {
        switch self {
        case .group(let node):
            return node.base.id ?? node.base.syntheticID
        case .path(let node):
            return node.base.id ?? node.base.syntheticID
        case .shape(let node):
            return node.base.id ?? node.base.syntheticID
        }
    }

    var base: SVGBaseNode {
        switch self {
        case .group(let node):
            return node.base
        case .path(let node):
            return node.base
        case .shape(let node):
            return node.base
        }
    }

    var children: [SVGNode] {
        switch self {
        case .group(let node):
            return node.children
        case .path, .shape:
            return []
        }
    }
}
