import Foundation

struct SVGResolvedNodeStyle: Sendable, Equatable {
    var nodeID: String
    var element: SVGElementKind
    var style: SVGResolvedStyle
    var scale: SVGSize?
    var offset: SVGPoint?

    init(
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

struct SVGStyleResolver: Sendable {
    init() {}

    func resolve(
        document: SVGDocument,
        configuration: SVGRenderConfiguration = .init()
    ) -> [String: SVGResolvedNodeStyle] {
        let viewport = resolveViewport(from: document)
        var result: [String: SVGResolvedNodeStyle] = [:]
        for node in document.nodes {
            resolveNode(
                node,
                inheritedStyle: .init(),
                styleRules: document.styleRules,
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
        styleRules: [SVGStyleRule],
        viewport: SVGSize,
        configuration: SVGRenderConfiguration,
        result: inout [String: SVGResolvedNodeStyle]
    ) {
        var stylesheetStyle = SVGStyle()
        for stylesheet in matchingRules(for: node, in: styleRules) {
            apply(styleDeclarations: stylesheet.declarations, to: &stylesheetStyle)
        }

        var style = inheritedStyle
            .applying(style: stylesheetStyle)
            .applying(style: node.base.style)

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
                styleRules: styleRules,
                viewport: viewport,
                configuration: configuration,
                result: &result
            )
        }
    }

    private func matchingRules(for node: SVGNode, in styleRules: [SVGStyleRule]) -> [SVGStyleRule] {
        var candidates: [(specificity: Int, order: Int, rule: SVGStyleRule)] = []

        for (index, rule) in styleRules.enumerated() {
            if matches(node: node, selector: rule.selector) {
                let selectorWeight = specificity(for: rule.selector)
                candidates.append((selectorWeight, index, rule))
            }
        }

        let sorted = candidates.sorted { first, second in
            if first.specificity == second.specificity {
                return first.order < second.order
            }
            return first.specificity < second.specificity
        }
        return sorted.map(\.rule)
    }

    private func matches(node: SVGNode, selector: SVGStyleSelector) -> Bool {
        switch selector {
        case .any:
            return true
        case .id(let id):
            return node.base.id == id
        case .class(let targetClass):
            let classNames = parseClassNames(from: node.base.attributes["class"])
            return classNames.contains(targetClass)
        case .element(let elementName):
            return elementName == node.elementKind.rawValue
        }
    }

    private func parseClassNames(from value: String?) -> Set<String> {
        guard let rawClass = value else {
            return []
        }
        let values = rawClass.split(whereSeparator: \.isWhitespace)
        return Set(values.map(String.init))
    }

    private func specificity(for selector: SVGStyleSelector) -> Int {
        switch selector {
        case .id:
            return 100
        case .class:
            return 10
        case .element:
            return 1
        case .any:
            return 0
        }
    }

    private func apply(
        styleDeclarations: [String: String],
        to style: inout SVGStyle
    ) {
        for (rawKey, rawValue) in styleDeclarations {
            let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedValue = removeImportantSuffix(from: rawValue)
            switch key {
            case "fill":
                style.fill = parsePaint(normalizedValue)
            case "fill-opacity":
                style.fillOpacity = parseNumeric(normalizedValue)
            case "fill-rule":
                style.fillRule = parseFillRule(normalizedValue)
            case "stroke":
                style.stroke = parsePaint(normalizedValue)
            case "stroke-opacity":
                style.strokeOpacity = parseNumeric(normalizedValue)
            case "stroke-width":
                style.strokeWidth = parseNumeric(normalizedValue)
            case "stroke-miterlimit":
                style.strokeMiterLimit = parseNumeric(normalizedValue)
            case "stroke-dasharray":
                style.strokeDashArray = parseDashArray(normalizedValue)
            case "stroke-dashoffset":
                style.strokeDashOffset = parseNumeric(normalizedValue)
            case "stroke-linecap":
                style.strokeLineCap = parseStrokeLineCap(normalizedValue)
            case "stroke-linejoin":
                style.strokeLineJoin = parseStrokeLineJoin(normalizedValue)
            case "filter":
                style.filter = normalizedValue
            case "opacity":
                style.opacity = parseNumeric(normalizedValue)
            case "font-size":
                style.fontSize = parseNumeric(normalizedValue)
            case "font-family":
                if let parsedFontFamily = parseFontFamily(normalizedValue) {
                    style.fontFamily = parsedFontFamily
                }
            case "text-anchor":
                style.textAnchor = parseTextAnchor(normalizedValue)
            case "font-style":
                style.fontStyle = parseFontStyle(normalizedValue)
            case "font-weight":
                style.fontWeight = parseFontWeight(normalizedValue)
            default:
                continue
            }
        }
    }

    private func parseFontFamily(_ value: String) -> String? {
        let normalizedValue: String = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates: [Substring] = normalizedValue.split(separator: ",", omittingEmptySubsequences: true)
        for rawCandidate in candidates {
            let trimmed = rawCandidate.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidate = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !candidate.isEmpty {
                return candidate
            }
        }
        return nil
    }

    private func parseFontStyle(_ value: String) -> SVGFontStyle {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        case "italic":
            return .italic
        case "oblique":
            return .oblique
        default:
            return .normal
        }
    }

    private func parseFontWeight(_ value: String) -> SVGFontWeight {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        case "normal":
            return .normal
        case "bold":
            return .bold
        case "bolder":
            return .bolder
        case "lighter":
            return .lighter
        default:
            if let number = Int(normalized), (1...1000).contains(number) {
                return .numeric(number)
            }
            return .normal
        }
    }

    private func parseTextAnchor(_ value: String) -> SVGTextAnchor {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "middle":
            return .middle
        case "end":
            return .end
        default:
            return .start
        }
    }

    private func removeImportantSuffix(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()
        let suffix = "!important"
        guard lowered.hasSuffix(suffix) else {
            return trimmed
        }
        let cutPoint = trimmed.index(trimmed.endIndex, offsetBy: -suffix.count)
        let withoutSuffix = String(trimmed[..<cutPoint])
        return withoutSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseNumeric(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
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

    private func parseStrokeLineCap(_ value: String) -> SVGLineCap? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "butt":
            return .butt
        case "round":
            return .round
        case "square":
            return .square
        default:
            return nil
        }
    }

    private func parseStrokeLineJoin(_ value: String) -> SVGLineJoin? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "miter":
            return .miter
        case "round":
            return .round
        case "bevel":
            return .bevel
        default:
            return nil
        }
    }

    private func parseFillRule(_ value: String) -> SVGFillRule? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "nonzero", "non-zero":
            return .nonZero
        case "evenodd", "even-odd":
            return .evenOdd
        default:
            return nil
        }
    }

    private func parseDashArray(_ value: String) -> [Double]? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if trimmed.lowercased() == "none" {
            return []
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: " ")
        let numericValues = normalized
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .compactMap { Double($0) }
        if numericValues.isEmpty {
            return nil
        }
        return numericValues
    }

    private func parsePaint(_ value: String) -> SVGPaint? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return nil
        }
        if normalized == "none" {
            return SVGPaint.none
        }
        if normalized == "currentColor".lowercased() {
            return .currentColor
        }
        if let hexColor = parseHexColor(normalized) {
            return .color(hexColor)
        }
        if let rgbColor = parseRGBColor(normalized) {
            return .color(rgbColor)
        }
        if let namedColor = parseNamedColor(normalized) {
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
            let expanded = String(hex.flatMap { [$0, $0] })
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
        let startIndex = value.index(value.startIndex, offsetBy: 4)
        let endIndex = value.index(before: value.endIndex)
        let body = value[startIndex..<endIndex]
        let parts = body.split(separator: ",")
        guard parts.count == 3 else {
            return nil
        }
        let numbers = parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard
            let red = Double(numbers[0]),
            let green = Double(numbers[1]),
            let blue = Double(numbers[2])
        else {
            return nil
        }
        return SVGColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
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
        if let fontSize = override.fontSize {
            style.fontSize = fontSize
        }
        if let fontFamily = override.fontFamily {
            style.fontFamily = fontFamily
        }
        if let textAnchor = override.textAnchor {
            style.textAnchor = textAnchor
        }
        if let fontStyle = override.fontStyle {
            style.fontStyle = fontStyle
        }
        if let fontWeight = override.fontWeight {
            style.fontWeight = fontWeight
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
