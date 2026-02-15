struct SVGDocument: Sendable, Equatable {
    var size: SVGSize?
    var viewBox: SVGRect?
    var nodes: [SVGNode]
    var styleRules: [SVGStyleRule]
    var clipPaths: [String: [SVGNode]]
    var filterDefinitions: [String: SVGFilterDefinition]

    init(
        size: SVGSize? = nil,
        viewBox: SVGRect? = nil,
        nodes: [SVGNode] = [],
        styleRules: [SVGStyleRule] = [],
        clipPaths: [String: [SVGNode]] = [:],
        filterDefinitions: [String: SVGFilterDefinition] = [:]
    ) {
        self.size = size
        self.viewBox = viewBox
        self.nodes = nodes
        self.styleRules = styleRules
        self.clipPaths = clipPaths
        self.filterDefinitions = filterDefinitions
    }
}
