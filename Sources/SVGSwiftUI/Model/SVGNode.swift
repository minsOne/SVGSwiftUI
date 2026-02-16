public enum SVGElementKind: String, Sendable, Equatable {
    case svg
    case group = "g"
    case path
    case image
    case text
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

struct SVGRasterImageNode: Sendable, Equatable {
    let base: SVGBaseNode
    let x: Double?
    let y: Double?
    let width: Double?
    let height: Double?
    let mediaType: String?

    init(
        base: SVGBaseNode,
        x: Double?,
        y: Double?,
        width: Double?,
        height: Double?,
        mediaType: String?
    ) {
        self.base = base
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.mediaType = mediaType
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

struct SVGTextNode: Sendable, Equatable {
    var base: SVGBaseNode
    var x: Double?
    var y: Double?
    var content: String

    init(
        base: SVGBaseNode,
        x: Double?,
        y: Double?,
        content: String
    ) {
        self.base = base
        self.x = x
        self.y = y
        self.content = content
    }
}

enum SVGNode: Sendable, Equatable {
    case group(SVGGroupNode)
    case path(SVGPathNode)
    case rasterImage(SVGRasterImageNode)
    case shape(SVGShapeNode)
    case text(SVGTextNode)

    var elementKind: SVGElementKind {
        switch self {
        case .group:
            return .group
        case .path:
            return .path
        case .rasterImage:
            return .image
        case .shape(let node):
            return node.kind
        case .text:
            return .text
        }
    }

    var nodeID: String {
        switch self {
        case .group(let node):
            return node.base.id ?? node.base.syntheticID
        case .path(let node):
            return node.base.id ?? node.base.syntheticID
        case .rasterImage(let node):
            return node.base.id ?? node.base.syntheticID
        case .shape(let node):
            return node.base.id ?? node.base.syntheticID
        case .text(let node):
            return node.base.id ?? node.base.syntheticID
        }
    }

    var base: SVGBaseNode {
        switch self {
        case .group(let node):
            return node.base
        case .path(let node):
            return node.base
        case .rasterImage(let node):
            return node.base
        case .shape(let node):
            return node.base
        case .text(let node):
            return node.base
        }
    }

    var children: [SVGNode] {
        switch self {
        case .group(let node):
            return node.children
        case .path, .rasterImage, .shape, .text:
            return []
        }
    }
}
