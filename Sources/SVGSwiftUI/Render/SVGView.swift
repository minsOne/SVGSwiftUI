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
    @State private var baseResolvedStyles: [String: SVGResolvedNodeStyle] = [:]
    @State private var animationsByTargetID: [String: [SVGSMILAnimation]] = [:]
    @State private var animatedNodeIDs: Set<String> = []
    @State private var animatedTransformNodeIDs: Set<String> = []
    @State private var staticDrawNodeLookup: [String: SVGDrawNode] = [:]
    @State private var animationStartDate: Date = .init()

    private var usesStaticConfiguration: Bool {
        configuration.resolver == nil
    }

    private var hasSMILAnimation: Bool {
        guard let document else {
            return false
        }
        return !document.animations.isEmpty
    }

    private var hasTransformAnimation: Bool {
        if !animatedTransformNodeIDs.isEmpty {
            return true
        }
        for animations in animationsByTargetID.values {
            for animation in animations {
                if animation.kind == .animateMotion {
                    return true
                }
                let attributeName: String = animation.attributeName?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() ?? ""
                if attributeName == "transform" {
                    return true
                }
            }
        }
        return false
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
            Group {
                if hasSMILAnimation {
                    TimelineView(.periodic(from: animationStartDate, by: 1.0 / 30.0)) { timeline in
                        renderCanvas(for: timeline.date)
                    }
                } else {
                    renderCanvas(for: Date())
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

    @ViewBuilder
    private func renderCanvas(for date: Date) -> some View {
        Canvas { context, size in
            let renderViewportTransform: SVGRenderViewportTransform? = viewportTransform(for: size)
            let transform = renderViewportTransform?.transform ?? .identity
            let strokeScale = renderViewportTransform?.strokeScale ?? 1.0
            let nodesToRender: [SVGDrawNode] = if hasSMILAnimation {
                animatedDrawNodes(for: date)
            } else {
                drawNodes
            }

            for node in nodesToRender {
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
    }

    private func animatedDrawNodes(for date: Date) -> [SVGDrawNode] {
        guard let document else {
            return []
        }
        let elapsed: TimeInterval = date.timeIntervalSince(animationStartDate)
        let shouldUsePathCache: Bool = canCachePathCacheForCurrentDocument && !hasTransformAnimation
        let resolvedStyles: [String: SVGResolvedNodeStyle] = SVGSMILEngine.applyAnimations(
            to: baseResolvedStyles,
            animationsByTargetID: animationsByTargetID,
            at: elapsed
        )
        if !hasTransformAnimation {
            if usesStaticConfiguration && canCacheDrawNodesForCurrentDocument && !cachedDrawNodes.isEmpty {
                if !animatedNodeIDs.isEmpty {
                    return buildAnimatedTargetedDrawNodes(
                        from: document.nodes,
                        resolved: resolvedStyles,
                        filterDefinitions: document.filterDefinitions,
                        clipPathCache: clipPathCache,
                        inheritedTransform: .identity,
                        inheritedClipPaths: [],
                        staticNodesByID: staticDrawNodeLookup,
                        canUsePathCache: shouldUsePathCache
                    )
                }
            }
        }
        return buildDrawNodes(
            from: document.nodes,
            resolved: resolvedStyles,
            filterDefinitions: document.filterDefinitions,
            clipPathCache: clipPathCache,
            inheritedTransform: .identity,
            inheritedClipPaths: [],
            canUsePathCache: shouldUsePathCache
        )
    }

    private func drawNodeShape(
        _ node: SVGDrawNode,
        in context: inout GraphicsContext,
        renderTransform: CGAffineTransform,
        strokeScale: CGFloat
    ) {
        if let text = node.textContent, let textPosition = node.textPosition {
            let fontSizeValue: CGFloat = node.textFontSize ?? 16
            let textFont = textFont(
                familyName: node.textFontFamily,
                size: fontSizeValue,
                fontStyle: node.textFontStyle,
                fontWeight: node.textFontWeight
            )
            let textColor = node.fillColor ?? Color.primary
            let alpha = CGFloat(node.opacity * node.fillOpacity)
            let anchor = textAnchorPoint(node.textAnchor)
            var content = Text(text)
            content = content
                .font(textFont)
                .foregroundColor(textColor.opacity(Double(alpha)))
            let renderedPoint = CGPointApplyAffineTransform(textPosition, renderTransform)
            context.draw(content, at: renderedPoint, anchor: anchor)
            return
        }
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

    private func textFont(
        familyName: String?,
        size: CGFloat,
        fontStyle: SVGFontStyle,
        fontWeight: SVGFontWeight
    ) -> Font {
        let name: String = familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "system"
        let sanitizedSize: CGFloat = max(size, 1)
        let resolvedWeight: Font.Weight = mappedFontWeight(fontWeight)

        if name == "system" || name.isEmpty {
            var font = Font.system(size: sanitizedSize, weight: resolvedWeight)
            if fontStyle == .italic || fontStyle == .oblique {
                font = font.italic()
            }
            return font
        }
        var font = Font.custom(name, size: sanitizedSize).weight(resolvedWeight)
        if fontStyle == .italic || fontStyle == .oblique {
            font = font.italic()
        }
        return font
    }

    private func mappedFontWeight(_ fontWeight: SVGFontWeight) -> Font.Weight {
        switch fontWeight {
        case .normal:
            return .regular
        case .bold:
            return .bold
        case .bolder:
            return .heavy
        case .lighter:
            return .light
        case .numeric(let value):
            switch value {
            case ..<150:
                return .ultraLight
            case 150..<250:
                return .thin
            case 250..<350:
                return .light
            case 350..<450:
                return .regular
            case 450..<550:
                return .medium
            case 550..<650:
                return .semibold
            case 650..<750:
                return .bold
            case 750..<850:
                return .heavy
            default:
                return .black
            }
        }
    }

    private func textAnchorPoint(_ anchor: SVGTextAnchor) -> UnitPoint {
        switch anchor {
        case .start:
            return .leading
        case .middle:
            return .center
        case .end:
            return .trailing
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
                let resolved = styleResolver.resolve(
                    document: cached,
                    configuration: configuration
                )
                baseResolvedStyles = resolved
                animationsByTargetID = cached.animationsByTargetID
                animatedNodeIDs = Set(cached.animationsByTargetID.keys)
                animatedTransformNodeIDs = collectAnimatedTransformNodeIDs(from: cached.animations)
                animationStartDate = Date()
                pathCache = canCache.shouldCachePathCache
                    ? buildPathCache(from: cached.nodes)
                    : [:]
                clipPathCache = buildClipPathCache(from: cached.clipPaths)
                updateCachedDrawNodes(
                    from: cached,
                    resolved: resolved,
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
            let resolved = styleResolver.resolve(
                document: parsed,
                configuration: configuration
            )
            baseResolvedStyles = resolved
            animationsByTargetID = parsed.animationsByTargetID
            animatedNodeIDs = Set(parsed.animationsByTargetID.keys)
            animatedTransformNodeIDs = collectAnimatedTransformNodeIDs(from: parsed.animations)
            animationStartDate = Date()
            await cache.insert(parsed, for: key, cost: data.count)
            document = parsed
            pathCache = canCache.shouldCachePathCache
                ? buildPathCache(from: parsed.nodes)
                : [:]
            clipPathCache = buildClipPathCache(from: parsed.clipPaths)
            updateCachedDrawNodes(
                from: parsed,
                resolved: resolved,
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
            baseResolvedStyles = [:]
            animationsByTargetID = [:]
            animatedNodeIDs = []
            animatedTransformNodeIDs = []
            pathCache.removeAll()
            clipPathCache.removeAll()
            cachedConfigurationFingerprint = ""
            cachedDrawNodes.removeAll()
            staticDrawNodeLookup.removeAll()
            await refreshCacheMetrics()
        }
    }

    private var debugParsingFailureMessage: String? {
        let hasMessage = !parsingFailureMessage.isEmpty
        return hasMessage ? parsingFailureMessage : nil
    }

    private func updateCachedDrawNodes(
        from document: SVGDocument,
        resolved: [String: SVGResolvedNodeStyle],
        using fingerprint: String,
        canCache: Bool
    ) {
        if !usesStaticConfiguration || !canCache {
            cachedConfigurationFingerprint = ""
            cachedDrawNodes.removeAll()
            staticDrawNodeLookup.removeAll()
            return
        }

        cachedDrawNodes = buildDrawNodes(
            from: document.nodes,
            resolved: resolved,
            filterDefinitions: document.filterDefinitions,
            clipPathCache: clipPathCache,
            inheritedTransform: .identity,
            inheritedClipPaths: [],
            canUsePathCache: canCachePathCacheForCurrentDocument
        )
        staticDrawNodeLookup = buildDrawNodeLookup(from: cachedDrawNodes)
        cachedConfigurationFingerprint = fingerprint
    }

    private func collectAnimatedTransformNodeIDs(
        from animations: [SVGSMILAnimation]
    ) -> Set<String> {
        var output: Set<String> = []
        for animation in animations {
            let targetElementID: String = animation.targetElementID
            if animation.kind == .animateMotion {
                output.insert(targetElementID)
                continue
            }
            if let attributeName = animation.attributeName {
                let normalizedAttributeName: String = attributeName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if normalizedAttributeName == "transform" {
                    output.insert(targetElementID)
                }
            }
        }
        return output
    }

    private func buildAnimatedTargetedDrawNodes(
        from nodes: [SVGNode],
        resolved: [String: SVGResolvedNodeStyle],
        filterDefinitions: [String: SVGFilterDefinition],
        clipPathCache: [String: CGPath],
        inheritedTransform: CGAffineTransform,
        inheritedClipPaths: [CGPath],
        staticNodesByID: [String: SVGDrawNode],
        canUsePathCache: Bool
    ) -> [SVGDrawNode] {
        var output: [SVGDrawNode] = []
        for node in nodes {
            let nodeID: String = node.nodeID
            let nodeIsAnimated: Bool = animatedNodeIDs.contains(nodeID)
            let nodeTransform: CGAffineTransform = transformBuilder.concatenate(
                local: node.base.transform,
                inherited: inheritedTransform
            )
            let maybeClipPath: CGPath? = clipPath(
                from: node,
                clipPathCache: clipPathCache
            )
            var activeClipPaths: [CGPath] = inheritedClipPaths
            if let nextClipPath = maybeClipPath {
                activeClipPaths.append(nextClipPath)
            }

            if nodeIsAnimated {
                if let animatedNode = makeDrawNode(
                    for: node,
                    resolved: resolved[nodeID],
                    filterDefinitions: filterDefinitions,
                    inheritedTransform: nodeTransform,
                    canUsePathCache: canUsePathCache,
                    clipPaths: activeClipPaths
                ) {
                    output.append(animatedNode)
                }
            } else if let staticNode = staticNodesByID[nodeID] {
                output.append(staticNode)
            }

            if !node.children.isEmpty {
                let childNodes: [SVGDrawNode] = buildAnimatedTargetedDrawNodes(
                    from: node.children,
                    resolved: resolved,
                    filterDefinitions: filterDefinitions,
                    clipPathCache: clipPathCache,
                    inheritedTransform: nodeTransform,
                    inheritedClipPaths: activeClipPaths,
                    staticNodesByID: staticNodesByID,
                    canUsePathCache: canUsePathCache
                )
                output.append(contentsOf: childNodes)
            }
        }
        return output
    }

    private func buildDrawNodeLookup(
        from drawNodes: [SVGDrawNode]
    ) -> [String: SVGDrawNode] {
        var output: [String: SVGDrawNode] = [:]
        for drawNode in drawNodes {
            output[drawNode.id] = drawNode
        }
        return output
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
            let animatedTransform: CGAffineTransform? = resolved[nodeID]?.transformOverride
            let maybeClipPath = clipPath(
                from: node,
                clipPathCache: clipPathCache
            )
            var activeClipPaths: [CGPath] = inheritedClipPaths
            if let nextClipPath = maybeClipPath {
                activeClipPaths.append(nextClipPath)
            }

            let nodeTransform: CGAffineTransform = if let transformOverride = animatedTransform {
                transformOverride.concatenating(inheritedTransform)
            } else {
                transformBuilder.concatenate(
                    local: node.base.transform,
                    inherited: inheritedTransform
                )
            }

            if let built = makeDrawNode(
                for: node,
                resolved: resolved[nodeID],
                filterDefinitions: filterDefinitions,
                inheritedTransform: nodeTransform,
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

    private func textNode(from node: SVGNode) -> SVGTextNode? {
        if case .text(let textNode) = node {
            return textNode
        }
        return nil
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

        if let sourceText = textNode(from: node) {
            return makeTextDrawNode(
                for: sourceText,
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
            textContent: nil,
            textPosition: nil,
            textAnchor: .start,
            textFontFamily: nil,
            textFontStyle: .normal,
            textFontWeight: .normal,
            textFontSize: nil,
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

    private func makeTextDrawNode(
        for sourceText: SVGTextNode,
        resolved: SVGResolvedNodeStyle?,
        inheritedTransform: CGAffineTransform,
        filterDefinitions: [String: SVGFilterDefinition],
        clipPaths: [CGPath]
    ) -> SVGDrawNode? {
        guard let resolved else {
            return nil
        }
        let pathTransform: CGAffineTransform = transformBuilder.concatenate(
            local: sourceText.base.transform,
            inherited: inheritedTransform
        )
        let baseX: CGFloat = CGFloat(sourceText.x ?? 0)
        let baseY: CGFloat = CGFloat(sourceText.y ?? 0)
        let renderedPoint: CGPoint = CGPoint(x: baseX, y: baseY).applying(pathTransform)
        let filteredPoint = applyTextOverrides(
            renderedPoint,
            scale: resolved.scale,
            offset: resolved.offset
        )
        let textFontSize: CGFloat = CGFloat(resolved.style.fontSize) * CGFloat(resolved.scale?.width ?? 1)
        return SVGDrawNode(
            id: resolved.nodeID,
            path: Path(),
            textContent: sourceText.content,
            textPosition: filteredPoint,
            textAnchor: resolved.style.textAnchor,
            textFontFamily: resolved.style.fontFamily,
            textFontStyle: resolved.style.fontStyle,
            textFontWeight: resolved.style.fontWeight,
            textFontSize: textFontSize,
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
            filterPrimitives: resolveFilterPrimitives(
                from: resolved.style.filter,
                filterDefinitions: filterDefinitions
            )
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
            textContent: nil,
            textPosition: nil,
            textAnchor: .start,
            textFontFamily: nil,
            textFontStyle: .normal,
            textFontWeight: .normal,
            textFontSize: nil,
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
            case .text:
                break
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
            case .shape, .path, .text:
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

    private func applyTextOverrides(
        _ point: CGPoint,
        scale: SVGSize?,
        offset: SVGPoint?
    ) -> CGPoint {
        var output = point
        if let scale {
            output.x *= CGFloat(scale.width)
            output.y *= CGFloat(scale.height)
        }
        if let offset {
            output.x += CGFloat(offset.x)
            output.y += CGFloat(offset.y)
        }
        return output
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
    let textContent: String?
    let textPosition: CGPoint?
    let textAnchor: SVGTextAnchor
    let textFontFamily: String?
    let textFontStyle: SVGFontStyle
    let textFontWeight: SVGFontWeight
    let textFontSize: CGFloat?
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
