struct SVGTransform: Sendable, Equatable {
    enum Operation: Sendable, Equatable {
        case matrix(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double)
        case translate(tx: Double, ty: Double)
        case scale(sx: Double, sy: Double)
        case rotate(angleDegrees: Double, cx: Double?, cy: Double?)
    }

    var operations: [Operation]

    init(operations: [Operation] = []) {
        self.operations = operations
    }

    static let identity = SVGTransform()
}
