#if canImport(SwiftUI)
import SwiftUI

public struct SVGView: View {
    private let source: SVGSource
    private let parser: SVGParser
    private let configuration: SVGRenderConfiguration
    private let options: SVGParserOptions

    public init(
        source: SVGSource,
        parser: SVGParser = .init(),
        options: SVGParserOptions = .init(),
        configuration: SVGRenderConfiguration = .init()
    ) {
        self.source = source
        self.parser = parser
        self.options = options
        self.configuration = configuration
    }

    public var body: some View {
        SVGStaticPlaceholderView(source: source, parser: parser, options: options, configuration: configuration)
    }
}

private struct SVGStaticPlaceholderView: View {
    let source: SVGSource
    let parser: SVGParser
    let options: SVGParserOptions
    let configuration: SVGRenderConfiguration

    @State private var parsingFailed = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: proxy.size))
                }
                .fill(.clear)

                if parsingFailed {
                    Text("Invalid SVG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .task(id: proxy.size) {
                _ = configuration
                do {
                    _ = try parser.parse(source: source, options: options)
                    parsingFailed = false
                } catch {
                    parsingFailed = true
                }
            }
        }
    }
}
#endif
