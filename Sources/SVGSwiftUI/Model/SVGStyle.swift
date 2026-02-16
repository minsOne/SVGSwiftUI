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

enum SVGFontStyle: String, Sendable, Equatable {
    case normal
    case italic
    case oblique
}

enum SVGFontWeight: Sendable, Equatable {
    case normal
    case bold
    case bolder
    case lighter
    case numeric(Int)
}

struct SVGStyle: Sendable, Equatable {
    var fill: SVGPaint?
    var fillOpacity: Double?
    var stroke: SVGPaint?
    var strokeOpacity: Double?
    var filter: String?
    var strokeWidth: Double?
    var fillRule: SVGFillRule?
    var strokeMiterLimit: Double?
    var strokeDashArray: [Double]?
    var strokeDashOffset: Double?
    var strokeLineCap: SVGLineCap?
    var strokeLineJoin: SVGLineJoin?
    var opacity: Double?
    var fontSize: Double?
    var fontFamily: String?
    var textAnchor: SVGTextAnchor?
    var fontStyle: SVGFontStyle?
    var fontWeight: SVGFontWeight?

    init(
        fill: SVGPaint? = nil,
        fillOpacity: Double? = nil,
        stroke: SVGPaint? = nil,
        strokeOpacity: Double? = nil,
        filter: String? = nil,
        strokeWidth: Double? = nil,
        fillRule: SVGFillRule? = nil,
        strokeMiterLimit: Double? = nil,
        strokeDashArray: [Double]? = nil,
        strokeDashOffset: Double? = nil,
        strokeLineCap: SVGLineCap? = nil,
        strokeLineJoin: SVGLineJoin? = nil,
        opacity: Double? = nil,
        fontSize: Double? = nil,
        fontFamily: String? = nil,
        textAnchor: SVGTextAnchor? = nil,
        fontStyle: SVGFontStyle? = nil,
        fontWeight: SVGFontWeight? = nil
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.filter = filter
        self.strokeWidth = strokeWidth
        self.fillRule = fillRule
        self.strokeMiterLimit = strokeMiterLimit
        self.strokeDashArray = strokeDashArray
        self.strokeDashOffset = strokeDashOffset
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.textAnchor = textAnchor
        self.fontStyle = fontStyle
        self.fontWeight = fontWeight
    }
}

enum SVGTextAnchor: String, Sendable, Equatable {
    case start
    case middle
    case end
}

struct SVGResolvedStyle: Sendable, Equatable {
    var fill: SVGPaint
    var fillOpacity: Double
    var stroke: SVGPaint
    var strokeOpacity: Double
    var filter: String?
    var strokeWidth: Double
    var fillRule: SVGFillRule
    var strokeMiterLimit: Double
    var strokeDashArray: [Double]
    var strokeDashOffset: Double
    var strokeLineCap: SVGLineCap
    var strokeLineJoin: SVGLineJoin
    var opacity: Double
    var fontSize: Double
    var fontFamily: String
    var textAnchor: SVGTextAnchor
    var fontStyle: SVGFontStyle
    var fontWeight: SVGFontWeight

    init(
        fill: SVGPaint = .color(SVGColor(red: 0, green: 0, blue: 0, alpha: 1)),
        fillOpacity: Double = 1.0,
        stroke: SVGPaint = .none,
        strokeOpacity: Double = 1.0,
        filter: String? = nil,
        strokeWidth: Double = 1.0,
        fillRule: SVGFillRule = .nonZero,
        strokeMiterLimit: Double = 4.0,
        strokeDashArray: [Double] = [],
        strokeDashOffset: Double = 0.0,
        strokeLineCap: SVGLineCap = .butt,
        strokeLineJoin: SVGLineJoin = .miter,
        opacity: Double = 1.0,
        fontSize: Double = 16.0,
        fontFamily: String = "system",
        textAnchor: SVGTextAnchor = .start,
        fontStyle: SVGFontStyle = .normal,
        fontWeight: SVGFontWeight = .normal
    ) {
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        self.filter = filter
        self.strokeWidth = strokeWidth
        self.fillRule = fillRule
        self.strokeMiterLimit = strokeMiterLimit
        self.strokeDashArray = strokeDashArray
        self.strokeDashOffset = strokeDashOffset
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.opacity = opacity
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.textAnchor = textAnchor
        self.fontStyle = fontStyle
        self.fontWeight = fontWeight
    }
}

extension SVGResolvedStyle {
    func applying(style: SVGStyle) -> SVGResolvedStyle {
        SVGResolvedStyle(
            fill: style.fill ?? fill,
            fillOpacity: style.fillOpacity ?? fillOpacity,
            stroke: style.stroke ?? stroke,
            strokeOpacity: style.strokeOpacity ?? strokeOpacity,
            filter: style.filter ?? filter,
            strokeWidth: style.strokeWidth ?? strokeWidth,
            fillRule: style.fillRule ?? fillRule,
            strokeMiterLimit: style.strokeMiterLimit ?? strokeMiterLimit,
            strokeDashArray: style.strokeDashArray ?? strokeDashArray,
            strokeDashOffset: style.strokeDashOffset ?? strokeDashOffset,
            strokeLineCap: style.strokeLineCap ?? strokeLineCap,
            strokeLineJoin: style.strokeLineJoin ?? strokeLineJoin,
            opacity: style.opacity ?? opacity,
            fontSize: style.fontSize ?? fontSize,
            fontFamily: style.fontFamily ?? fontFamily,
            textAnchor: style.textAnchor ?? textAnchor,
            fontStyle: style.fontStyle ?? fontStyle,
            fontWeight: style.fontWeight ?? fontWeight
        )
    }
}
