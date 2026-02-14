public struct SVGDocument: Sendable, Equatable {
    public var size: SVGSize?
    public var viewBox: SVGRect?
    public var nodes: [SVGNode]

    public init(size: SVGSize? = nil, viewBox: SVGRect? = nil, nodes: [SVGNode] = []) {
        self.size = size
        self.viewBox = viewBox
        self.nodes = nodes
    }
}
