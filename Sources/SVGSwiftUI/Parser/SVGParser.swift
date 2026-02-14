import Foundation

public protocol SVGDocumentParsing: Sendable {
    func parse(source: SVGSource, options: SVGParserOptions) throws -> SVGDocument
}

public struct SVGParser: SVGDocumentParsing, Sendable {
    public init() {}

    public func parse(source: SVGSource, options: SVGParserOptions = .init()) throws -> SVGDocument {
        let data = try source.loadData()
        return try parse(data: data, options: options)
    }

    public func parse(data: Data, options: SVGParserOptions = .init()) throws -> SVGDocument {
        guard !data.isEmpty else {
            throw SVGParserError.emptyInput
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw SVGParserError.invalidUTF8Input
        }

        guard text.localizedCaseInsensitiveContains("<svg") else {
            throw SVGParserError.invalidSVGRoot
        }

        let xmlParser = SVGXMLDocumentParser(options: options)
        return try xmlParser.parse(data: data)
    }
}

private final class SVGXMLDocumentParser: NSObject, XMLParserDelegate {
    private enum FrameKind {
        case svg
        case group
        case path
        case shape(SVGElementKind)
    }

    private struct Frame {
        var kind: FrameKind
        var base: SVGBaseNode
        var attributes: [String: String]
        var children: [SVGNode]
        var childCount: Int
    }

    private let options: SVGParserOptions
    private let pathDataParser = SVGPathDataParser()
    private var frames: [Frame] = []
    private var ignoreDepth: Int = 0
    private var parseError: SVGParserError?
    private var rootDocument: SVGDocument?

    init(options: SVGParserOptions) {
        self.options = options
    }

    func parse(data: Data) throws -> SVGDocument {
        frames.removeAll()
        ignoreDepth = 0
        parseError = nil
        rootDocument = nil

        let parser = XMLParser(data: data)
        parser.delegate = self

        let success = parser.parse()
        if !success {
            if let parseError {
                throw parseError
            }
            if let parserError = parser.parserError {
                throw SVGParserError.malformedDocument(reason: parserError.localizedDescription)
            }
            throw SVGParserError.malformedDocument(reason: "Unknown XML parser failure")
        }
        if let parseError {
            throw parseError
        }
        guard let rootDocument else {
            throw SVGParserError.invalidSVGRoot
        }
        return rootDocument
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if parseError != nil {
            return
        }
        if ignoreDepth > 0 {
            ignoreDepth += 1
            return
        }

        let normalizedName = normalizeName(elementName)
        guard let frameKind = frameKind(for: normalizedName, stackDepth: frames.count) else {
            ignoreDepth = 1
            return
        }

        let syntheticID = makeSyntheticID(parentDepth: frames.count)
        let base = SVGBaseNode(
            id: attributeDict["id"],
            syntheticID: syntheticID,
            style: parseStyle(attributes: attributeDict),
            transform: parseTransform(attributes: attributeDict),
            attributes: attributeDict
        )

        frames.append(
            Frame(
                kind: frameKind,
                base: base,
                attributes: attributeDict,
                children: [],
                childCount: 0
            )
        )
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if parseError != nil {
            return
        }
        if ignoreDepth > 0 {
            ignoreDepth -= 1
            return
        }
        guard !frames.isEmpty else {
            parseError = .malformedDocument(reason: "Encountered closing tag without open frame: \(elementName)")
            parser.abortParsing()
            return
        }

        let normalizedName = normalizeName(elementName)
        let frame = frames.removeLast()
        let frameElementName = elementNameForKind(frame.kind)
        if frameElementName != normalizedName {
            parseError = .malformedDocument(reason: "Mismatched closing tag for \(normalizedName)")
            parser.abortParsing()
            return
        }

        switch frame.kind {
        case .svg:
            rootDocument = SVGDocument(
                size: parseRootSize(attributes: frame.attributes),
                viewBox: parseViewBox(attributes: frame.attributes),
                nodes: frame.children
            )
        case .group:
            appendNode(.group(.init(base: frame.base, children: frame.children)), parser: parser)
        case .path:
            let pathData = frame.attributes["d"] ?? ""
            do {
                let commands = try pathDataParser.parse(pathData)
                appendNode(.path(.init(base: frame.base, pathData: pathData, commands: commands)), parser: parser)
            } catch {
                parseError = .malformedDocument(reason: "Invalid path data: \(pathData)")
                parser.abortParsing()
            }
        case .shape(let kind):
            appendNode(buildShapeNode(kind: kind, frame: frame), parser: parser)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if self.parseError == nil {
            self.parseError = .malformedDocument(reason: parseError.localizedDescription)
        }
    }

    private func appendNode(_ node: SVGNode, parser: XMLParser) {
        guard !frames.isEmpty else {
            parseError = .malformedDocument(reason: "Node encountered outside root")
            parser.abortParsing()
            return
        }
        var parent = frames.removeLast()
        parent.children.append(node)
        frames.append(parent)
    }

    private func frameKind(for name: String, stackDepth: Int) -> FrameKind? {
        switch name {
        case "svg":
            return stackDepth == 0 ? .svg : nil
        case "g":
            return .group
        case "path":
            return .path
        case "rect":
            return .shape(.rect)
        case "circle":
            return .shape(.circle)
        case "ellipse":
            return .shape(.ellipse)
        case "line":
            return .shape(.line)
        case "polyline":
            return .shape(.polyline)
        case "polygon":
            return .shape(.polygon)
        default:
            return nil
        }
    }

    private func elementNameForKind(_ kind: FrameKind) -> String {
        switch kind {
        case .svg:
            return "svg"
        case .group:
            return "g"
        case .path:
            return "path"
        case .shape(let shapeKind):
            return shapeKind.rawValue
        }
    }

    private func normalizeName(_ name: String) -> String {
        if let last = name.split(separator: ":").last {
            return String(last).lowercased()
        }
        return name.lowercased()
    }

    private func makeSyntheticID(parentDepth: Int) -> String {
        if parentDepth == 0 {
            return "auto:/0"
        }
        guard var parent = frames.last else {
            return "auto:/0"
        }
        let path = parent.base.syntheticID.replacingOccurrences(of: "auto:", with: "")
        let next = parent.childCount
        parent.childCount += 1
        frames[frames.count - 1] = parent
        return "auto:\(path)/\(next)"
    }

    private func parseRootSize(attributes: [String: String]) -> SVGSize? {
        guard
            let widthText = attributes["width"],
            let heightText = attributes["height"],
            let width = parseNumeric(widthText),
            let height = parseNumeric(heightText)
        else {
            return nil
        }
        return SVGSize(width: width, height: height)
    }

    private func parseViewBox(attributes: [String: String]) -> SVGRect? {
        guard let viewBoxString = attributes["viewBox"] ?? attributes["viewbox"] else {
            return nil
        }
        let numbers = viewBoxString
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { Double($0) }
        guard numbers.count == 4 else {
            return nil
        }
        return SVGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
    }

    private func buildShapeNode(kind: SVGElementKind, frame: Frame) -> SVGNode {
        var values: [String: Double] = [:]
        for (key, value) in frame.attributes {
            if let numeric = parseNumeric(value) {
                values[key] = numeric
            }
        }
        let points: [SVGPoint]
        if kind == .polyline || kind == .polygon {
            points = parsePoints(frame.attributes["points"] ?? "")
        } else {
            points = []
        }
        return .shape(.init(base: frame.base, kind: kind, values: values, points: points))
    }

    private func parsePoints(_ input: String) -> [SVGPoint] {
        let compact = input.replacingOccurrences(of: ",", with: " ")
        let numbers = compact.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).compactMap { Double($0) }
        var output: [SVGPoint] = []
        var index = 0
        while index + 1 < numbers.count {
            output.append(SVGPoint(x: numbers[index], y: numbers[index + 1]))
            index += 2
        }
        return output
    }

    private func parseNumeric(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        if trimmed.hasSuffix("px") {
            return Double(trimmed.dropLast(2))
        }
        if trimmed.hasSuffix("%") {
            return nil
        }
        return Double(trimmed)
    }

    private func parseStyle(attributes: [String: String]) -> SVGStyle {
        var style = SVGStyle()
        applyStyleAttribute(attributes: attributes, to: &style)
        if let inlineStyle = attributes["style"] {
            applyInlineStyle(inlineStyle, to: &style)
        }
        return style
    }

    private func applyStyleAttribute(attributes: [String: String], to style: inout SVGStyle) {
        if let fill = attributes["fill"] {
            style.fill = parsePaint(fill)
        }
        if let fillOpacity = attributes["fill-opacity"] {
            style.fillOpacity = parseNumeric(fillOpacity)
        }
        if let stroke = attributes["stroke"] {
            style.stroke = parsePaint(stroke)
        }
        if let strokeOpacity = attributes["stroke-opacity"] {
            style.strokeOpacity = parseNumeric(strokeOpacity)
        }
        if let strokeWidth = attributes["stroke-width"] {
            style.strokeWidth = parseNumeric(strokeWidth)
        }
        if let opacity = attributes["opacity"] {
            style.opacity = parseNumeric(opacity)
        }
    }

    private func applyInlineStyle(_ inline: String, to style: inout SVGStyle) {
        let declarations = inline.split(separator: ";")
        for declaration in declarations {
            let pair = declaration.split(separator: ":", maxSplits: 1).map(String.init)
            guard pair.count == 2 else {
                continue
            }
            let key = pair[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = pair[1].trimmingCharacters(in: .whitespacesAndNewlines)
            switch key {
            case "fill":
                style.fill = parsePaint(value)
            case "fill-opacity":
                style.fillOpacity = parseNumeric(value)
            case "stroke":
                style.stroke = parsePaint(value)
            case "stroke-opacity":
                style.strokeOpacity = parseNumeric(value)
            case "stroke-width":
                style.strokeWidth = parseNumeric(value)
            case "opacity":
                style.opacity = parseNumeric(value)
            default:
                continue
            }
        }
    }

    private func parsePaint(_ value: String) -> SVGPaint? {
        let lowered = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lowered.isEmpty else {
            return nil
        }
        if lowered == "none" {
            return SVGPaint.none
        }
        if lowered == "currentcolor" {
            return .currentColor
        }
        if let hexColor = parseHexColor(lowered) {
            return .color(hexColor)
        }
        if let rgbColor = parseRGBColor(lowered) {
            return .color(rgbColor)
        }
        if let namedColor = parseNamedColor(lowered) {
            return .color(namedColor)
        }
        return nil
    }

    private func parseHexColor(_ value: String) -> SVGColor? {
        guard value.hasPrefix("#") else {
            return nil
        }
        let hex = String(value.dropFirst())
        if hex.count == 3 {
            let chars = Array(hex)
            let expanded = String(chars.flatMap { [$0, $0] })
            return parseHexColor("#\(expanded)")
        }
        guard hex.count == 6, let int = Int(hex, radix: 16) else {
            return nil
        }
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        return SVGColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    private func parseRGBColor(_ value: String) -> SVGColor? {
        guard value.hasPrefix("rgb("), value.hasSuffix(")") else {
            return nil
        }
        let start = value.index(value.startIndex, offsetBy: 4)
        let body = value[start..<value.index(before: value.endIndex)]
        let numbers = body.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard numbers.count == 3 else {
            return nil
        }
        guard
            let r = Double(numbers[0]),
            let g = Double(numbers[1]),
            let b = Double(numbers[2])
        else {
            return nil
        }
        return SVGColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
    }

    private func parseNamedColor(_ value: String) -> SVGColor? {
        switch value {
        case "black":
            return SVGColor(red: 0, green: 0, blue: 0, alpha: 1)
        case "white":
            return SVGColor(red: 1, green: 1, blue: 1, alpha: 1)
        case "red":
            return SVGColor(red: 1, green: 0, blue: 0, alpha: 1)
        case "green":
            return SVGColor(red: 0, green: 1, blue: 0, alpha: 1)
        case "blue":
            return SVGColor(red: 0, green: 0, blue: 1, alpha: 1)
        default:
            return nil
        }
    }

    private func parseTransform(attributes: [String: String]) -> SVGTransform {
        guard let raw = attributes["transform"] else {
            return .identity
        }
        let normalized = raw.replacingOccurrences(of: ",", with: " ")
        let parts = normalized.split(separator: ")")
        var operations: [SVGTransform.Operation] = []
        for part in parts {
            let item = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !item.isEmpty else {
                continue
            }
            guard let leftParenIndex = item.firstIndex(of: "(") else {
                continue
            }
            let name = String(item[..<leftParenIndex]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let valuesText = item[item.index(after: leftParenIndex)...]
            let values = valuesText.split(whereSeparator: { $0 == " " || $0 == "\t" }).compactMap { Double($0) }
            switch name {
            case "translate":
                if values.count == 1 {
                    operations.append(.translate(tx: values[0], ty: 0))
                } else if values.count >= 2 {
                    operations.append(.translate(tx: values[0], ty: values[1]))
                }
            case "scale":
                if values.count == 1 {
                    operations.append(.scale(sx: values[0], sy: values[0]))
                } else if values.count >= 2 {
                    operations.append(.scale(sx: values[0], sy: values[1]))
                }
            case "rotate":
                if values.count == 1 {
                    operations.append(.rotate(angleDegrees: values[0], cx: nil, cy: nil))
                } else if values.count >= 3 {
                    operations.append(.rotate(angleDegrees: values[0], cx: values[1], cy: values[2]))
                }
            case "matrix":
                if values.count >= 6 {
                    operations.append(
                        .matrix(
                            a: values[0],
                            b: values[1],
                            c: values[2],
                            d: values[3],
                            tx: values[4],
                            ty: values[5]
                        )
                    )
                }
            default:
                continue
            }
        }
        return SVGTransform(operations: operations)
    }
}
