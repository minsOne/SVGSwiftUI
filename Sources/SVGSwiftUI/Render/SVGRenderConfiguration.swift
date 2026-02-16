public struct NodeOverride: Sendable, Equatable {
    public var fill: SVGPaint?
    public var stroke: SVGPaint?
    public var strokeWidth: Double?
    public var fontSize: Double?
    public var fontFamily: String?
    public var textAnchor: SVGTextAnchor?
    public var fontStyle: SVGFontStyle?
    public var fontWeight: SVGFontWeight?
    public var opacity: Double?
    public var scale: SVGSize?
    public var offset: SVGPoint?

    public init(
        fill: SVGPaint? = nil,
        stroke: SVGPaint? = nil,
        strokeWidth: Double? = nil,
        fontSize: Double? = nil,
        fontFamily: String? = nil,
        textAnchor: SVGTextAnchor? = nil,
        fontStyle: SVGFontStyle? = nil,
        fontWeight: SVGFontWeight? = nil,
        opacity: Double? = nil,
        scale: SVGSize? = nil,
        offset: SVGPoint? = nil
    ) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.textAnchor = textAnchor
        self.fontStyle = fontStyle
        self.fontWeight = fontWeight
        self.opacity = opacity
        self.scale = scale
        self.offset = offset
    }
}

public struct NodeContext: Sendable, Equatable {
    public var id: String?
    public var syntheticID: String
    public var element: SVGElementKind
    public var attributes: [String: String]
    var inheritedStyle: SVGResolvedStyle
    public var viewport: SVGSize

    init(
        id: String?,
        syntheticID: String,
        element: SVGElementKind,
        attributes: [String: String],
        inheritedStyle: SVGResolvedStyle,
        viewport: SVGSize
    ) {
        self.id = id
        self.syntheticID = syntheticID
        self.element = element
        self.attributes = attributes
        self.inheritedStyle = inheritedStyle
        self.viewport = viewport
    }
}

public typealias NodeOverrideMap = [String: NodeOverride]
public typealias NodeStyleResolver = @Sendable (NodeContext) -> NodeOverride?

public struct SVGRenderConfiguration: Sendable {
    public var idOverrides: NodeOverrideMap
    public var resolver: NodeStyleResolver?

    public init(idOverrides: NodeOverrideMap = [:], resolver: NodeStyleResolver? = nil) {
        self.idOverrides = idOverrides
        self.resolver = resolver
    }
}
