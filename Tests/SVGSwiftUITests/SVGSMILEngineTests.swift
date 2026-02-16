import XCTest
@testable import SVGSwiftUI

final class SVGSMILEngineTests: XCTestCase {
    func testApplyAnimationsInterpolatesNumericAttributeOverTimeline() {
        let target = "target"
        let baseStyle = SVGResolvedStyle(opacity: 0)
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: baseStyle
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "opacity", "from": "0", "to": "1"],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "opacity",
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "0",
            toValue: "1",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        XCTAssertEqual(updatedStyle.style.opacity, 0.5)
    }

    func testApplyAnimationsInterpolatesLengthFromToPxWithAttributeName() {
        let target = "target-stroke-width"
        let baseStyle = SVGResolvedStyle(strokeWidth: 1)
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: baseStyle
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: [
                "attributename": "stroke-width",
                "from": "1px",
                "to": "5px"
            ],
            timing: .init(
                begin: [0],
                dur: 4,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "stroke-width",
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "1px",
            toValue: "5px",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        XCTAssertEqual(updatedStyle.style.strokeWidth, 2)
    }

    func testApplyAnimationsInterpolatesColorAttributeFromToValues() {
        let target = "target-fill"
        let baseStyle = SVGResolvedStyle(fill: SVGPaint.color(.init(red: 0, green: 0, blue: 0, alpha: 1)))
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: baseStyle
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "fill", "from": "#ff0000", "to": "#0000ff"],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "fill",
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "#ff0000",
            toValue: "#0000ff",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard case .color(let color) = updatedStyle.style.fill else {
            return XCTFail("Expected color style")
        }
        XCTAssertEqual(color.red, 0.5, accuracy: 0.001)
        XCTAssertEqual(color.green, 0, accuracy: 0.001)
        XCTAssertEqual(color.blue, 0.5, accuracy: 0.001)
    }

    func testApplySetAnimationOverridesToValue() {
        let target = "target"
        let baseStyle = SVGResolvedStyle(strokeOpacity: 1)
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: baseStyle
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .set,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "stroke-opacity", "to": "0.25"],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "stroke-opacity",
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: "0.25",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        XCTAssertEqual(updatedStyle.style.strokeOpacity, 0.25)
    }

    func testApplyAnimateTransformInterpolatesRotateWithType() {
        let target = "transform-rotate"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "transform", "from": "0", "to": "90", "type": "rotate"],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "transform",
            values: nil,
            type: "rotate",
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "0",
            toValue: "90",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updatedStyle.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transform.a, 0.5, accuracy: 0.0001)
        XCTAssertEqual(transform.b, 0.5, accuracy: 0.0001)
        XCTAssertEqual(transform.c, -0.5, accuracy: 0.0001)
        XCTAssertEqual(transform.d, 0.5, accuracy: 0.0001)
    }

    func testApplyAnimateTransformInterpolateScaleWithType() {
        let target = "transform-scale"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "transform", "from": "1", "to": "2", "type": "scale"],
            timing: .init(
                begin: [0],
                dur: 4,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "transform",
            values: nil,
            type: "scale",
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "1",
            toValue: "2",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 2
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updatedStyle.transformOverride else {
            return XCTFail("Expected transform override")
        }
        XCTAssertEqual(transform.a, 1.5, accuracy: 0.0001)
        XCTAssertEqual(transform.b, 0, accuracy: 0.0001)
        XCTAssertEqual(transform.c, 0, accuracy: 0.0001)
        XCTAssertEqual(transform.d, 1.5, accuracy: 0.0001)
    }

    func testApplyAnimateTransformInterpolatesTranslateValuesList() {
        let target = "transform-translate-values"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animate,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: [
                "attributename": "transform",
                "values": "translate(0 0);translate(10 20)",
                "type": "translate"
            ],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "transform",
            values: .init(kind: "values", raw: "translate(0 0);translate(10 20)"),
            type: "translate",
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: nil,
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updatedStyle.transformOverride else {
            return XCTFail("Expected transform override")
        }
        XCTAssertEqual(transform.tx, 5, accuracy: 0.0001)
        XCTAssertEqual(transform.ty, 10, accuracy: 0.0001)
    }

    func testApplySetTransformSetsMatrixFromToValue() {
        let target = "target"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .set,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["attributename": "transform", "to": "translate(12 34)"],
            timing: .init(
                begin: [0],
                dur: 1,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: "transform",
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: "translate(12 34)",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 0.1
        )

        guard let updatedStyle = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updatedStyle.transformOverride else {
            return XCTFail("Expected transform override")
        }
        XCTAssertEqual(transform.tx, 12)
        XCTAssertEqual(transform.ty, 34)
    }

    func testApplyAnimateMotionTranslatesAlongPath() {
        let target = "motion"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animateMotion,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["path": "M 0 0 L 100 0 L 100 100", "rotate": "0"],
            timing: .init(
                begin: [0],
                dur: 4,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: nil,
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: nil,
            byValue: nil
        )

        let atQuarter = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )
        guard let animatedQuarter = atQuarter[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transformQuarter = animatedQuarter.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transformQuarter.tx, 50, accuracy: 0.001)
        XCTAssertEqual(transformQuarter.ty, 0, accuracy: 0.001)

        let atThreeQuarters = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 3
        )
        guard let animatedThreeQuarters = atThreeQuarters[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transformThreeQuarters = animatedThreeQuarters.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transformThreeQuarters.tx, 100, accuracy: 0.001)
        XCTAssertEqual(transformThreeQuarters.ty, 50, accuracy: 0.001)
    }

    func testApplyAnimateMotionSupportsFixedRotation() {
        let target = "motion-rotate"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animateMotion,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["from": "0 0", "to": "100 100", "rotate": "45"],
            timing: .init(
                begin: [0],
                dur: 2,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: nil,
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: "0 0",
            toValue: "100 100",
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 1
        )
        guard let updated = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updated.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transform.tx, 50, accuracy: 0.001)
        XCTAssertEqual(transform.ty, 50, accuracy: 0.001)
        XCTAssertEqual(transform.a, cos(.pi / 4), accuracy: 0.001)
        XCTAssertEqual(transform.b, sin(.pi / 4), accuracy: 0.001)
        XCTAssertEqual(transform.c, -sin(.pi / 4), accuracy: 0.001)
        XCTAssertEqual(transform.d, cos(.pi / 4), accuracy: 0.001)
    }

    func testApplyAnimateMotionSupportsAutoRotation() {
        let target = "motion-autorotate"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animateMotion,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["path": "M 0 0 L 10 0 L 10 10", "rotate": "auto"],
            timing: .init(
                begin: [0],
                dur: 4,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: nil,
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: nil,
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 3
        )
        guard let updated = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updated.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transform.tx, 10, accuracy: 0.001)
        XCTAssertEqual(transform.ty, 5, accuracy: 0.001)
        XCTAssertEqual(transform.a, 0, accuracy: 0.001)
        XCTAssertEqual(transform.b, 1, accuracy: 0.001)
        XCTAssertEqual(transform.c, -1, accuracy: 0.001)
        XCTAssertEqual(transform.d, 0, accuracy: 0.001)
    }

    func testApplyAnimateMotionSupportsAutoReverseRotation() {
        let target = "motion-autorotate-reverse"
        let styles: [String: SVGResolvedNodeStyle] = [
            target: SVGResolvedNodeStyle(
                nodeID: target,
                element: .rect,
                style: SVGResolvedStyle()
            )
        ]

        let animation = SVGSMILAnimation(
            id: nil,
            kind: .animateMotion,
            targetElementID: target,
            targetSyntheticID: target,
            attributes: ["path": "M 0 0 L 10 0 L 10 10", "rotate": "auto-reverse"],
            timing: .init(
                begin: [0],
                dur: 4,
                end: [],
                repeatCount: nil,
                repeatDur: nil,
                fill: .remove
            ),
            attributeName: nil,
            values: nil,
            type: nil,
            keyTimes: nil,
            keySplines: nil,
            interpolation: .linear,
            fromValue: nil,
            toValue: nil,
            byValue: nil
        )

        let animated = SVGSMILEngine.applyAnimations(
            to: styles,
            animationsByTargetID: [target: [animation]],
            at: 3
        )
        guard let updated = animated[target] else {
            return XCTFail("Expected animated target")
        }
        guard let transform = updated.transformOverride else {
            return XCTFail("Expected transform override")
        }

        XCTAssertEqual(transform.tx, 10, accuracy: 0.001)
        XCTAssertEqual(transform.ty, 5, accuracy: 0.001)

        // Second segment direction (0,1) 기준 auto(90°)에서 +180°가 적용되어 270°가 됨.
        XCTAssertEqual(transform.a, 0, accuracy: 0.001)
        XCTAssertEqual(transform.b, -1, accuracy: 0.001)
        XCTAssertEqual(transform.c, 1, accuracy: 0.001)
        XCTAssertEqual(transform.d, 0, accuracy: 0.001)
    }
}
