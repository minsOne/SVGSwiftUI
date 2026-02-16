enum SVGSMILAnimationKind: String, Sendable, Equatable {
    case animate
    case set
    case animateTransform = "animatetransform"
    case animateMotion = "animatemotion"
}

struct SVGSMILAnimationBinding: Sendable, Equatable, Hashable {
    let animationIndex: Int
    let targetAttribute: String?
}

enum SVGSMILAnimationValueInterpolation: String, Sendable, Equatable {
    case discrete
    case linear
    case paced
    case spline
    case `default` = "default"
}

enum SVGSMILAnimationRepeatCount: Sendable, Equatable {
    case finite(Double)
    case indefinite
}

enum SVGSMILAnimationFill: String, Sendable, Equatable {
    case remove = "remove"
    case freeze = "freeze"
    case auto = "auto"
}

struct SVGSMILAnimationTiming: Sendable, Equatable {
    var begin: [Double]
    var dur: Double?
    var end: [Double]
    var repeatCount: SVGSMILAnimationRepeatCount?
    var repeatDur: Double?
    var fill: SVGSMILAnimationFill
}

struct SVGSMILAnimationValue: Sendable, Equatable {
    var kind: String
    var raw: String
}

struct SVGSMILAnimation: Sendable, Equatable {
    var id: String?
    var kind: SVGSMILAnimationKind
    var targetElementID: String
    var targetSyntheticID: String
    var attributes: [String: String]
    var timing: SVGSMILAnimationTiming
    var attributeName: String?
    var values: SVGSMILAnimationValue?
    var type: String?
    var keyTimes: String?
    var keySplines: String?
    var interpolation: SVGSMILAnimationValueInterpolation
    var fromValue: String?
    var toValue: String?
    var byValue: String?

    init(
        id: String?,
        kind: SVGSMILAnimationKind,
        targetElementID: String,
        targetSyntheticID: String,
        attributes: [String: String],
        timing: SVGSMILAnimationTiming = Self.defaultTiming,
        attributeName: String? = nil,
        values: SVGSMILAnimationValue? = nil,
        type: String? = nil,
        keyTimes: String? = nil,
        keySplines: String? = nil,
        interpolation: SVGSMILAnimationValueInterpolation = .default,
        fromValue: String? = nil,
        toValue: String? = nil,
        byValue: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.targetElementID = targetElementID
        self.targetSyntheticID = targetSyntheticID
        self.attributes = attributes
        self.timing = timing
        self.attributeName = attributeName
        self.values = values
        self.type = type
        self.keyTimes = keyTimes
        self.keySplines = keySplines
        self.interpolation = interpolation
        self.fromValue = fromValue
        self.toValue = toValue
        self.byValue = byValue
    }

    static let defaultTiming: SVGSMILAnimationTiming = .init(
        begin: [],
        dur: nil,
        end: [],
        repeatCount: nil,
        repeatDur: nil,
        fill: .remove
    )
}
