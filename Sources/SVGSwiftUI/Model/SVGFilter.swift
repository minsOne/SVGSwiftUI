enum SVGFilterPrimitive: Sendable, Equatable {
    case gaussianBlur(stdDeviationX: Double, stdDeviationY: Double)
    case offset(dx: Double, dy: Double)
}

struct SVGFilterDefinition: Sendable, Equatable {
    var id: String
    var attributes: [String: String]
    var primitives: [SVGFilterPrimitive]

    init(
        id: String,
        attributes: [String: String] = [:],
        primitives: [SVGFilterPrimitive] = []
    ) {
        self.id = id
        self.attributes = attributes
        self.primitives = primitives
    }
}
