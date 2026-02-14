import Foundation

public protocol SVGDocumentParsing: Sendable {
    func parse(source: SVGSource, options: SVGParserOptions) throws -> SVGDocument
}

public struct SVGParser: SVGDocumentParsing, Sendable {
    public init() {}

    public func parse(source: SVGSource, options: SVGParserOptions = .init()) throws -> SVGDocument {
        let data = try source.loadData()
        guard !data.isEmpty else {
            throw SVGParserError.emptyInput
        }

        guard var text = String(data: data, encoding: .utf8) else {
            throw SVGParserError.invalidUTF8Input
        }

        if options.normalizeWhitespace {
            text = text.replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
        }

        guard text.localizedCaseInsensitiveContains("<svg") else {
            throw SVGParserError.invalidSVGRoot
        }

        // P1 skeleton: returns a document shell until XML tokenization is implemented.
        return SVGDocument()
    }
}
