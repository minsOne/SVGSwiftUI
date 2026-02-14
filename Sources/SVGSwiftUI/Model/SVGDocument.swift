struct SVGDocument: Sendable, Equatable {
    var size: SVGSize?
    var viewBox: SVGRect?
    var nodes: [SVGNode]

    init(size: SVGSize? = nil, viewBox: SVGRect? = nil, nodes: [SVGNode] = []) {
        self.size = size
        self.viewBox = viewBox
        self.nodes = nodes
    }
}
