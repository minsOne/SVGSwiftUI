import XCTest
@testable import SVGSwiftUI

final class SVGRenderConfigurationSignatureTests: XCTestCase {
    func testFingerprintStableForEquivalentOverrideMaps() {
        let first = SVGRenderConfiguration(
            idOverrides: [
                "node-b": NodeOverride(
                    fill: .color(.init(red: 1, green: 0, blue: 0, alpha: 1)),
                    opacity: 0.5,
                    scale: SVGSize(width: 2, height: 3)
                ),
                "node-a": NodeOverride(
                    strokeWidth: 2,
                    offset: SVGPoint(x: 10, y: 20)
                )
            ],
            resolver: nil
        )

        let second = SVGRenderConfiguration(
            idOverrides: [
                "node-a": NodeOverride(
                    strokeWidth: 2,
                    offset: SVGPoint(x: 10, y: 20)
                ),
                "node-b": NodeOverride(
                    fill: .color(.init(red: 1, green: 0, blue: 0, alpha: 1)),
                    opacity: 0.5,
                    scale: SVGSize(width: 2, height: 3)
                )
            ],
            resolver: nil
        )

        let firstFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: first)
        let secondFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: second)

        XCTAssertEqual(firstFingerprint, secondFingerprint)
    }

    func testFingerprintChangesWhenResolverPresenceChanges() {
        let base = SVGRenderConfiguration(idOverrides: ["node-a": NodeOverride(opacity: 1)])
        let withResolver = SVGRenderConfiguration(
            idOverrides: ["node-a": NodeOverride(opacity: 1)],
            resolver: { _ in
                nil
            }
        )

        let baseFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: base)
        let resolverFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: withResolver)

        XCTAssertNotEqual(baseFingerprint, resolverFingerprint)
    }

    func testFingerprintChangesWithDifferentOverrideValue() {
        let first = SVGRenderConfiguration(idOverrides: ["node-a": NodeOverride(strokeWidth: 1)])
        let second = SVGRenderConfiguration(idOverrides: ["node-a": NodeOverride(strokeWidth: 2)])

        let firstFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: first)
        let secondFingerprint: String = SVGRenderConfigurationSignature.fingerprint(for: second)

        XCTAssertNotEqual(firstFingerprint, secondFingerprint)
    }
}
