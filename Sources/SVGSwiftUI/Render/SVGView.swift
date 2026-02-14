#if canImport(SwiftUI)
import CoreGraphics
import SwiftUI

public struct SVGView: View {
    private let source: SVGSource
    private let parser: SVGParser
    private let cache: SVGParseCache?
    private let configuration: SVGRenderConfiguration
    private let options: SVGParserOptions

    public init(
        source: SVGSource,
        parser: SVGParser = .init(),
        cache: SVGParseCache? = nil,
        options: SVGParserOptions = .init(),
        configuration: SVGRenderConfiguration = .init()
    ) {
        self.source = source
        self.parser = parser
        self.cache = cache
        self.options = options
        self.configuration = configuration
    }

    public var body: some View {
        SVGStaticPlaceholderView(source: source, parser: parser, cache: cache, options: options, configuration: configuration)
    }
}

private struct SVGStaticPlaceholderView: View {
    struct ParseTaskID: Equatable {
        let source: SVGSource
        let options: SVGParserOptions
    }

    let source: SVGSource
    let parser: SVGParser
    let cache: SVGParseCache?
    let options: SVGParserOptions
    let configuration: SVGRenderConfiguration

    @State private var parsingFailed = false
    @State private var document: SVGDocument?

    private let styleResolver = SVGStyleResolver()
    private let nodePathBuilder = SVGNodePathBuilder()

    private var drawNodes: [SVGDrawNode] {
        guard let document else {
            return []
        }
        let resolved = styleResolver.resolve(document: document, configuration: configuration)
        return buildDrawNodes(from: document.nodes, resolved: resolved)
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, _ in
                for node in drawNodes {
                    let opacity = node.opacity
                    if let fill = node.fillColor {
                        context.fill(node.path, with: .color(fill.opacity(opacity)))
                    }
                    if let stroke = node.strokeColor, node.strokeWidth > 0 {
                        let strokeStyle = StrokeStyle(
                            lineWidth: node.strokeWidth,
                            lineCap: node.lineCap,
                            lineJoin: node.lineJoin
                        )
                        context.stroke(node.path, with: .color(stroke.opacity(opacity)), style: strokeStyle)
                    }
                }
            }
            .overlay(alignment: .center) {
                if parsingFailed {
                    Text("Invalid SVG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .task(id: ParseTaskID(source: source, options: options)) {
                await loadDocument()
            }
        }
    }

    @MainActor
    private func loadDocument() async {
        do {
            let data = try source.loadData()
            if let cache {
                let key = SVGParseCacheKey.from(sourceData: data, options: options)
                if let cached = await cache.document(for: key) {
                    document = cached
                    parsingFailed = false
                    return
                }
                let parsed = try parser.parse(data: data, options: options)
                await cache.insert(parsed, for: key, cost: data.count)
                document = parsed
            } else {
                document = try parser.parse(data: data, options: options)
            }
            parsingFailed = false
        } catch {
            parsingFailed = true
            document = nil
        }
    }

    private func buildDrawNodes(
        from nodes: [SVGNode],
        resolved: [String: SVGResolvedNodeStyle]
    ) -> [SVGDrawNode] {
        var output: [SVGDrawNode] = []
        for node in nodes {
            if let built = makeDrawNode(for: node, resolved: resolved[node.nodeID]) {
                output.append(built)
            }
            if !node.children.isEmpty {
                output.append(contentsOf: buildDrawNodes(from: node.children, resolved: resolved))
            }
        }
        return output
    }

    private func makeDrawNode(for node: SVGNode, resolved: SVGResolvedNodeStyle?) -> SVGDrawNode? {
        guard let resolved else {
            return nil
        }
        guard var cgPath = nodePathBuilder.buildPath(for: node) else {
            return nil
        }
        cgPath = applyGeometryOverrides(cgPath, scale: resolved.scale, offset: resolved.offset)
        let path = Path(cgPath)

        return SVGDrawNode(
            id: resolved.nodeID,
            path: path,
            fillColor: color(from: resolved.style.fill),
            strokeColor: color(from: resolved.style.stroke),
            strokeWidth: CGFloat(resolved.style.strokeWidth),
            lineCap: lineCap(from: resolved.style.strokeLineCap),
            lineJoin: lineJoin(from: resolved.style.strokeLineJoin),
            opacity: resolved.style.opacity
        )
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
}

private struct SVGDrawNode: Identifiable {
    let id: String
    let path: Path
    let fillColor: Color?
    let strokeColor: Color?
    let strokeWidth: CGFloat
    let lineCap: CGLineCap
    let lineJoin: CGLineJoin
    let opacity: Double
}
#endif
