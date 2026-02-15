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

enum SVGFillRule: Sendable, Equatable {
    case nonZero
    case evenOdd
}

enum SVGLineCap: Sendable, Equatable {
    case butt
    case round
    case square
}

enum SVGLineJoin: Sendable, Equatable {
    case miter
    case round
    case bevel
}

struct SVGStyle: Sendable, Equatable {
    var fill: SVGPaint?
    var fillOpacity: Double?
    var stroke: SVGPaint?
    var strokeOpacity: Double?
    var strokeWidth: Double?
    var fillRule: SVGFillRule?
    var strokeMiterLimit: Double?
    var strokeDashArray: [Double]?
    var strokeDashOffset: Double?
    var strokeLineCap: SVGLineCap?
    var strokeLineJoin: SVGLineJoin?
    var opacity: Double?

    init(
        fill: SVGPaint? = nil,
        fillOpacity: Double? = nil,
        stroke: SVGPaint? = nil,
        strokeOpacity: Double? = nil,
        strokeWidth: Double? = nil,
        fillRule: SVGFillRule? = nil,
        strokeMiterLimit: Double? = nil,
        strokeDashArray: [Double]? = nil,
        strokeDashOffset: Double? = nil,
        strokeLineCap: SVGLineCap? = nil,
        strokeLineJoin: SVGLineJoin? = nil,
        opacity: Double? = nil
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.strokeWidth = strokeWidth
        self.fillRule = fillRule
        self.strokeMiterLimit = strokeMiterLimit
        self.strokeDashArray = strokeDashArray
        self.strokeDashOffset = strokeDashOffset
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
    }
}

struct SVGResolvedStyle: Sendable, Equatable {
    var fill: SVGPaint
    var fillOpacity: Double
    var stroke: SVGPaint
    var strokeOpacity: Double
    var strokeWidth: Double
    var fillRule: SVGFillRule
    var strokeMiterLimit: Double
    var strokeDashArray: [Double]
    var strokeDashOffset: Double
    var strokeLineCap: SVGLineCap
    var strokeLineJoin: SVGLineJoin
    var opacity: Double

    init(
        fill: SVGPaint = .color(SVGColor(red: 0, green: 0, blue: 0, alpha: 1)),
        fillOpacity: Double = 1.0,
        stroke: SVGPaint = .none,
        strokeOpacity: Double = 1.0,
        strokeWidth: Double = 1.0,
        fillRule: SVGFillRule = .nonZero,
        strokeMiterLimit: Double = 4.0,
        strokeDashArray: [Double] = [],
        strokeDashOffset: Double = 0.0,
        strokeLineCap: SVGLineCap = .butt,
        strokeLineJoin: SVGLineJoin = .miter,
        opacity: Double = 1.0
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.strokeWidth = strokeWidth
        self.fillRule = fillRule
        self.strokeMiterLimit = strokeMiterLimit
        self.strokeDashArray = strokeDashArray
        self.strokeDashOffset = strokeDashOffset
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
    }
}

extension SVGResolvedStyle {
    func applying(style: SVGStyle) -> SVGResolvedStyle {
        SVGResolvedStyle(
            fill: style.fill ?? fill,
            fillOpacity: style.fillOpacity ?? fillOpacity,
            stroke: style.stroke ?? stroke,
            strokeOpacity: style.strokeOpacity ?? strokeOpacity,
            strokeWidth: style.strokeWidth ?? strokeWidth,
            fillRule: style.fillRule ?? fillRule,
            strokeMiterLimit: style.strokeMiterLimit ?? strokeMiterLimit,
            strokeDashArray: style.strokeDashArray ?? strokeDashArray,
            strokeDashOffset: style.strokeDashOffset ?? strokeDashOffset,
            strokeLineCap: style.strokeLineCap ?? strokeLineCap,
            strokeLineJoin: style.strokeLineJoin ?? strokeLineJoin,
            opacity: style.opacity ?? opacity
        )
    }
}
