public struct SVGTransform: Sendable, Equatable {
    public enum Operation: Sendable, Equatable {
        case matrix(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double)
        case translate(tx: Double, ty: Double)
        case scale(sx: Double, sy: Double)
        case rotate(angleDegrees: Double, cx: Double?, cy: Double?)
    }

    public var operations: [Operation]

    public init(operations: [Operation] = []) {
        self.operations = operations
    }

    public static let identity = SVGTransform()
}
