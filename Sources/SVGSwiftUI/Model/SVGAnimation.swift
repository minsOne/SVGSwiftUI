enum SVGSMILAnimationKind: String, Sendable, Equatable {
    case animate
    case set
    case animateTransform = "animatetransform"
    case animateMotion = "animatemotion"
}

struct SVGSMILAnimation: Sendable, Equatable {
    var id: String?
    var kind: SVGSMILAnimationKind
    var targetElementID: String
    var targetSyntheticID: String
    var attributes: [String: String]
}
