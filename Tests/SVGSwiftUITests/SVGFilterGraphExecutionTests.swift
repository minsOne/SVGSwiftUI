import XCTest
@testable import SVGSwiftUI

final class SVGFilterGraphExecutionTests: XCTestCase {
    func testFilterGraphCanExecuteBlendChainWithAvailableSources() {
        let primitives: [SVGFilterPrimitive] = [
            .gaussianBlur(stdDeviationX: 1.5, stdDeviationY: 1.5, inSource: "SourceGraphic", result: "blurred"),
            .offset(dx: 3, dy: 4, inSource: "blurred", result: "shifted"),
            .blend(mode: "multiply", inSource: "shifted", inSourceTwo: "SourceGraphic", result: "merged"),
            .colorMatrix(values: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], inSource: "merged", result: nil)
        ]

        var availableSources: Set<String> = SVGFilterGraphExecutor.defaultAvailableSources()
        for primitive in primitives {
            let canExecute: Bool = SVGFilterGraphExecutor.canExecute(
                primitive,
                availableSources: availableSources
            )
            XCTAssertTrue(canExecute)
            let resultName: String? = SVGFilterGraphExecutor.resolvedResultName(for: primitive)
            if let resultName {
                availableSources.insert(resultName)
            }
        }

        XCTAssertEqual(
            availableSources,
            Set([
                "SourceGraphic",
                "SourceAlpha",
                "blurred",
                "shifted",
                "merged"
            ])
        )
        XCTAssertTrue(availableSources.contains("merged"))
    }

    func testFilterGraphSkipsPrimitiveWhenSourceMissing() {
        let primitives: [SVGFilterPrimitive] = [
            .gaussianBlur(stdDeviationX: 1.5, stdDeviationY: 1.5, inSource: "ghost", result: "blurred"),
            .offset(dx: 1, dy: 2, inSource: "blurred", result: nil),
            .colorMatrix(values: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], inSource: "SourceGraphic", result: "base")
        ]

        var availableSources: Set<String> = SVGFilterGraphExecutor.defaultAvailableSources()
        for primitive in primitives {
            guard SVGFilterGraphExecutor.canExecute(primitive, availableSources: availableSources) else {
                continue
            }
            let resultName: String? = SVGFilterGraphExecutor.resolvedResultName(for: primitive)
            if let resultName {
                availableSources.insert(resultName)
            }
        }

        XCTAssertEqual(
            availableSources,
            Set([
                "SourceGraphic",
                "SourceAlpha",
                "base"
            ])
        )
    }

    func testFilterGraphDefaultsSourceInputsWhenMissingIn() {
        let primitive: SVGFilterPrimitive = .offset(
            dx: 2,
            dy: 2,
            inSource: nil,
            result: nil
        )

        let canExecute: Bool = SVGFilterGraphExecutor.canExecute(
            primitive,
            availableSources: SVGFilterGraphExecutor.defaultAvailableSources()
        )
        XCTAssertTrue(canExecute)
    }
}
