#if canImport(SwiftUI)
import CoreGraphics
import SwiftUI

public struct SVGView: View {
    private static let parser = SVGParser()
    private static let parseCache = SVGParseCache()

    private let source: SVGSource
    private let configuration: SVGRenderConfiguration
    private let options: SVGParserOptions
    private let cacheStats: SVGCacheStats?

    public init(
        source: SVGSource,
        options: SVGParserOptions = .init(),
        configuration: SVGRenderConfiguration = .init(),
        cacheStats: SVGCacheStats? = nil
    ) {
        self.source = source
        self.options = options
        self.configuration = configuration
        self.cacheStats = cacheStats
    }

    public var body: some View {
        SVGStaticPlaceholderView(
            source: source,
            parser: Self.parser,
            cache: Self.parseCache,
            options: options,
            configuration: configuration,
            cacheStats: cacheStats
        )
    }
}

private struct SVGStaticPlaceholderView: View {
    struct RenderTaskID: Equatable {
        let source: SVGSource
        let options: SVGParserOptions
        let configFingerprint: String
    }

    let source: SVGSource
    let parser: SVGParser
    let cache: SVGParseCache
    let options: SVGParserOptions
    let configuration: SVGRenderConfiguration
    let cacheStats: SVGCacheStats?

    @State private var parsingFailed = false
    @State private var document: SVGDocument?
    @State private var pathCache: [String: CGPath] = [:]
    @State private var clipPathCache: [String: CGPath] = [:]
    @State private var cachedDrawNodes: [SVGDrawNode] = []
    @State private var cachedConfigurationFingerprint: String = ""
    @State private var canCacheDrawNodesForCurrentDocument: Bool = false
    @State private var canCachePathCacheForCurrentDocument: Bool = false
    @State private var parsingFailureMessage: String = ""

    private var usesStaticConfiguration: Bool {
        configuration.resolver == nil
    }

    private let styleResolver = SVGStyleResolver()
    private let nodePathBuilder = SVGNodePathBuilder()
    private let transformBuilder = SVGTransformBuilder()

    private var drawNodes: [SVGDrawNode] {
        let shouldUseCachedDrawNodes: Bool = usesStaticConfiguration && canCacheDrawNodesForCurrentDocument
        if !shouldUseCachedDrawNodes {
            guard let document else {
                return []
            }
            let resolved = styleResolver.resolve(document: document, configuration: configuration)
            return buildDrawNodes(
                from: document.nodes,
                resolved: resolved,
                filterDefinitions: document.filterDefinitions,
                clipPathCache: clipPathCache,
                inheritedTransform: .identity,
                inheritedClipPaths: [],
                canUsePathCache: canCachePathCacheForCurrentDocument
            )
        }
        if cachedConfigurationFingerprint == configurationFingerprint {
            return cachedDrawNodes
        }
        guard let document else {
            return []
        }
        let resolved = styleResolver.resolve(document: document, configuration: configuration)
        return buildDrawNodes(
            from: document.nodes,
            resolved: resolved,
            filterDefinitions: document.filterDefinitions,
            clipPathCache: clipPathCache,
            inheritedTransform: .identity,
            inheritedClipPaths: [],
            canUsePathCache: canCachePathCacheForCurrentDocument
        )
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let renderViewportTransform: SVGRenderViewportTransform? = viewportTransform(for: size)
                let transform = renderViewportTransform?.transform ?? .identity
                let strokeScale = renderViewportTransform?.strokeScale ?? 1.0

                for node in drawNodes {
                    if node.clipPaths.isEmpty && node.filterPrimitives.isEmpty {
                        drawNodeShape(
                            node,
                            in: &context,
                            renderTransform: transform,
                            strokeScale: strokeScale
                        )
                    } else if SVGFilterImageRenderer.requiresOffscreenProcessing(node.filterPrimitives) {
                        context.drawLayer { layer in
                            if !node.clipPaths.isEmpty {
                                for clipPath in node.clipPaths {
                                    let transformedClipPath = clipPath.applying(transform)
                                    layer.clip(to: transformedClipPath, style: .init(eoFill: false))
                                }
                            }
                            if let filteredImage: CGImage = SVGFilterImageRenderer.renderFilteredImage(
                                path: node.path.applying(transform),
                                fillColor: node.fillColor,
                                fillStyle: node.fillStyle,
                                strokeColor: node.strokeColor,
                                strokeWidth: node.strokeWidth * strokeScale,
                                lineCap: node.lineCap,
                                lineJoin: node.lineJoin,
                                miterLimit: node.miterLimit,
                                dash: node.dash,
                                dashPhase: node.dashPhase,
                                opacity: node.opacity,
                                fillOpacity: node.fillOpacity,
                                strokeOpacity: node.strokeOpacity,
                                size: size,
                                primitives: node.filterPrimitives
                            ) {
                                let image = Image(
                                    decorative: filteredImage,
                                    scale: 1,
                                    orientation: .up
                                )
                                layer.draw(image, in: CGRect(origin: .zero, size: size))
                            } else {
                                drawNodeShape(
                                    node,
                                    in: &layer,
                                    renderTransform: transform,
                                    strokeScale: strokeScale
                                )
                            }
                        }
                    } else {
                        context.drawLayer { layer in
                            if !node.clipPaths.isEmpty {
                                for clipPath in node.clipPaths {
                                    let transformedClipPath = clipPath.applying(transform)
                                    layer.clip(to: transformedClipPath, style: .init(eoFill: false))
                                }
                            }
                            applyFilterPrimitives(node.filterPrimitives, to: &layer)
                            drawNodeShape(
                                node,
                                in: &layer,
                                renderTransform: transform,
                                strokeScale: strokeScale
                            )
                        }
                    }
                }
            }
            .overlay(alignment: .center) {
                if parsingFailed {
                    VStack(spacing: 4) {
                        Text("Invalid SVG")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let failureMessage = debugParsingFailureMessage {
                            Text(failureMessage)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .task(id: RenderTaskID(
                source: source,
                options: options,
                configFingerprint: configurationFingerprint
            )) {
                await loadDocument()
            }
        }
    }

    private func drawNodeShape(
        _ node: SVGDrawNode,
        in context: inout GraphicsContext,
        renderTransform: CGAffineTransform,
        strokeScale: CGFloat
    ) {
        let renderedPath: Path = node.path.applying(renderTransform)
        if let fill = node.fillColor {
            let totalFillOpacity: Double = node.opacity * node.fillOpacity
            context.fill(
                renderedPath,
                with: .color(fill.opacity(totalFillOpacity)),
                style: node.fillStyle
            )
        }
        if let stroke = node.strokeColor, node.strokeWidth > 0 {
            let totalStrokeOpacity: Double = node.opacity * node.strokeOpacity
            let scaledStrokeWidth: CGFloat = max(node.strokeWidth * strokeScale, 0.0)
            let strokeStyle = StrokeStyle(
                lineWidth: scaledStrokeWidth,
                lineCap: node.lineCap,
                lineJoin: node.lineJoin,
                miterLimit: node.miterLimit,
                dash: node.dash,
                dashPhase: node.dashPhase
            )
            context.stroke(
                renderedPath,
                with: .color(stroke.opacity(totalStrokeOpacity)),
                style: strokeStyle
            )
        }
    }

    private func viewportTransform(for size: CGSize) -> SVGRenderViewportTransform? {
        guard size.width > 0 && size.height > 0 else {
            return nil
        }
        guard let transformSource = resolveRenderSourceRect() else {
            return nil
        }
        let sourceWidth: CGFloat = transformSource.width
        let sourceHeight: CGFloat = transformSource.height
        if sourceWidth <= 0 || sourceHeight <= 0 {
            return nil
        }
        let scaleX = size.width / sourceWidth
        let scaleY = size.height / sourceHeight
        let scale = min(scaleX, scaleY)
        if !scale.isFinite || scale <= 0 {
            return nil
        }

        let renderedWidth = sourceWidth * scale
        let renderedHeight = sourceHeight * scale
        let translateX = (-transformSource.minX * scale) + ((size.width - renderedWidth) / 2)
        let translateY = (-transformSource.minY * scale) + ((size.height - renderedHeight) / 2)

        let transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: translateX, y: translateY)
        return SVGRenderViewportTransform(
            transform: transform,
            strokeScale: scale
        )
    }

    private func resolveRenderSourceRect() -> CGRect? {
        if let document {
            if let size = document.size {
                let width: CGFloat = CGFloat(size.width)
                let height: CGFloat = CGFloat(size.height)
                if width > 0 && height > 0 {
                    return CGRect(
                        x: 0.0,
                        y: 0.0,
                        width: width,
                        height: height
                    )
                }
            }

            if let viewBox = document.viewBox {
                let width: CGFloat = CGFloat(viewBox.width)
                let height: CGFloat = CGFloat(viewBox.height)
                if width > 0 && height > 0 {
                    return CGRect(
                        x: CGFloat(viewBox.x),
                        y: CGFloat(viewBox.y),
                        width: width,
                        height: height
                    )
                }
            }
        }
        return nil
    }

    private var configurationFingerprint: String {
        SVGRenderConfigurationSignature.fingerprint(for: configuration)
    }

    @MainActor
    private func loadDocument() async {
        let fingerprint = configurationFingerprint
        do {
            let data = try source.loadData()
            let key = SVGParseCacheKey.from(sourceData: data, options: options)
            let sourceByteCount: Int = data.count
            let canCache: SVGRenderCachePolicy.Decision
            if let cached = await cache.document(for: key) {
                canCache = SVGRenderCachePolicy.decision(
                    for: cached,
                    sourceByteCount: sourceByteCount
                )
                canCacheDrawNodesForCurrentDocument = canCache.shouldCacheDrawNodes
                canCachePathCacheForCurrentDocument = canCache.shouldCachePathCache
                document = cached
                pathCache = canCache.shouldCachePathCache
                    ? buildPathCache(from: cached.nodes)
                    : [:]
                clipPathCache = buildClipPathCache(from: cached.clipPaths)
                updateCachedDrawNodes(
                    from: cached,
                    using: fingerprint,
                    canCache: canCache.shouldCacheDrawNodes
                )
                parsingFailed = false
                await refreshCacheMetrics()
                return
            }

            let parsed = try parser.parse(data: data, options: options)
            canCache = SVGRenderCachePolicy.decision(
                for: parsed,
                sourceByteCount: sourceByteCount
            )
            canCacheDrawNodesForCurrentDocument = canCache.shouldCacheDrawNodes
            canCachePathCacheForCurrentDocument = canCache.shouldCachePathCache
            await cache.insert(parsed, for: key, cost: data.count)
            document = parsed
            pathCache = canCache.shouldCachePathCache
                ? buildPathCache(from: parsed.nodes)
                : [:]
            clipPathCache = buildClipPathCache(from: parsed.clipPaths)
            updateCachedDrawNodes(
                from: parsed,
                using: fingerprint,
                canCache: canCache.shouldCacheDrawNodes
            )
            parsingFailed = false
            await refreshCacheMetrics()
        } catch {
            canCacheDrawNodesForCurrentDocument = false
                canCachePathCacheForCurrentDocument = false
                parsingFailureMessage = error.localizedDescription
                parsingFailed = true
                document = nil
                pathCache.removeAll()
            clipPathCache.removeAll()
            cachedConfigurationFingerprint = ""
            cachedDrawNodes.removeAll()
            await refreshCacheMetrics()
        }
    }

    private var debugParsingFailureMessage: String? {
        let hasMessage = !parsingFailureMessage.isEmpty
        return hasMessage ? parsingFailureMessage : nil
    }

    private func updateCachedDrawNodes(
        from document: SVGDocument,
        using fingerprint: String,
        canCache: Bool
    ) {
        if !usesStaticConfiguration || !canCache {
            cachedConfigurationFingerprint = ""
            cachedDrawNodes.removeAll()
            return
        }

        let resolved = styleResolver.resolve(
            document: document,
            configuration: configuration
        )
        cachedDrawNodes = buildDrawNodes(
            from: document.nodes,
            resolved: resolved,
            filterDefinitions: document.filterDefinitions,
            clipPathCache: clipPathCache,
            inheritedTransform: .identity,
            inheritedClipPaths: [],
            canUsePathCache: canCachePathCacheForCurrentDocument
        )
        cachedConfigurationFingerprint = fingerprint
    }

    @MainActor
    private func refreshCacheMetrics() async {
        guard let cacheStats else {
            return
        }
        let metrics = await cache.metricsSnapshot()
        cacheStats.update(metrics)
    }

    private func buildDrawNodes(
        from nodes: [SVGNode],
        resolved: [String: SVGResolvedNodeStyle],
        filterDefinitions: [String: SVGFilterDefinition],
        clipPathCache: [String: CGPath],
        inheritedTransform: CGAffineTransform,
        inheritedClipPaths: [CGPath],
        canUsePathCache: Bool
    ) -> [SVGDrawNode] {
        var output: [SVGDrawNode] = []
        for node in nodes {
            let nodeID: String = node.nodeID
            let maybeClipPath = clipPath(
                from: node,
                clipPathCache: clipPathCache
            )
            var activeClipPaths: [CGPath] = inheritedClipPaths
            if let nextClipPath = maybeClipPath {
                activeClipPaths.append(nextClipPath)
            }

            let nodeTransform: CGAffineTransform = transformBuilder.concatenate(
                local: node.base.transform,
                inherited: inheritedTransform
            )

            if let built = makeDrawNode(
                for: node,
                resolved: resolved[nodeID],
                filterDefinitions: filterDefinitions,
                inheritedTransform: inheritedTransform,
                canUsePathCache: canUsePathCache,
                clipPaths: activeClipPaths
            ) {
                output.append(built)
            }
            if !node.children.isEmpty {
                output.append(
                    contentsOf: buildDrawNodes(
                    from: node.children,
                    resolved: resolved,
                    filterDefinitions: filterDefinitions,
                    clipPathCache: clipPathCache,
                    inheritedTransform: nodeTransform,
                    inheritedClipPaths: activeClipPaths,
                    canUsePathCache: canUsePathCache
                )
                )
            }
        }
        return output
    }

    private func makeDrawNode(
        for node: SVGNode,
        resolved: SVGResolvedNodeStyle?,
        filterDefinitions: [String: SVGFilterDefinition],
        inheritedTransform: CGAffineTransform,
        canUsePathCache: Bool,
        clipPaths: [CGPath]
    ) -> SVGDrawNode? {
        guard let resolved else {
            return nil
        }

        if let rasterNode = rasterImageNode(from: node) {
            return makeRasterDrawNode(
                for: rasterNode,
                resolved: resolved,
                inheritedTransform: inheritedTransform,
                filterDefinitions: filterDefinitions,
                clipPaths: clipPaths
            )
        }

        let filterPrimitives = resolveFilterPrimitives(
            from: resolved.style.filter,
            filterDefinitions: filterDefinitions
        )

        let maybeCachedPath: CGPath? = canUsePathCache
            ? pathCache[node.nodeID]
            : nil
        guard var cgPath = maybeCachedPath ?? nodePathBuilder.buildPath(
            for: node,
            inheritedTransform: inheritedTransform
        ) else {
            return nil
        }
        if cgPath.isEmpty {
            return nil
        }
        cgPath = applyGeometryOverrides(cgPath, scale: resolved.scale, offset: resolved.offset)
        let path = Path(cgPath)

        return SVGDrawNode(
            id: resolved.nodeID,
            path: path,
            fillColor: color(from: resolved.style.fill),
            fillStyle: fillStyle(from: resolved.style.fillRule),
            strokeColor: color(from: resolved.style.stroke),
            fillOpacity: CGFloat(resolved.style.fillOpacity),
            strokeOpacity: CGFloat(resolved.style.strokeOpacity),
            strokeWidth: CGFloat(resolved.style.strokeWidth),
            lineCap: lineCap(from: resolved.style.strokeLineCap),
            lineJoin: lineJoin(from: resolved.style.strokeLineJoin),
            miterLimit: CGFloat(resolved.style.strokeMiterLimit),
            dash: resolved.style.strokeDashArray.map { CGFloat($0) },
            dashPhase: CGFloat(resolved.style.strokeDashOffset),
            opacity: resolved.style.opacity,
            clipPaths: clipPaths.map { Path($0) },
            filterPrimitives: filterPrimitives
        )
    }

    private func makeRasterDrawNode(
        for imageNode: SVGRasterImageNode,
        resolved: SVGResolvedNodeStyle,
        inheritedTransform: CGAffineTransform,
        filterDefinitions: [String: SVGFilterDefinition],
        clipPaths: [CGPath]
    ) -> SVGDrawNode {
        let x: CGFloat = CGFloat(imageNode.x ?? 0)
        let y: CGFloat = CGFloat(imageNode.y ?? 0)
        let width: CGFloat = CGFloat(imageNode.width ?? 0)
        let height: CGFloat = CGFloat(imageNode.height ?? 0)

        let widthWithFallback: CGFloat = width > 0 ? width : 1
        let heightWithFallback: CGFloat = height > 0 ? height : 1

        var localTransform: CGAffineTransform = transformBuilder.concatenate(
            local: imageNode.base.transform,
            inherited: inheritedTransform
        )

        let rectPath = CGMutablePath()
        rectPath.addRect(CGRect(x: x, y: y, width: widthWithFallback, height: heightWithFallback))
        let cgRectPath: CGPath = if localTransform == .identity {
            rectPath
        } else {
            rectPath.copy(using: &localTransform) ?? rectPath
        }
        let path = applyGeometryOverrides(
            cgRectPath,
            scale: resolved.scale,
            offset: resolved.offset
        )

        let strokeWidth = max(CGFloat(resolved.style.strokeWidth), 1)
        let fallbackFill = Color.gray.opacity(0.16)
        let fallbackStroke = Color.gray

        return SVGDrawNode(
            id: resolved.nodeID,
            path: Path(path),
            fillColor: color(from: resolved.style.fill) ?? fallbackFill,
            fillStyle: fillStyle(from: resolved.style.fillRule),
            strokeColor: color(from: resolved.style.stroke) ?? fallbackStroke,
            fillOpacity: CGFloat(resolved.style.fillOpacity),
            strokeOpacity: CGFloat(resolved.style.strokeOpacity),
            strokeWidth: strokeWidth,
            lineCap: lineCap(from: resolved.style.strokeLineCap),
            lineJoin: lineJoin(from: resolved.style.strokeLineJoin),
            miterLimit: CGFloat(resolved.style.strokeMiterLimit),
            dash: resolved.style.strokeDashArray.map { CGFloat($0) },
            dashPhase: CGFloat(resolved.style.strokeDashOffset),
            opacity: resolved.style.opacity,
            clipPaths: clipPaths.map { Path($0) },
            filterPrimitives: resolveFilterPrimitives(
                from: resolved.style.filter,
                filterDefinitions: filterDefinitions
            )
        )
    }

    private func rasterImageNode(from node: SVGNode) -> SVGRasterImageNode? {
        if case .rasterImage(let imageNode) = node {
            return imageNode
        }
        return nil
    }

    private func buildPathCache(from nodes: [SVGNode]) -> [String: CGPath] {
        var cache: [String: CGPath] = [:]
        cachePaths(
            from: nodes,
            inheritedTransform: .identity,
            into: &cache
        )
        return cache
    }

    private func buildClipPathCache(from definitions: [String: [SVGNode]]) -> [String: CGPath] {
        var cache: [String: CGPath] = [:]
        for (clipPathID, nodes) in definitions {
            guard let clipPath = buildClipPath(from: nodes, inheritedTransform: .identity) else {
                continue
            }
            cache[clipPathID] = clipPath
        }
        return cache
    }

    private func buildClipPath(
        from nodes: [SVGNode],
        inheritedTransform: CGAffineTransform
    ) -> CGPath? {
        let mutablePath = CGMutablePath()
        var hasPath = false

        for node in nodes {
            switch node {
            case .path, .shape:
                if let nodePath = nodePathBuilder.buildPath(for: node, inheritedTransform: inheritedTransform) {
                    mutablePath.addPath(nodePath)
                    hasPath = true
                }
            case .group(let group):
                let nextTransform: CGAffineTransform = transformBuilder.concatenate(
                    local: group.base.transform,
                    inherited: inheritedTransform
                )
                if let groupPath = buildClipPath(
                    from: group.children,
                    inheritedTransform: nextTransform
                ) {
                    mutablePath.addPath(groupPath)
                    hasPath = true
                }
            case .rasterImage:
                break
            }
        }

        if !hasPath {
            return nil
        }
        return mutablePath
    }

    private func resolveFilterPrimitives(
        from filterValue: String?,
        filterDefinitions: [String: SVGFilterDefinition]
    ) -> [SVGFilterPrimitive] {
        guard let filterValue else {
            return []
        }
        guard let filterID = parseReferenceID(from: filterValue) else {
            return []
        }
        guard let filterDefinition = filterDefinitions[filterID] else {
            return []
        }
        return filterDefinition.primitives
    }

    private func applyFilterPrimitives(
        _ primitives: [SVGFilterPrimitive],
        to context: inout GraphicsContext
    ) {
        var availableSources: Set<String> = SVGFilterGraphExecutor.defaultAvailableSources()
        for primitive in primitives {
            if !SVGFilterGraphExecutor.canExecute(primitive, availableSources: availableSources) {
                continue
            }

            switch primitive {
            case .gaussianBlur(
                let stdDeviationX,
                let stdDeviationY,
                _,
                _
            ):
                let radius = max(stdDeviationX, stdDeviationY)
                context.addFilter(.blur(radius: CGFloat(radius)))
                if let resultName: String = SVGFilterGraphExecutor.resolvedResultName(for: primitive) {
                    availableSources.insert(resultName)
                }
            case .offset(
                let dx,
                let dy,
                _,
                _
            ):
                context.translateBy(x: CGFloat(dx), y: CGFloat(dy))
                if let resultName: String = SVGFilterGraphExecutor.resolvedResultName(for: primitive) {
                    availableSources.insert(resultName)
                }
            case .blend(
                let blendMode,
                _,
                _,
                _
            ):
                if let blendFilterMode = parseBlendFilterMode(blendMode) {
                    context.blendMode = blendFilterMode
                }
                if let resultName: String = SVGFilterGraphExecutor.resolvedResultName(for: primitive) {
                    availableSources.insert(resultName)
                }
            case .composite:
                continue
            case .colorMatrix(
                _,
                _,
                _
            ):
                if let resultName: String = SVGFilterGraphExecutor.resolvedResultName(for: primitive) {
                    availableSources.insert(resultName)
                }
            case .unsupported:
                continue
            }
        }
    }

    private func parseBlendFilterMode(_ value: String) -> GraphicsContext.BlendMode? {
        switch value {
        case "multiply":
            return .multiply
        case "screen":
            return .screen
        case "darken":
            return .darken
        case "lighten":
            return .lighten
        case "color-dodge":
            return .colorDodge
        case "color-burn":
            return .colorBurn
        case "hard-light":
            return .hardLight
        case "soft-light":
            return .softLight
        case "difference":
            return .difference
        case "exclusion":
            return .exclusion
        case "hue", "saturation", "color", "luminosity":
            return nil
        case "normal", "":
            return nil
        default:
            return nil
        }
    }

    private func clipPath(
        from node: SVGNode,
        clipPathCache: [String: CGPath]
    ) -> CGPath? {
        guard let clipPathValue = node.base.attributes["clip-path"] else {
            return nil
        }
        guard let clipPathID = parseClipPathID(from: clipPathValue) else {
            return nil
        }
        return clipPathCache[clipPathID]
    }

    private func parseClipPathID(from value: String) -> String? {
        return parseReferenceID(from: value)
    }

    private func parseReferenceID(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()
        if !lowered.hasPrefix("url(") || !trimmed.hasSuffix(")") {
            return nil
        }
        let startIndex: String.Index = trimmed.index(trimmed.startIndex, offsetBy: 4)
        let endIndex: String.Index = trimmed.index(before: trimmed.endIndex)
        if startIndex > endIndex {
            return nil
        }
        let rawID = trimmed[startIndex...endIndex]
        let innerWithWhitespace = String(rawID).trimmingCharacters(in: .whitespacesAndNewlines)
        let inner: String
        if innerWithWhitespace.count >= 2,
           innerWithWhitespace.hasPrefix("\"") && innerWithWhitespace.hasSuffix("\"") {
            let start = innerWithWhitespace.index(after: innerWithWhitespace.startIndex)
            let end = innerWithWhitespace.index(before: innerWithWhitespace.endIndex)
            inner = String(innerWithWhitespace[start..<end])
        } else if innerWithWhitespace.count >= 2,
                  innerWithWhitespace.hasPrefix("'") && innerWithWhitespace.hasSuffix("'") {
            let start = innerWithWhitespace.index(after: innerWithWhitespace.startIndex)
            let end = innerWithWhitespace.index(before: innerWithWhitespace.endIndex)
            inner = String(innerWithWhitespace[start..<end])
        } else {
            inner = innerWithWhitespace
        }

        if !inner.hasPrefix("#") {
            return nil
        }
        let marker: String.Index = inner.index(inner.startIndex, offsetBy: 1)
        let identifier = String(inner[marker...])
        if identifier.isEmpty {
            return nil
        }
        return identifier
    }

    private func cachePaths(
        from nodes: [SVGNode],
        inheritedTransform: CGAffineTransform,
        into cache: inout [String: CGPath]
    ) {
        for node in nodes {
            let nodeTransform = transformBuilder.concatenate(
                local: node.base.transform,
                inherited: inheritedTransform
            )
            switch node {
            case .shape, .path:
                if let path = nodePathBuilder.buildPath(for: node, inheritedTransform: inheritedTransform) {
                    cache[node.nodeID] = path
                }
            case .group, .rasterImage:
                break
            }
            if !node.children.isEmpty {
                cachePaths(
                    from: node.children,
                    inheritedTransform: nodeTransform,
                    into: &cache
                )
            }
        }
    }

    private func applyGeometryOverrides(_ path: CGPath, scale: SVGSize?, offset: SVGPoint?) -> CGPath {
        var transform = CGAffineTransform.identity
        if let scale {
            let bounds = path.boundingBoxOfPath
            let cx = bounds.midX
            let cy = bounds.midY
            transform = transform
                .translatedBy(x: cx, y: cy)
                .scaledBy(x: CGFloat(scale.width), y: CGFloat(scale.height))
                .translatedBy(x: -cx, y: -cy)
        }
        if let offset {
            transform = transform.translatedBy(x: CGFloat(offset.x), y: CGFloat(offset.y))
        }
        if transform == .identity {
            return path
        }
        return path.copy(using: &transform) ?? path
    }

    private func color(from paint: SVGPaint) -> Color? {
        switch paint {
        case .none:
            return nil
        case .currentColor:
            return .primary
        case .color(let color):
            return Color(
                .sRGB,
                red: color.red,
                green: color.green,
                blue: color.blue,
                opacity: color.alpha
            )
        }
    }

    private func lineCap(from lineCap: SVGLineCap) -> CGLineCap {
        switch lineCap {
        case .butt:
            return .butt
        case .round:
            return .round
        case .square:
            return .square
        }
    }

    private func lineJoin(from lineJoin: SVGLineJoin) -> CGLineJoin {
        switch lineJoin {
        case .miter:
            return .miter
        case .round:
            return .round
        case .bevel:
            return .bevel
        }
    }

    private func fillStyle(from fillRule: SVGFillRule) -> FillStyle {
        switch fillRule {
        case .nonZero:
            return FillStyle(eoFill: false)
        case .evenOdd:
            return FillStyle(eoFill: true)
        }
    }
}

private struct SVGDrawNode: Identifiable {
    let id: String
    let path: Path
    let fillColor: Color?
    let fillStyle: FillStyle
    let strokeColor: Color?
    let fillOpacity: CGFloat
    let strokeOpacity: CGFloat
    let strokeWidth: CGFloat
    let lineCap: CGLineCap
    let lineJoin: CGLineJoin
    let miterLimit: CGFloat
    let dash: [CGFloat]
    let dashPhase: CGFloat
    let opacity: Double
    let clipPaths: [Path]
    let filterPrimitives: [SVGFilterPrimitive]
}

private struct SVGRenderViewportTransform: Sendable {
    let transform: CGAffineTransform
    let strokeScale: CGFloat
}
#endif
