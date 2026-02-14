public struct SVGResolvedNodeStyle: Sendable, Equatable {
    public var nodeID: String
    public var element: SVGElementKind
    public var style: SVGResolvedStyle
    public var scale: SVGSize?
    public var offset: SVGPoint?

    public init(
        nodeID: String,
        element: SVGElementKind,
        style: SVGResolvedStyle,
        scale: SVGSize? = nil,
        offset: SVGPoint? = nil
    ) {
        self.nodeID = nodeID
        self.element = element
        self.style = style
        self.scale = scale
        self.offset = offset
    }
}

public struct SVGStyleResolver: Sendable {
    public init() {}

    public func resolve(
        document: SVGDocument,
        configuration: SVGRenderConfiguration = .init()
    ) -> [String: SVGResolvedNodeStyle] {
        let viewport = resolveViewport(from: document)
        var result: [String: SVGResolvedNodeStyle] = [:]
        for node in document.nodes {
            resolveNode(
                node,
                inheritedStyle: .init(),
                viewport: viewport,
                configuration: configuration,
                result: &result
            )
        }
        return result
    }

    private func resolveNode(
        _ node: SVGNode,
        inheritedStyle: SVGResolvedStyle,
        viewport: SVGSize,
        configuration: SVGRenderConfiguration,
        result: inout [String: SVGResolvedNodeStyle]
    ) {
        var style = inheritedStyle.applying(style: node.base.style)
        var scaleOverride: SVGSize?
        var offsetOverride: SVGPoint?

        if let staticOverride = configuration.idOverrides[node.nodeID] {
            apply(override: staticOverride, style: &style, scale: &scaleOverride, offset: &offsetOverride)
        }

        if let resolver = configuration.resolver {
            let context = NodeContext(
                id: node.base.id,
                syntheticID: node.base.syntheticID,
                element: node.elementKind,
                attributes: node.base.attributes,
                inheritedStyle: inheritedStyle,
                viewport: viewport
            )
            if let dynamicOverride = resolver(context) {
                apply(override: dynamicOverride, style: &style, scale: &scaleOverride, offset: &offsetOverride)
            }
        }

        result[node.nodeID] = SVGResolvedNodeStyle(
            nodeID: node.nodeID,
            element: node.elementKind,
            style: style,
            scale: scaleOverride,
            offset: offsetOverride
        )

        for child in node.children {
            resolveNode(
                child,
                inheritedStyle: style,
                viewport: viewport,
                configuration: configuration,
                result: &result
            )
        }
    }

    private func apply(
        override: NodeOverride,
        style: inout SVGResolvedStyle,
        scale: inout SVGSize?,
        offset: inout SVGPoint?
    ) {
        if let fill = override.fill {
            style.fill = fill
        }
        if let stroke = override.stroke {
            style.stroke = stroke
        }
        if let strokeWidth = override.strokeWidth {
            style.strokeWidth = strokeWidth
        }
        if let opacity = override.opacity {
            style.opacity = opacity
        }
        if let scaleValue = override.scale {
            scale = scaleValue
        }
        if let offsetValue = override.offset {
            offset = offsetValue
        }
    }

    private func resolveViewport(from document: SVGDocument) -> SVGSize {
        if let size = document.size {
            return size
        }
        if let viewBox = document.viewBox {
            return SVGSize(width: viewBox.width, height: viewBox.height)
        }
        return SVGSize(width: 0, height: 0)
    }
}
