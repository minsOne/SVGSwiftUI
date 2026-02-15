enum SVGFilterPrimitive: Sendable, Equatable {
    case gaussianBlur(stdDeviationX: Double, stdDeviationY: Double)
    case offset(dx: Double, dy: Double)
    case blend(mode: String, inSource: String?, inSourceTwo: String?)
    case colorMatrix(values: [Double])
    case unsupported(type: String, attributes: [String: String])
}

extension SVGFilterPrimitive {
    var isSupported: Bool {
        switch self {
        case .gaussianBlur, .offset, .blend, .colorMatrix:
            true
        case .unsupported:
            false
        }
    }
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

    var hasUnsupportedPrimitives: Bool {
        for primitive in primitives {
            if !primitive.isSupported {
                return true
            }
        }
        return false
    }

    var hasSupportedPrimitives: Bool {
        for primitive in primitives {
            if primitive.isSupported {
                return true
            }
        }
        return false
    }

    var hasNoPrimitives: Bool {
        primitives.isEmpty
    }
}
