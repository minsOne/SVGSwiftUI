struct SVGDocument: Sendable, Equatable {
    var size: SVGSize?
    var viewBox: SVGRect?
    var nodes: [SVGNode]
    var animations: [SVGSMILAnimation]
    var styleRules: [SVGStyleRule]
    var clipPaths: [String: [SVGNode]]
    var filterDefinitions: [String: SVGFilterDefinition]
    var unsupportedFeatures: [String: Int]

    var hasUnsupportedFeatures: Bool {
        !unsupportedFeatures.isEmpty
    }

    init(
        size: SVGSize? = nil,
        viewBox: SVGRect? = nil,
        nodes: [SVGNode] = [],
        animations: [SVGSMILAnimation] = [],
        styleRules: [SVGStyleRule] = [],
        clipPaths: [String: [SVGNode]] = [:],
        filterDefinitions: [String: SVGFilterDefinition] = [:],
        unsupportedFeatures: [String: Int] = [:]
    ) {
        self.size = size
        self.viewBox = viewBox
        self.nodes = nodes
        self.animations = animations
        self.styleRules = styleRules
        self.clipPaths = clipPaths
        self.filterDefinitions = filterDefinitions
        self.unsupportedFeatures = unsupportedFeatures
    }
}
