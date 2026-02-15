import Foundation

protocol SVGDocumentParsing: Sendable {
    func parse(source: SVGSource, options: SVGParserOptions) throws -> SVGDocument
}

private final class SVGEmbeddedImageState {
    var embeddedImageCount: Int = 0
    var currentEmbeddedDepth: Int = 0
    let maxEmbeddedImageCount: Int
    let maxEmbeddedImageDepth: Int

    init(maxEmbeddedImageCount: Int, maxEmbeddedImageDepth: Int) {
        self.maxEmbeddedImageCount = maxEmbeddedImageCount
        self.maxEmbeddedImageDepth = maxEmbeddedImageDepth
    }

    func canEmbedAnother() -> Bool {
        if maxEmbeddedImageCount <= 0 {
            return false
        }
        if maxEmbeddedImageDepth <= 0 {
            return false
        }
        if embeddedImageCount >= maxEmbeddedImageCount {
            return false
        }
        if currentEmbeddedDepth >= maxEmbeddedImageDepth {
            return false
        }
        return true
    }

    func beginEmbedding() -> Bool {
        if !canEmbedAnother() {
            return false
        }
        embeddedImageCount += 1
        currentEmbeddedDepth += 1
        return true
    }

    func endEmbedding(succeeded: Bool) {
        if currentEmbeddedDepth > 0 {
            currentEmbeddedDepth -= 1
        }
        if !succeeded && embeddedImageCount > 0 {
            embeddedImageCount -= 1
        }
    }
}

private let embeddedImageSourceAttribute = "__svgswiftui_embeddedImageSource"

struct SVGParser: SVGDocumentParsing, Sendable {
    private let dataURIParser = SVGDataURIParser()

    init() {}

    func parseDataURI(_ uri: String, options: SVGParserOptions = .init()) throws -> SVGDataURIPayload {
        guard options.enableDataURI else {
            throw SVGParserError.notImplemented(reason: "Data URI parsing is disabled")
        }

        guard options.maxDataURIBytes > 0 else {
            throw SVGParserError.notImplemented(reason: "maxDataURIBytes must be greater than 0")
        }

        return try dataURIParser.parse(uri, maxBytes: options.maxDataURIBytes)
    }

    func parse(source: SVGSource, options: SVGParserOptions = .init()) throws -> SVGDocument {
        let data = try source.loadData()
        return try parse(data: data, options: options)
    }

    func parse(data: Data, options: SVGParserOptions = .init()) throws -> SVGDocument {
        let state = SVGEmbeddedImageState(
            maxEmbeddedImageCount: options.maxEmbeddedImageCount,
            maxEmbeddedImageDepth: options.maxEmbeddedImageDepth
        )
        return try parse(data: data, options: options, embeddedImageState: state)
    }

    fileprivate func parse(
        data: Data,
        options: SVGParserOptions,
        embeddedImageState: SVGEmbeddedImageState
    ) throws -> SVGDocument {
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
        let parsedDocument = try xmlParser.parse(data: data)
        let expandedNodes = try expandEmbeddedImageNodes(
            in: parsedDocument.nodes,
            options: options,
            state: embeddedImageState
        )
        return SVGDocument(
            size: parsedDocument.size,
            viewBox: parsedDocument.viewBox,
            nodes: expandedNodes,
            styleRules: parsedDocument.styleRules,
            clipPaths: parsedDocument.clipPaths,
            filterDefinitions: parsedDocument.filterDefinitions
        )
    }

    private func expandEmbeddedImageNodes(
        in nodes: [SVGNode],
        options: SVGParserOptions,
        state: SVGEmbeddedImageState
    ) throws -> [SVGNode] {
        var output: [SVGNode] = []
        for node in nodes {
            output.append(contentsOf: try expandEmbeddedImageNode(node, options: options, state: state))
        }
        return output
    }

    private func expandEmbeddedImageNode(
        _ node: SVGNode,
        options: SVGParserOptions,
        state: SVGEmbeddedImageState
    ) throws -> [SVGNode] {
        switch node {
        case .group(let sourceGroup):
            if let embeddedSource = sourceGroup.base.attributes[embeddedImageSourceAttribute] {
                if let expandedChildren = try parseEmbeddedImageChildren(
                    source: embeddedSource,
                    parentSyntheticID: sourceGroup.base.syntheticID,
                    options: options,
                    state: state
                ) {
                    return [.group(.init(base: sourceGroup.base, children: expandedChildren))]
                }
                switch options.imageNodePolicy {
                case .ignore:
                    return []
                case .renderRaster:
                    return [makeRasterImageNode(for: sourceGroup)]
                case .failOnRaster:
                    let message = "Unsupported raster image policy: failOnRaster"
                    throw SVGParserError.notImplemented(reason: message)
                }
            }
            let children = try expandEmbeddedImageNodes(
                in: sourceGroup.children,
                options: options,
                state: state
            )
            return [.group(.init(base: sourceGroup.base, children: children))]
        case .path(let sourcePath):
            return [.path(.init(
                base: sourcePath.base,
                pathData: sourcePath.pathData,
                commands: sourcePath.commands
            ))]
        case .shape(let sourceShape):
            return [.shape(.init(
                base: sourceShape.base,
                kind: sourceShape.kind,
                values: sourceShape.values,
                points: sourceShape.points
            ))]
        case .rasterImage:
            return [node]
        }
    }

    private func parseEmbeddedImageChildren(
        source: String,
        parentSyntheticID: String,
        options: SVGParserOptions,
        state: SVGEmbeddedImageState
    ) throws -> [SVGNode]? {
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSource.hasPrefix("data:") else {
            return nil
        }

        let payload: SVGDataURIPayload
        do {
            payload = try parseDataURI(normalizedSource, options: options)
        } catch {
            switch options.imageNodePolicy {
            case .failOnRaster:
                throw SVGParserError.notImplemented(reason: "Failed to parse data URI in raster image node")
            case .ignore, .renderRaster:
                return nil
            }
        }

        let loweredMediaType = payload.mediaType.lowercased()
        guard loweredMediaType.hasPrefix("image/svg+xml") else {
            switch options.imageNodePolicy {
            case .ignore:
                return nil
            case .renderRaster:
                return nil
            case .failOnRaster:
                let reason = "Data URI is not an embedded SVG image"
                throw SVGParserError.notImplemented(reason: reason)
            }
        }

        if !state.beginEmbedding() {
            switch options.imageNodePolicy {
            case .ignore, .renderRaster:
                return nil
            case .failOnRaster:
                return nil
            }
        }

        var didEmbed = false
        defer { state.endEmbedding(succeeded: didEmbed) }

        let embeddedDocument: SVGDocument
        do {
            embeddedDocument = try parse(
                data: payload.data,
                options: options,
                embeddedImageState: state
            )
            didEmbed = true
        } catch {
            return nil
        }
        if embeddedDocument.nodes.isEmpty {
            return nil
        }

        return rebaseEmbeddedNodes(embeddedDocument.nodes, parentSyntheticID: parentSyntheticID)
    }

    private func makeRasterImageNode(for sourceGroup: SVGGroupNode) -> SVGNode {
        let source = sourceGroup.base.attributes[embeddedImageSourceAttribute] ?? ""
        let sourceMediaType = parseDataURIMediaType(from: source)
        let x = parseNumeric(sourceGroup.base.attributes["x"])
        let y = parseNumeric(sourceGroup.base.attributes["y"])
        let width = parseNumeric(sourceGroup.base.attributes["width"])
        let height = parseNumeric(sourceGroup.base.attributes["height"])

        return .rasterImage(.init(
            base: sourceGroup.base,
            x: x,
            y: y,
            width: width,
            height: height,
            mediaType: sourceMediaType
        ))
    }

    private func parseDataURIMediaType(from source: String) -> String? {
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSource.hasPrefix("data:") else {
            return nil
        }
        guard let commaIndex = normalizedSource.firstIndex(of: ",") else {
            return nil
        }
        let payloadStartIndex = normalizedSource.index(
            normalizedSource.startIndex,
            offsetBy: "data:".count
        )
        let metadata = String(normalizedSource[payloadStartIndex..<commaIndex])
        let mediaTypePart = metadata.split(separator: ";").first
        guard let rawMediaType = mediaTypePart, !rawMediaType.isEmpty else {
            return nil
        }
        return rawMediaType.lowercased()
    }

    private func parseNumeric(_ value: String?) -> Double? {
        guard let value else {
            return nil
        }

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

    private func rebaseEmbeddedNodes(
        _ nodes: [SVGNode],
        parentSyntheticID: String
    ) -> [SVGNode] {
        let parentSuffix = parentEmbeddedSuffix(from: parentSyntheticID)
        return nodes.map { rebaseEmbeddedNode($0, parentSyntheticSuffix: parentSuffix) }
    }

    private func rebaseEmbeddedNode(
        _ node: SVGNode,
        parentSyntheticSuffix: String
    ) -> SVGNode {
        switch node {
        case .group(let sourceGroup):
            let base = rebaseSyntheticID(in: sourceGroup.base, parentSuffix: parentSyntheticSuffix)
            let children = sourceGroup.children.map {
                rebaseEmbeddedNode($0, parentSyntheticSuffix: parentSyntheticSuffix)
            }
            return .group(.init(base: base, children: children))
        case .path(let sourcePath):
            let base = rebaseSyntheticID(in: sourcePath.base, parentSuffix: parentSyntheticSuffix)
            return .path(.init(base: base, pathData: sourcePath.pathData, commands: sourcePath.commands))
        case .shape(let sourceShape):
            let base = rebaseSyntheticID(in: sourceShape.base, parentSuffix: parentSyntheticSuffix)
            return .shape(
                .init(
                    base: base,
                    kind: sourceShape.kind,
                    values: sourceShape.values,
                    points: sourceShape.points
                )
            )
        case .rasterImage(let sourceRasterImage):
            let base = rebaseSyntheticID(in: sourceRasterImage.base, parentSuffix: parentSyntheticSuffix)
            return .rasterImage(
                .init(
                    base: base,
                    x: sourceRasterImage.x,
                    y: sourceRasterImage.y,
                    width: sourceRasterImage.width,
                    height: sourceRasterImage.height,
                    mediaType: sourceRasterImage.mediaType
                )
            )
        }
    }

    private func rebaseSyntheticID(in sourceBase: SVGBaseNode, parentSuffix: String) -> SVGBaseNode {
        let childSuffix = embeddedChildSuffix(from: sourceBase.syntheticID)
        let rebasedID = "auto:\(parentSuffix)/embedded\(childSuffix)"
        return SVGBaseNode(
            id: sourceBase.id,
            syntheticID: rebasedID,
            style: sourceBase.style,
            transform: sourceBase.transform,
            attributes: sourceBase.attributes
        )
    }

    private func parentEmbeddedSuffix(from syntheticID: String) -> String {
        let prefix = "auto:"
        guard syntheticID.hasPrefix(prefix) else {
            return "/\(syntheticID)"
        }
        let startIndex = syntheticID.index(syntheticID.startIndex, offsetBy: prefix.count)
        return String(syntheticID[startIndex...])
    }

    private func embeddedChildSuffix(from syntheticID: String) -> String {
        let prefix = "auto:"
        guard syntheticID.hasPrefix(prefix) else {
            return "/\(syntheticID)"
        }
        let startIndex = syntheticID.index(syntheticID.startIndex, offsetBy: prefix.count)
        let withoutAuto = String(syntheticID[startIndex...])
        if withoutAuto == "/0" {
            return withoutAuto
        }
        if withoutAuto.hasPrefix("/0/") {
            let index = withoutAuto.index(withoutAuto.startIndex, offsetBy: 2)
            return String(withoutAuto[index...])
        }
        return withoutAuto
    }
}

private final class SVGXMLDocumentParser: NSObject, XMLParserDelegate {
    private enum FrameKind {
        case svg
        case group
        case path
        case defs
        case clipPath
        case filter
        case shape(SVGElementKind)
        case image
    }

    private struct Frame {
        var kind: FrameKind
        var base: SVGBaseNode
        var attributes: [String: String]
        var filterPrimitives: [SVGFilterPrimitive]
        var children: [SVGNode]
        var childCount: Int
    }

    private let options: SVGParserOptions
    private let styleDeclarationParser = SVGStyleDeclarationParser()
    private let styleRuleParser = SVGStyleRuleParser()
    private let pathDataParser = SVGPathDataParser()
    private var frames: [Frame] = []
    private var ignoreDepth: Int = 0
    private var styleDepth: Int = 0
    private var styleBuffer: String = ""
    private var styleRules: [SVGStyleRule] = []
    private var clipPathDefinitions: [String: [SVGNode]] = [:]
    private var filterDefinitions: [String: SVGFilterDefinition] = [:]
    private var parseError: SVGParserError?
    private var rootDocument: SVGDocument?

    init(options: SVGParserOptions) {
        self.options = options
    }

    func parse(data: Data) throws -> SVGDocument {
        frames.removeAll()
        ignoreDepth = 0
        styleDepth = 0
        styleBuffer.removeAll(keepingCapacity: false)
        styleRules.removeAll(keepingCapacity: false)
        clipPathDefinitions.removeAll(keepingCapacity: false)
        filterDefinitions.removeAll(keepingCapacity: false)
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
        let normalizedName = normalizeName(elementName)
        if styleDepth > 0 {
            styleDepth += 1
            return
        }
        if let filterPrimitive = parseFilterPrimitive(
            name: normalizedName,
            attributes: attributeDict
        ) {
            appendFilterPrimitive(filterPrimitive)
            return
        }
        if ignoreDepth > 0 {
            ignoreDepth += 1
            return
        }

        if normalizedName == "style" {
            if options.enableStyleTag {
                styleDepth = 1
                styleBuffer.removeAll(keepingCapacity: false)
                return
            }
            ignoreDepth = 1
            return
        }

        guard let frameKind = frameKind(for: normalizedName, stackDepth: frames.count) else {
            ignoreDepth = 1
            return
        }

        let embeddedSource: String? = if case .image = frameKind {
            embeddedImageSource(from: attributeDict)
        } else {
            nil
        }
        let syntheticID = makeSyntheticID(parentDepth: frames.count)
        var styledAttributes = enrichStyledAttributes(attributeDict)
        if let embeddedSource {
            styledAttributes[embeddedImageSourceAttribute] = embeddedSource
        }

        let base = SVGBaseNode(
            id: attributeDict["id"],
            syntheticID: syntheticID,
            style: parseStyle(attributes: attributeDict),
            transform: parseTransform(attributes: attributeDict),
            attributes: styledAttributes
        )

        frames.append(
            Frame(
                kind: frameKind,
                base: base,
                attributes: styledAttributes,
                filterPrimitives: [],
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
        if styleDepth > 0 {
            if normalizeName(elementName) == "style" {
                if styleDepth == 1 {
                    let rules = styleRuleParser.parse(styleBuffer)
                    styleRules.append(contentsOf: rules)
                    styleBuffer.removeAll(keepingCapacity: false)
                }
                styleDepth -= 1
            }
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
                nodes: frame.children,
                styleRules: styleRules,
                clipPaths: clipPathDefinitions,
                filterDefinitions: filterDefinitions
            )
        case .group:
            appendNode(.group(.init(base: frame.base, children: frame.children)), parser: parser)
        case .defs:
            break
        case .clipPath:
            if let clipPathID = frame.base.id {
                clipPathDefinitions[clipPathID] = frame.children
            }
        case .filter:
            if let filterID = frame.base.id {
                filterDefinitions[filterID] = SVGFilterDefinition(
                    id: filterID,
                    attributes: frame.attributes,
                    primitives: frame.filterPrimitives
                )
            }
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
        case .image:
            if !frame.children.isEmpty || frame.base.attributes[embeddedImageSourceAttribute] != nil {
                appendNode(.group(.init(base: frame.base, children: frame.children)), parser: parser)
            }
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if self.parseError == nil {
            self.parseError = .malformedDocument(reason: parseError.localizedDescription)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if styleDepth > 0 {
            styleBuffer.append(string)
        }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard styleDepth > 0 else {
            return
        }
        if let text = String(data: CDATABlock, encoding: .utf8) {
            styleBuffer.append(text)
        }
    }

    private func parseFilterPrimitive(
        name: String,
        attributes: [String: String]
    ) -> SVGFilterPrimitive? {
        guard let currentParent = frames.last,
              case .filter = currentParent.kind else {
            return nil
        }
        switch name {
        case "fegaussianblur":
            let stdDeviation: SVGFilterPrimitive? = parseStdDeviation(
                attributes["stdDeviation"]
            )
            if let stdDeviation {
                return stdDeviation
            }
            let stdXAttribute: String = attributes["stdDeviationX"] ?? ""
            let stdYAttribute: String = attributes["stdDeviationY"] ?? ""
            let stdX: Double = parseNumeric(stdXAttribute) ?? 0.0
            let stdY: Double = parseNumeric(stdYAttribute) ?? stdX
            return .gaussianBlur(
                stdDeviationX: stdX,
                stdDeviationY: stdY
            )
        case "feoffset":
            let dxAttribute: String = attributes["dx"] ?? ""
            let dyAttribute: String = attributes["dy"] ?? ""
            let dx: Double = parseNumeric(dxAttribute) ?? 0.0
            let dy: Double = parseNumeric(dyAttribute) ?? 0.0
            return .offset(dx: dx, dy: dy)
        default:
            if name.hasPrefix("fe") {
                return .unsupported(
                    type: name,
                    attributes: normalizePrimitiveAttributes(attributes)
                )
            }
            return nil
        }
    }

    private func parseStdDeviation(_ value: String?) -> SVGFilterPrimitive? {
        guard let value else {
            return nil
        }
        let values = value
            .split(
                whereSeparator: { separator in
                    separator == " " || separator == "," || separator == "\n" || separator == "\t"
                }
            )
            .compactMap { parseNumeric(String($0)) }
        if values.isEmpty {
            return nil
        }
        let stdDeviationX: Double = values[0]
        let stdDeviationY: Double = values.count > 1 ? values[1] : values[0]
        return .gaussianBlur(stdDeviationX: stdDeviationX, stdDeviationY: stdDeviationY)
    }

    private func normalizePrimitiveAttributes(_ attributes: [String: String]) -> [String: String] {
        var output: [String: String] = [:]
        for pair in attributes {
            let key: String = pair.key.lowercased()
            let value: String = pair.value
            output[key] = value
        }
        return output
    }

    private func appendFilterPrimitive(_ primitive: SVGFilterPrimitive) {
        guard let currentParent = frames.last,
              case .filter = currentParent.kind else {
            ignoreDepth = 1
            return
        }
        var parent = frames.removeLast()
        parent.filterPrimitives.append(primitive)
        frames.append(parent)
        ignoreDepth = 1
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

    private func embeddedImageSource(from attributes: [String: String]) -> String? {
        guard let href = attributeValue(named: "href", in: attributes) else {
            return nil
        }
        let normalizedHref = href.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedHref
    }

    private func attributeValue(named attributeName: String, in attributes: [String: String]) -> String? {
        if let directMatch = attributes[attributeName] {
            return directMatch
        }
        for (key, value) in attributes {
            let normalized = normalizeName(key)
            if normalized == attributeName {
                return value
            }
        }
        return nil
    }

    private func frameKind(for name: String, stackDepth: Int) -> FrameKind? {
        switch name {
        case "svg":
            return stackDepth == 0 ? .svg : nil
        case "defs":
            return .defs
        case "image":
            return .image
        case "clippath":
            return .clipPath
        case "filter":
            return .filter
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
        case .defs:
            return "defs"
        case .path:
            return "path"
        case .clipPath:
            return "clippath"
        case .filter:
            return "filter"
        case .image:
            return "image"
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
        applyStyleAttributes(attributes: attributes, to: &style)
        if let inlineStyle = attributes["style"] {
            let declarations = styleDeclarationParser.parse(inlineStyle)
            applyStyleDeclarations(declarations, to: &style)
        }
        return style
    }

    private func enrichStyledAttributes(_ attributes: [String: String]) -> [String: String] {
        var output = attributes
        if let clipPathFromStyle = parseClipPathStyle(from: attributes["style"]) {
            output["clip-path"] = clipPathFromStyle
        }
        if let filterFromStyle = parseFilterStyle(from: attributes["style"]) {
            output["filter"] = filterFromStyle
        }
        return output
    }

    private func parseClipPathStyle(from styleText: String?) -> String? {
        guard let styleText else {
            return nil
        }
        let declarations = styleDeclarationParser.parse(styleText)
        return declarations["clip-path"]
    }

    private func parseFilterStyle(from styleText: String?) -> String? {
        guard let styleText else {
            return nil
        }
        let declarations = styleDeclarationParser.parse(styleText)
        return declarations["filter"]
    }

    private func applyStyleAttributes(attributes: [String: String], to style: inout SVGStyle) {
        if let fill = attributes["fill"] {
            style.fill = parsePaint(fill)
        }
        if let fillOpacity = attributes["fill-opacity"] {
            style.fillOpacity = parseNumeric(fillOpacity)
        }
        if let fillRule = attributes["fill-rule"] {
            style.fillRule = parseFillRule(fillRule)
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
        if let strokeMiterLimit = attributes["stroke-miterlimit"] {
            style.strokeMiterLimit = parseNumeric(strokeMiterLimit)
        }
        if let strokeDasharray = attributes["stroke-dasharray"] {
            style.strokeDashArray = parseDashArray(strokeDasharray)
        }
        if let strokeDashoffset = attributes["stroke-dashoffset"] {
            style.strokeDashOffset = parseNumeric(strokeDashoffset)
        }
        if let filter = attributes["filter"] {
            style.filter = filter
        }
        if let opacity = attributes["opacity"] {
            style.opacity = parseNumeric(opacity)
        }
        if let strokeLinecap = attributes["stroke-linecap"] {
            style.strokeLineCap = parseStrokeLineCap(strokeLinecap)
        }
        if let strokeLinejoin = attributes["stroke-linejoin"] {
            style.strokeLineJoin = parseStrokeLineJoin(strokeLinejoin)
        }
    }

    private func applyStyleDeclarations(_ declarations: [String: String], to style: inout SVGStyle) {
        for (rawKey, rawValue) in declarations {
            let key = rawKey
        switch key {
        case "fill":
            style.fill = parsePaint(rawValue)
        case "fill-opacity":
            style.fillOpacity = parseNumeric(rawValue)
        case "fill-rule":
            style.fillRule = parseFillRule(rawValue)
        case "stroke":
            style.stroke = parsePaint(rawValue)
        case "stroke-opacity":
            style.strokeOpacity = parseNumeric(rawValue)
        case "stroke-width":
            style.strokeWidth = parseNumeric(rawValue)
        case "stroke-miterlimit":
            style.strokeMiterLimit = parseNumeric(rawValue)
        case "stroke-dasharray":
            style.strokeDashArray = parseDashArray(rawValue)
        case "stroke-dashoffset":
            style.strokeDashOffset = parseNumeric(rawValue)
        case "stroke-linecap":
            style.strokeLineCap = parseStrokeLineCap(rawValue)
        case "stroke-linejoin":
            style.strokeLineJoin = parseStrokeLineJoin(rawValue)
        case "filter":
            style.filter = rawValue
        case "opacity":
                style.opacity = parseNumeric(rawValue)
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
            case "skewx":
                if values.count >= 1 {
                    operations.append(.skewX(angleDegrees: values[0]))
                }
            case "skewy":
                if values.count >= 1 {
                    operations.append(.skewY(angleDegrees: values[0]))
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

    private func parseStrokeLineCap(_ value: String) -> SVGLineCap? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "butt":
            return .butt
        case "square":
            return .square
        case "round":
            return .round
        default:
            return nil
        }
    }

    private func parseStrokeLineJoin(_ value: String) -> SVGLineJoin? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "miter":
            return .miter
        case "bevel":
            return .bevel
        case "round":
            return .round
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
}
