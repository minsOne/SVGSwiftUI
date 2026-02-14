public struct SVGColor: Sendable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public enum SVGPaint: Sendable, Equatable {
    case none
    case color(SVGColor)
    case currentColor
}

public enum SVGLineCap: Sendable, Equatable {
    case butt
    case round
    case square
}

public enum SVGLineJoin: Sendable, Equatable {
    case miter
    case round
    case bevel
}

public struct SVGStyle: Sendable, Equatable {
    public var fill: SVGPaint?
    public var fillOpacity: Double?
    public var stroke: SVGPaint?
    public var strokeOpacity: Double?
    public var strokeWidth: Double?
    public var strokeLineCap: SVGLineCap?
    public var strokeLineJoin: SVGLineJoin?
    public var opacity: Double?

    public init(
        fill: SVGPaint? = nil,
        fillOpacity: Double? = nil,
        stroke: SVGPaint? = nil,
        strokeOpacity: Double? = nil,
        strokeWidth: Double? = nil,
        strokeLineCap: SVGLineCap? = nil,
        strokeLineJoin: SVGLineJoin? = nil,
        opacity: Double? = nil
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.strokeWidth = strokeWidth
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
    }
}

public struct SVGResolvedStyle: Sendable, Equatable {
    public var fill: SVGPaint
    public var fillOpacity: Double
    public var stroke: SVGPaint
    public var strokeOpacity: Double
    public var strokeWidth: Double
    public var strokeLineCap: SVGLineCap
    public var strokeLineJoin: SVGLineJoin
    public var opacity: Double

    public init(
        fill: SVGPaint = .color(SVGColor(red: 0, green: 0, blue: 0, alpha: 1)),
        fillOpacity: Double = 1.0,
        stroke: SVGPaint = .none,
        strokeOpacity: Double = 1.0,
        strokeWidth: Double = 1.0,
        strokeLineCap: SVGLineCap = .butt,
        strokeLineJoin: SVGLineJoin = .miter,
        opacity: Double = 1.0
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.strokeWidth = strokeWidth
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
    }
}
