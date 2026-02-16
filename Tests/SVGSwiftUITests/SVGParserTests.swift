import XCTest
@testable import SVGSwiftUI

final class SVGParserTests: XCTestCase {
    private let parser = SVGParser()

    func testParseRejectsEmptyInput() {
        XCTAssertThrowsError(try parser.parse(source: .string(""))) { error in
            XCTAssertEqual(error as? SVGParserError, .emptyInput)
        }
    }

    func testParseRejectsNonSVGRoot() {
        XCTAssertThrowsError(try parser.parse(source: .string("<html></html>"))) { error in
            XCTAssertEqual(error as? SVGParserError, .invalidSVGRoot)
        }
    }

    func testParseThrowsMalformedDocumentForBrokenXML() {
        XCTAssertThrowsError(try parser.parse(source: .string("<svg><g></svg>"))) { error in
            guard case .malformedDocument = (error as? SVGParserError) else {
                return XCTFail("Expected malformedDocument, got \(error)")
            }
        }
    }

    func testParseReadsRootSizeAndViewBox() throws {
        let document = try parser.parse(source: .string("<svg width='24' height='32' viewBox='0 0 24 32'></svg>"))

        XCTAssertEqual(document.size, SVGSize(width: 24, height: 32))
        XCTAssertEqual(document.viewBox, SVGRect(x: 0, y: 0, width: 24, height: 32))
    }

    func testParseDataMatchesParseSource() throws {
        let svg = "<svg width='24' height='32'><path d='M0 0 L2 2'/></svg>"
        let sourceDocument = try parser.parse(source: .string(svg))
        let dataDocument = try parser.parse(data: Data(svg.utf8))
        XCTAssertEqual(dataDocument, sourceDocument)
    }

    func testParseHandlesUTF16EncodedData() throws {
        let svg = "<svg width='24' height='32'></svg>"
        let utf16Bytes: [UInt8] = svg.utf16.flatMap { value in
            let lowByte: UInt8 = UInt8(truncatingIfNeeded: value)
            let highByte: UInt8 = UInt8(truncatingIfNeeded: value >> 8)
            return [lowByte, highByte]
        }
        let utf16Data: Data = Data(utf16Bytes)

        _ = try parser.parse(data: utf16Data)
    }

    func testParseRecoversWrappedSVGPayload() throws {
        let svg = """
        <html>
          <body>
            <svg width='20' height='20'>
            </svg>
          </body>
        </html>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(document.size, SVGSize(width: 20, height: 20))
    }

    func testParseSetsRootSizeNilForPercentageUnits() throws {
        let document = try parser.parse(source: .string("<svg width='100%' height='100%'></svg>"))
        XCTAssertNil(document.size)
    }

    func testParseHandlesNamespacePrefixedElements() throws {
        let svg = """
        <svg xmlns:foo="http://example.com/svg">
          <foo:g id="grp">
            <foo:path id="prefixed-path" d="M0 0"/>
          </foo:g>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(document.nodes.count, 1)

        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected group node")
        }
        XCTAssertEqual(group.base.id, "grp")
        XCTAssertEqual(group.children.count, 1)
        XCTAssertEqual(pathNode(id: "prefixed-path", in: document)?.pathData, "M0 0")
    }

    func testParseIgnoresUnsupportedElementsButKeepsSupportedSiblings() throws {
        let svg = """
        <svg width="20" height="20">
          <defs>
            <path id="inside-defs" d="M0 0 L5 5"/>
          </defs>
          <circle id="kept-circle" cx="5" cy="5" r="2"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNil(pathNode(id: "inside-defs", in: document))

        guard let circle = shapeNode(id: "kept-circle", in: document) else {
            return XCTFail("Expected circle shape")
        }
        XCTAssertEqual(circle.kind, .circle)
    }

    func testParseKeepsElementsWithClipPathAttributeAndDropsClipPathBlock() throws {
        let svg = """
        <svg width="20" height="20">
          <defs>
            <clipPath id="clip">
              <rect x="0" y="0" width="10" height="10"/>
            </clipPath>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" clip-path="url(#clip)"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let clipNodes = document.clipPaths["clip"] else {
            return XCTFail("Expected clipPath definition for id 'clip'")
        }
        XCTAssertEqual(clipNodes.count, 1)
        guard case .shape(let clipShape) = clipNodes[0] else {
            return XCTFail("Expected clipPath child to remain as shape node")
        }
        XCTAssertEqual(clipShape.kind, .rect)
        XCTAssertNil(shapeNode(id: "clip", in: document))

        guard let shape = shapeNode(id: "foreground", in: document) else {
            return XCTFail("Expected foreground shape")
        }
        XCTAssertEqual(shape.kind, .rect)
        XCTAssertEqual(shape.base.attributes["clip-path"], "url(#clip)")
    }

    func testParseReadsClipPathDefinitionsInClipPathNode() throws {
        let svg = """
        <svg>
          <defs>
            <clipPath id="clip-window">
              <g transform="translate(5 7)">
                <rect x="10" y="20" width="3" height="4"/>
              </g>
            </clipPath>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" clip-path="url(#clip-window)"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let clipNodes = document.clipPaths["clip-window"] else {
            return XCTFail("Expected clipPath definition for id 'clip-window'")
        }
        XCTAssertEqual(clipNodes.count, 1)
        guard case .group(let clipGroup) = clipNodes[0] else {
            return XCTFail("Expected wrapper group inside clipPath")
        }
        XCTAssertEqual(clipGroup.base.transform.operations.count, 1)
        XCTAssertEqual(clipGroup.base.transform.operations[0], .translate(tx: 5, ty: 7))
        XCTAssertEqual(clipGroup.children.count, 1)
    }

    func testParseReadsClipPathFromInlineStyle() throws {
        let svg = """
        <svg>
          <defs>
            <clipPath id="inline">
              <rect x="0" y="0" width="8" height="8"/>
            </clipPath>
          </defs>
          <clipPath id="attr">
            <rect x="0" y="0" width="2" height="2"/>
          </clipPath>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            clip-path="url(#attr)"
            style="clip-path:url(#inline); fill:#0ff"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let foreground = shapeNode(id: "foreground", in: document) else {
            return XCTFail("Expected foreground shape")
        }
        XCTAssertEqual(foreground.base.attributes["clip-path"], "url(#inline)")
    }

    func testParseReadsFilterDefinitionAndFilterAttribute() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="blur" x="0" y="0" width="200%" height="200%">
              <feGaussianBlur stdDeviation="2.5"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#blur)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let filterDefinition = document.filterDefinitions["blur"] else {
            return XCTFail("Expected filter definition for id 'blur'")
        }
        XCTAssertEqual(filterDefinition.id, "blur")
        XCTAssertEqual(filterDefinition.attributes["x"], "0")
        XCTAssertEqual(filterDefinition.attributes["y"], "0")
        XCTAssertEqual(filterDefinition.attributes["width"], "200%")
        XCTAssertEqual(filterDefinition.attributes["height"], "200%")

        guard let foreground = shapeNode(id: "foreground", in: document) else {
            return XCTFail("Expected foreground rect")
        }
        XCTAssertEqual(foreground.base.style.filter, "url(#blur)")
        XCTAssertEqual(foreground.base.attributes["filter"], "url(#blur)")
    }

    func testParseReadsFilterFromInlineStyle() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="inline">
              <feOffset dx="2" dy="3"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            style="filter: url(#inline); fill: #0ff;"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let foreground = shapeNode(id: "foreground", in: document) else {
            return XCTFail("Expected foreground rect")
        }
        XCTAssertEqual(foreground.base.style.filter, "url(#inline)")
        XCTAssertEqual(foreground.base.attributes["filter"], "url(#inline)")
    }

    func testParseReadsFilterPrimitives() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="complex">
              <feGaussianBlur stdDeviation="2.5 4"/>
              <feOffset dx="8" dy="-3"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#complex)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let filterDefinition = document.filterDefinitions["complex"] else {
            return XCTFail("Expected filter definition for id 'complex'")
        }
        XCTAssertEqual(filterDefinition.primitives.count, 2)

        let first = filterDefinition.primitives[0]
        let second = filterDefinition.primitives[1]
        XCTAssertEqual(
            first,
            .gaussianBlur(
                stdDeviationX: 2.5,
                stdDeviationY: 4.0,
                inSource: "SourceGraphic",
                result: nil
            )
        )
        XCTAssertEqual(
            second,
            .offset(
                dx: 8,
                dy: -3,
                inSource: "SourceGraphic",
                result: nil
            )
        )
    }

    func testParseReadsFilterPrimitivesWithSingleStandardDeviationValue() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="single">
              <feGaussianBlur stdDeviation="3.25"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#single)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["single"]?.primitives)
        XCTAssertEqual(primitives.count, 1)
        XCTAssertEqual(
            primitives[0],
            .gaussianBlur(
                stdDeviationX: 3.25,
                stdDeviationY: 3.25,
                inSource: "SourceGraphic",
                result: nil
            )
        )
    }

    func testParseTracksSupportedColorMatrixFilterPrimitive() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="unsupported">
              <feColorMatrix values="0.5"/>
              <feGaussianBlur stdDeviation="1"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#unsupported)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["unsupported"]?.primitives)
        XCTAssertEqual(primitives.count, 2)
        guard case .colorMatrix(let values, _, _) = primitives[0] else {
            return XCTFail("Expected colorMatrix filter primitive first")
        }
        XCTAssertEqual(values, [0.5])

        XCTAssertEqual(
            primitives[1],
            .gaussianBlur(
                stdDeviationX: 1,
                stdDeviationY: 1,
                inSource: "SourceGraphic",
                result: nil
            )
        )
        XCTAssertFalse(document.filterDefinitions["unsupported"]?.hasUnsupportedPrimitives == true)
        XCTAssertTrue(document.filterDefinitions["unsupported"]?.hasSupportedPrimitives == true)
    }

    func testParseTracksSupportedBlendPrimitive() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="supported">
              <feColorMatrix values="1"/>
              <feOffset dx="7" dy="-4"/>
              <feBlend in="SourceGraphic" in2="SourceGraphic" mode="multiply"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#mixed)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["supported"]?.primitives)
        XCTAssertEqual(primitives.count, 3)
        guard case .colorMatrix(let values, _, _) = primitives[0] else {
            return XCTFail("Expected colorMatrix as first primitive")
        }
        XCTAssertEqual(values, [1])

        XCTAssertEqual(
            primitives[1],
            .offset(
                dx: 7,
                dy: -4,
                inSource: "SourceGraphic",
                result: nil
            )
        )

        guard case .blend(
            let blendMode,
            let inSource,
            let inSourceTwo,
            let result
        ) = primitives[2] else {
            return XCTFail("Expected blend as third primitive")
        }
        XCTAssertEqual(blendMode, "multiply")
        XCTAssertEqual(inSource, "SourceGraphic")
        XCTAssertEqual(inSourceTwo, "SourceGraphic")
        XCTAssertNil(result)

        let filterDefinition = try XCTUnwrap(document.filterDefinitions["supported"])
        XCTAssertFalse(filterDefinition.hasUnsupportedPrimitives)
        XCTAssertTrue(filterDefinition.hasSupportedPrimitives)
        XCTAssertEqual(
            filterDefinition.primitives.filter { primitive in
                if case .unsupported = primitive {
                    return true
                }
                return false
            }.count,
            0
        )
    }

    func testParseTracksSupportedCompositePrimitive() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="composite">
              <feComposite operator="in" in="SourceGraphic" in2="SourceAlpha" k1="0.2" k2="0.3" k3="0.4" k4="0.5"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#composite)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["composite"]?.primitives)
        XCTAssertEqual(primitives.count, 1)
        guard case .composite(
            let operatorType,
            let inSource,
            let inSourceTwo,
            let k1,
            let k2,
            let k3,
            let k4,
            let result
        ) = primitives[0] else {
            return XCTFail("Expected composite filter primitive")
        }
        XCTAssertEqual(operatorType, "in")
        XCTAssertEqual(inSource, "SourceGraphic")
        XCTAssertEqual(inSourceTwo, "SourceAlpha")
        XCTAssertEqual(k1, 0.2)
        XCTAssertEqual(k2, 0.3)
        XCTAssertEqual(k3, 0.4)
        XCTAssertEqual(k4, 0.5)
        XCTAssertNil(result)
        XCTAssertFalse(document.filterDefinitions["composite"]?.hasUnsupportedPrimitives == true)
    }

    func testParseTracksCompositeArithmeticPrimitive() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="composite-arithmetic">
              <feComposite
                operator="arithmetic"
                in="SourceGraphic"
                in2="SourceAlpha"
                k1="0.7"
                k2="0.2"
                k3="0.4"
                k4="0.1"/>
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#composite-arithmetic)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["composite-arithmetic"]?.primitives)
        XCTAssertEqual(primitives.count, 1)
        guard case .composite(
            let operatorType,
            let inSource,
            let inSourceTwo,
            let k1,
            let k2,
            let k3,
            let k4,
            let result
        ) = primitives[0] else {
            return XCTFail("Expected composite filter primitive")
        }
        XCTAssertEqual(operatorType, "arithmetic")
        XCTAssertEqual(inSource, "SourceGraphic")
        XCTAssertEqual(inSourceTwo, "SourceAlpha")
        XCTAssertEqual(k1, 0.7)
        XCTAssertEqual(k2, 0.2)
        XCTAssertEqual(k3, 0.4)
        XCTAssertEqual(k4, 0.1)
        XCTAssertNil(result)
    }

    func testParseDefaultsCompositeOperatorAndTrimmedSources() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="composite-defaults">
              <feComposite in=" SourceGraphic " in2=" SourceAlpha " k1="0.5" />
            </filter>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" filter="url(#composite-defaults)" />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["composite-defaults"]?.primitives)
        XCTAssertEqual(primitives.count, 1)
        guard case .composite(
            let operatorType,
            let inSource,
            let inSourceTwo,
            let k1,
            let k2,
            let k3,
            let k4,
            let result
        ) = primitives[0] else {
            return XCTFail("Expected composite filter primitive")
        }
        XCTAssertEqual(operatorType, "over")
        XCTAssertEqual(inSource, "SourceGraphic")
        XCTAssertEqual(inSourceTwo, "SourceAlpha")
        XCTAssertEqual(k1, 0.5)
        XCTAssertEqual(k2, 0)
        XCTAssertEqual(k3, 0)
        XCTAssertEqual(k4, 0)
        XCTAssertNil(result)
    }

    func testParseIgnoresWhitespaceOnlyCompositeResultName() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="composite-result-space">
              <feComposite operator="in" in="SourceGraphic" in2="SourceAlpha" result="   "/>
            </filter>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" filter="url(#composite-result-space)" />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["composite-result-space"]?.primitives)
        XCTAssertEqual(primitives.count, 1)
        guard case .composite(
            let operatorType,
            let inSource,
            let inSourceTwo,
            let k1,
            let k2,
            let k3,
            let k4,
            let result
        ) = primitives[0] else {
            return XCTFail("Expected composite filter primitive")
        }
        XCTAssertEqual(operatorType, "in")
        XCTAssertEqual(inSource, "SourceGraphic")
        XCTAssertEqual(inSourceTwo, "SourceAlpha")
        XCTAssertEqual(k1, 0)
        XCTAssertEqual(k2, 0)
        XCTAssertEqual(k3, 0)
        XCTAssertEqual(k4, 0)
        XCTAssertNil(result)
    }

    func testParseKeepsUnsupportedFilterPrimitives() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="unsupported">
              <feColorMatrix values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0"/>
              <feFlood flood-color="red" />
            </filter>
          </defs>
          <rect
            id="foreground"
            x="0"
            y="0"
            width="20"
            height="20"
            filter="url(#unsupported)"
          />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["unsupported"]?.primitives)
        XCTAssertEqual(primitives.count, 2)
        XCTAssertEqual(
            primitives[0],
            .colorMatrix(
                values: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
                inSource: "SourceGraphic",
                result: nil
            )
        )
        guard case .unsupported(let unsupportedType, _) = primitives[1] else {
            return XCTFail("Expected unsupported filter primitive after supported colorMatrix")
        }
        XCTAssertEqual(unsupportedType, "feflood")
        XCTAssertTrue(document.filterDefinitions["unsupported"]?.hasUnsupportedPrimitives == true)
        XCTAssertTrue(document.filterDefinitions["unsupported"]?.hasSupportedPrimitives == true)
    }

    func testParseTracksUnsupportedElementFeatures() throws {
        let svg = """
        <svg>
          <text id="label">unsupported tag</text>
          <rect id="supported" x="0" y="0" width="10" height="10"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNil(document.unsupportedFeatures["element:text"])
        XCTAssertNil(pathNode(id: "label", in: document))

        guard let supportedRect = shapeNode(id: "supported", in: document) else {
            return XCTFail("Expected supported rect node")
        }
        XCTAssertEqual(supportedRect.kind, .rect)
    }

    func testParseTracksUnsupportedFilterPrimitivesInFeatures() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="unsupported">
              <feFlood flood-color="red" />
            </filter>
          </defs>
          <rect id="supported" x="0" y="0" width="10" height="10" filter="url(#unsupported)"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(document.unsupportedFeatures["filter:feflood"], 1)

        guard let primitive = document.filterDefinitions["unsupported"]?.primitives.first else {
            return XCTFail("Expected unsupported filter primitive")
        }
        guard case .unsupported = primitive else {
            return XCTFail("Expected filter primitive to be unsupported")
        }
        XCTAssertEqual(document.nodes.count, 1)
    }

    func testParseTracksUnsupportedFeaturesFromEmbeddedSVG() throws {
        let embeddedSVG = """
        <svg>
          <rect id="embedded-supported" x="0" y="0" width="4" height="5"/>
          <text id="embedded-unsupported">embedded</text>
        </svg>
        """
        let source = """
        <svg>
          <image href="\(makeDataURISource(from: embeddedSVG))"/>
        </svg>
        """

        let document = try parser.parse(
            source: .string(source),
            options: SVGParserOptions(enableDataURI: true)
        )

        XCTAssertNil(document.unsupportedFeatures["element:text"])
        XCTAssertEqual(document.nodes.count, 1)
        XCTAssertEqual(document.nodes.first?.nodeID, "auto:/0/0")
        guard case .group(let embeddedGroup) = document.nodes.first else {
            return XCTFail("Expected embedded image to be expanded as group node")
        }
        guard case .shape(let embeddedShape) = embeddedGroup.children.first else {
            return XCTFail("Expected embedded rect shape")
        }
        XCTAssertEqual(embeddedShape.base.id, "embedded-supported")
    }

    func testParseCapturesSupportedSMILElementsAsAnimations() throws {
        let svg = """
        <svg width='120' height='120'>
          <g id='motion-group'>
            <animate attributeName='opacity' values='0;1;0' dur='3s' begin='1s;2.5s'/>
          </g>
          <circle id='target' cx='50' cy='50' r='20'>
            <set attributeName='opacity' to='0.5' begin='500ms' dur='2s'/>
          </circle>
          <rect id='spin' width='10' height='10'>
            <animateTransform attributeName='transform' type='rotate' from='0 5 5' to='360 5 5' dur='4s' repeatCount='indefinite'/>
          </rect>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(document.animations.count, 3)
        XCTAssertNil(document.unsupportedFeatures["element:animate"])
        XCTAssertNil(document.unsupportedFeatures["element:set"])
        XCTAssertNil(document.unsupportedFeatures["element:animatetransform"])

        let motionGroupAnimation = animation(forTargetID: "motion-group", in: document, kind: .animate)
        XCTAssertEqual(motionGroupAnimation?.targetElementID, "motion-group")
        XCTAssertEqual(motionGroupAnimation?.targetSyntheticID, "auto:/0/0")
        XCTAssertEqual(motionGroupAnimation?.timing.dur, 3.0)
        XCTAssertEqual(motionGroupAnimation?.timing.begin, [1.0, 2.5])
        XCTAssertEqual(motionGroupAnimation?.interpolation, .linear)
        XCTAssertEqual(motionGroupAnimation?.values?.kind, "values")

        let targetCircleAnimation = animation(forTargetID: "target", in: document, kind: .set)
        XCTAssertEqual(targetCircleAnimation?.attributes["attributename"], "opacity")
        XCTAssertEqual(targetCircleAnimation?.timing.begin, [0.5])
        XCTAssertEqual(targetCircleAnimation?.timing.dur, 2.0)
        XCTAssertEqual(targetCircleAnimation?.attributeName, "opacity")
        XCTAssertEqual(targetCircleAnimation?.values, nil)

        let rectAnimation = animation(forTargetID: "spin", in: document, kind: .animateTransform)
        XCTAssertEqual(rectAnimation?.attributes["from"], "0 5 5")
        XCTAssertEqual(rectAnimation?.type, "rotate")
        XCTAssertEqual(rectAnimation?.fromValue, "0 5 5")
        XCTAssertEqual(rectAnimation?.toValue, "360 5 5")
        XCTAssertEqual(rectAnimation?.timing.repeatCount, .indefinite)
        XCTAssertEqual(rectAnimation?.timing.repeatDur, nil)
    }

    func testAnimationTargetLookupMapsByIDAndSyntheticID() throws {
        let svg = """
        <svg width='120' height='120'>
          <circle>
            <animate attributeName='opacity' from='0' to='1' dur='2s'/>
          </circle>
          <rect id='target' width='10' height='10'>
            <set attributeName='opacity' to='0.5' dur='1s'/>
          </rect>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let rectAnimation = animation(forTargetID: "target", in: document, kind: .set)
        XCTAssertNotNil(rectAnimation)
        XCTAssertEqual(document.animationIDs(forTargetID: "target").count, 1)
        XCTAssertEqual(document.animationIDs(forTargetID: "target", includeSyntheticID: false).count, 1)
        XCTAssertEqual(
            document.animationsByTargetID["target"]?.count,
            1
        )

        let circleAnimation = document.animations.first(where: { animation in
            animation.kind == .animate && animation.targetElementID != "target"
        })
        let circleTargetID = try XCTUnwrap(circleAnimation?.targetElementID)
        XCTAssertEqual(document.animationIDs(forTargetID: circleTargetID).count, 1)
        XCTAssertEqual(document.animationsByTargetID[circleTargetID]?.count, 1)
    }

    func testNodeStoresSMILAnimationReferences() throws {
        let svg = """
        <svg width='120' height='120'>
          <g id='target-group'>
            <animate attributeName='opacity' from='0' to='1' dur='2s'/>
          </g>
          <circle>
            <animateTransform attributeName='transform' type='rotate' from='0' to='360' dur='4s'/>
          </circle>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let targetGroup = try XCTUnwrap(groupNode(id: "target-group", in: document))
        let groupRefs = targetGroup.base.animationReferences
        XCTAssertEqual(groupRefs.count, 1)
        guard let groupBinding = groupRefs.first else {
            return XCTFail("Expected one animation binding on target-group node")
        }
        XCTAssertEqual(
            document.animations[groupBinding.animationIndex].attributeName,
            "opacity"
        )

        let allShapes = allNodes(in: document).compactMap { node -> SVGShapeNode? in
            if case .shape(let shape) = node, shape.kind == .circle {
                return shape
            }
            return nil
        }
        let circle = try XCTUnwrap(allShapes.first(where: { $0.base.id == nil }))
        let circleRefs = circle.base.animationReferences
        XCTAssertEqual(circleRefs.count, 1)
        let circleBinding = try XCTUnwrap(circleRefs.first)
        XCTAssertEqual(document.animations[circleBinding.animationIndex].kind, .animateTransform)
        XCTAssertEqual(document.animations[circleBinding.animationIndex].attributeName, "transform")
        XCTAssertEqual(document.animations[circleBinding.animationIndex].type, "rotate")
    }

    func testParseSMILCalcModeAndUnsupportedTimeSyntaxFallsBackToDefaults() throws {
        let svg = """
        <svg>
          <rect id='target' width='10' height='10'>
            <animate attributeName='opacity' from='0' to='1' calcMode='paced' begin='invalid;1.5s' dur='indefinite'/>
          </rect>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard let animation = animation(forTargetID: "target", in: document, kind: .animate) else {
            return XCTFail("Expected animate to be collected")
        }

        XCTAssertEqual(animation.interpolation, .paced)
        XCTAssertEqual(animation.timing.begin, [1.5])
        XCTAssertNil(animation.timing.dur)
        XCTAssertEqual(animation.timing.fill, .remove)
    }

    func testParseFallsBackToUnsupportedForUnknownSMILElements() throws {
        let svg = """
        <svg>
          <circle id='target' cx='50' cy='50' r='20'>
            <animateColor values='red;blue;red' dur='3s'/>
          </circle>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertTrue(document.animations.isEmpty)
        XCTAssertEqual(document.unsupportedFeatures["element:animatecolor"], 1)
    }

    func testParseReadsFilterPrimitiveChainInputsAndResults() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="chain">
              <feGaussianBlur stdDeviation="1.5" in="SourceGraphic" result="blur"/>
              <feOffset dx="4" dy="1" in="blur" result="shifted"/>
              <feBlend in="shifted" in2="SourceGraphic" mode="multiply" result="mixed"/>
              <feColorMatrix in="mixed" result="final" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0"/>
            </filter>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" filter="url(#chain)" />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["chain"]?.primitives)
        XCTAssertEqual(primitives.count, 4)
        XCTAssertEqual(
            primitives[0],
            .gaussianBlur(
                stdDeviationX: 1.5,
                stdDeviationY: 1.5,
                inSource: "SourceGraphic",
                result: "blur"
            )
        )
        XCTAssertEqual(
            primitives[1],
            .offset(
                dx: 4,
                dy: 1,
                inSource: "blur",
                result: "shifted"
            )
        )
        XCTAssertEqual(
            primitives[2],
            .blend(
                mode: "multiply",
                inSource: "shifted",
                inSourceTwo: "SourceGraphic",
                result: "mixed"
            )
        )
        guard case .colorMatrix(let values, let inSource, let result) = primitives[3] else {
            return XCTFail("Expected colorMatrix as chain fourth primitive")
        }
        XCTAssertEqual(
            values,
            [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
        )
        XCTAssertEqual(inSource, "mixed")
        XCTAssertEqual(result, "final")
    }

    func testParseReadsFilterChainSourcesWithWhitespaceTrimmed() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="chain-space">
              <feGaussianBlur stdDeviation="1" in=" SourceGraphic " result=" blurred "/>
              <feOffset dx="2" dy="1" in="blurred" result=" shifted "/>
              <feBlend in="shifted" in2=" SourceGraphic " mode="multiply"/>
            </filter>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" filter="url(#chain-space)" />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["chain-space"]?.primitives)
        XCTAssertEqual(primitives.count, 3)
        XCTAssertEqual(
            primitives[0],
            .gaussianBlur(
                stdDeviationX: 1,
                stdDeviationY: 1,
                inSource: "SourceGraphic",
                result: "blurred"
            )
        )
        XCTAssertEqual(
            primitives[1],
            .offset(
                dx: 2,
                dy: 1,
                inSource: "blurred",
                result: "shifted"
            )
        )
        XCTAssertEqual(
            primitives[2],
            .blend(
                mode: "multiply",
                inSource: "shifted",
                inSourceTwo: "SourceGraphic",
                result: nil
            )
        )
    }

    func testParseRetainsChainResultNamesForRendererInputs() throws {
        let svg = """
        <svg>
          <defs>
            <filter id="chain-guard">
              <feGaussianBlur stdDeviation="1.5" in="SourceAlpha" result="shadow"/>
              <feOffset dx="1" dy="2" in="ghost" result="shifted"/>
              <feBlend in="shifted" in2="shadow" mode="screen" result="merged"/>
            </filter>
          </defs>
          <rect id="foreground" x="0" y="0" width="20" height="20" filter="url(#chain-guard)" />
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        let primitives = try XCTUnwrap(document.filterDefinitions["chain-guard"]?.primitives)
        XCTAssertEqual(primitives.count, 3)
        XCTAssertEqual(
            primitives[0],
            .gaussianBlur(
                stdDeviationX: 1.5,
                stdDeviationY: 1.5,
                inSource: "SourceAlpha",
                result: "shadow"
            )
        )
        XCTAssertEqual(
            primitives[1],
            .offset(
                dx: 1,
                dy: 2,
                inSource: "ghost",
                result: "shifted"
            )
        )
        XCTAssertEqual(
            primitives[2],
            .blend(
                mode: "screen",
                inSource: "shifted",
                inSourceTwo: "shadow",
                result: "merged"
            )
        )
    }

    func testParseIgnoresFilterAndMaskElementsButKeepsSupportedSiblings() throws {
        let svg = """
        <svg width="20" height="20">
          <filter id="blur">
            <ellipse cx="10" cy="10" rx="5" ry="5"/>
          </filter>
          <path id="base" d="M0 0 L20 20"/>
          <mask id="mask">
            <rect x="0" y="0" width="10" height="10"/>
          </mask>
          <path id="visible" d="M0 20 L20 0"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNotNil(document.filterDefinitions["blur"])
        XCTAssertNil(shapeNode(id: "blur", in: document))
        XCTAssertNil(shapeNode(id: "mask", in: document))
        XCTAssertEqual(pathNode(id: "base", in: document)?.pathData, "M0 0 L20 20")
        XCTAssertEqual(pathNode(id: "visible", in: document)?.pathData, "M0 20 L20 0")
    }

    func testParseIgnoresNestedSVGSubtrees() throws {
        let svg = """
        <svg>
          <svg>
            <path id="nested-path" d="M0 0"/>
          </svg>
          <path id="top-path" d="M1 1"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertNil(pathNode(id: "nested-path", in: document))
        XCTAssertEqual(pathNode(id: "top-path", in: document)?.pathData, "M1 1")
    }

    func testParseBuildsTreeForGroupPathAndRect() throws {
        let svg = """
        <svg width="100" height="100">
          <g id="icon-group" transform="translate(4 8)">
            <path id="main-path" d="M0 0 L10 10" fill="#ff0000"/>
            <rect id="box" x="1" y="2" width="3" height="4" />
          </g>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))

        XCTAssertEqual(document.nodes.count, 1)
        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected group node")
        }
        XCTAssertEqual(group.base.id, "icon-group")
        XCTAssertEqual(group.base.transform.operations.count, 1)
        XCTAssertEqual(group.children.count, 2)

        guard case .path(let pathNode) = group.children[0] else {
            return XCTFail("Expected path node")
        }
        XCTAssertEqual(pathNode.base.id, "main-path")
        XCTAssertEqual(pathNode.pathData, "M0 0 L10 10")
        XCTAssertEqual(pathNode.commands, [
            .init(symbol: "M", values: [0, 0]),
            .init(symbol: "L", values: [10, 10]),
        ])

        guard case .shape(let rectNode) = group.children[1] else {
            return XCTFail("Expected shape node")
        }
        XCTAssertEqual(rectNode.kind, .rect)
        XCTAssertEqual(rectNode.values["x"], 1)
        XCTAssertEqual(rectNode.values["y"], 2)
        XCTAssertEqual(rectNode.values["width"], 3)
        XCTAssertEqual(rectNode.values["height"], 4)
    }

    func testParseGeneratesDeterministicSyntheticIDs() throws {
        let svg = """
        <svg>
          <g>
            <path/>
            <rect/>
          </g>
          <circle/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))

        guard case .group(let group) = document.nodes[0] else {
            return XCTFail("Expected first root node as group")
        }
        XCTAssertEqual(group.base.syntheticID, "auto:/0/0")

        guard case .path(let path) = group.children[0] else {
            return XCTFail("Expected first child path")
        }
        XCTAssertEqual(path.base.syntheticID, "auto:/0/0/0")

        guard case .shape(let rect) = group.children[1] else {
            return XCTFail("Expected second child rect")
        }
        XCTAssertEqual(rect.base.syntheticID, "auto:/0/0/1")

        guard case .shape(let circle) = document.nodes[1] else {
            return XCTFail("Expected second root node circle")
        }
        XCTAssertEqual(circle.base.syntheticID, "auto:/0/1")
    }

    func testInlineStyleOverridesPresentationAttributes() throws {
        let svg = """
        <svg width="24" height="24">
          <path d="M0 0 L1 1" fill="black" style="fill:#00ff00;stroke:#0000ff;stroke-width:2;opacity:0.5"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard case .path(let path) = document.nodes.first else {
            return XCTFail("Expected path node")
        }
        XCTAssertEqual(path.base.style.fill, .color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(path.base.style.stroke, .color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(path.base.style.strokeWidth, 2)
        XCTAssertEqual(path.base.style.opacity, 0.5)
    }

    func testStyleTagIgnoredWhenDisabled() throws {
        let svg = """
        <svg width="24" height="24">
          <style>
            .hidden { fill: #ff00ff; }
          </style>
          <path id="ignored" d="M0 0 L1 1"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg), options: .init())
        XCTAssertTrue(document.styleRules.isEmpty)
    }

    func testStyleTagParsedWhenEnabled() throws {
        let svg = """
        <svg width="24" height="24">
          <style>
            #primary {
              fill: #00ff00;
              stroke-width: 2;
            }
          </style>
          <path id="target" d="M0 0 L1 1"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg), options: .init(enableStyleTag: true))
        XCTAssertEqual(document.styleRules.count, 1)

        let rule = tryUnwrap(document.styleRules.first)
        guard case .id("primary") = rule.selector else {
            return XCTFail("Expected id selector")
        }
        XCTAssertEqual(rule.declarations["fill"], "#00ff00")
        XCTAssertEqual(rule.declarations["stroke-width"], "2")
    }

    func testStyleTagSupportsMultipleSelectors() throws {
        let svg = """
        <svg width="24" height="24">
          <style>
            #primary, .secondary, path { fill: blue; opacity: 0.75; }
          </style>
          <path id="p" d="M0 0 L1 1"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg), options: .init(enableStyleTag: true))
        XCTAssertEqual(document.styleRules.count, 3)

        guard case .id("primary") = document.styleRules[0].selector else {
            return XCTFail("Expected id selector")
        }
        guard case .class("secondary") = document.styleRules[1].selector else {
            return XCTFail("Expected class selector")
        }
        guard case .element("path") = document.styleRules[2].selector else {
            return XCTFail("Expected element selector")
        }
        XCTAssertEqual(document.styleRules[1].declarations["fill"], "blue")
    }

    func testParseImageNodeExpandsDataURIEmbeddedSVG() throws {
        let embedded = """
        <svg>
          <path id="embedded-path" d="M0 0 L10 10"/>
        </svg>
        """

        let uri = makeDataURISource(from: embedded)
        let document = try parser.parse(
            source: .string("<svg><image href=\"\(uri)\"/></svg>"),
            options: SVGParserOptions(enableDataURI: true)
        )

        XCTAssertEqual(document.nodes.count, 1)
        guard case .group(let imageGroup) = document.nodes[0] else {
            return XCTFail("Expected group wrapper for embedded image")
        }
        XCTAssertEqual(imageGroup.children.count, 1)

        guard case .path(let pathNode) = imageGroup.children[0] else {
            return XCTFail("Expected embedded path node")
        }
        XCTAssertEqual(pathNode.pathData, "M0 0 L10 10")
        XCTAssertEqual(pathNode.base.syntheticID, "auto:/0/0/embedded/0")
    }

    func testParseImageNodeIgnoresRasterDataURINodeByDefault() throws {
        let source = "<svg><image href=\"data:image/png;base64,iVBORw0KGgo=\"/></svg>"
        let document = try parser.parse(
            source: .string(source),
            options: SVGParserOptions(enableDataURI: true)
        )
        XCTAssertEqual(document.nodes.count, 0)
    }

    func testParseImageNodeRendersRasterDataURINodeWhenPolicyIsRenderRaster() throws {
        let source = """
        <svg>
          <image id="logo" x="4" y="5" width="10" height="20" href="data:image/png;base64,iVBORw0KGgo="/>
        </svg>
        """
        let document = try parser.parse(
            source: .string(source),
            options: SVGParserOptions(
                enableDataURI: true,
                imageNodePolicy: .renderRaster
            )
        )

        XCTAssertEqual(document.nodes.count, 1)
        guard case .rasterImage(let imageNode) = document.nodes[0] else {
            return XCTFail("Expected raster image node")
        }
        XCTAssertEqual(imageNode.base.id, "logo")
        XCTAssertEqual(imageNode.base.attributes["href"], "data:image/png;base64,iVBORw0KGgo=")
        XCTAssertEqual(imageNode.x, 4)
        XCTAssertEqual(imageNode.y, 5)
        XCTAssertEqual(imageNode.width, 10)
        XCTAssertEqual(imageNode.height, 20)
        XCTAssertEqual(imageNode.mediaType, "image/png")
    }

    func testParseImageNodeFailsOnRasterDataURINodeWhenPolicyFailOnRaster() {
        let source = "<svg><image href=\"data:image/png;base64,iVBORw0KGgo=\"/></svg>"
        XCTAssertThrowsError(
            try parser.parse(
                source: .string(source),
                options: SVGParserOptions(
                    enableDataURI: true,
                    imageNodePolicy: .failOnRaster
                )
            )
        ) { error in
            guard case .notImplemented = error as? SVGParserError else {
                return XCTFail("Expected notImplemented error, got \(error)")
            }
        }
    }

    func testParseImageNodeSupportsNestedImageDataURIs() throws {
        let leaf = """
        <svg>
          <path id="leaf-path" d="M1 2 L3 4"/>
        </svg>
        """

        let mid = """
        <svg>
          <image xlink:href="\(makeDataURISource(from: leaf))"/>
        </svg>
        """
        let outer = """
        <svg>
          <image href="\(makeDataURISource(from: mid))"/>
        </svg>
        """

        let document = try parser.parse(
            source: .string(outer),
            options: SVGParserOptions(enableDataURI: true)
        )

        XCTAssertEqual(document.nodes.count, 1)
        guard case .group(let outerGroup) = document.nodes[0] else {
            return XCTFail("Expected first level embedded group")
        }
        XCTAssertEqual(outerGroup.children.count, 1)
        guard case .group(let innerGroup) = outerGroup.children[0] else {
            return XCTFail("Expected second level embedded group")
        }
        XCTAssertEqual(innerGroup.children.count, 1)
        guard case .path(let leafPath) = innerGroup.children[0] else {
            return XCTFail("Expected leaf path")
        }
        XCTAssertEqual(leafPath.pathData, "M1 2 L3 4")
        XCTAssertTrue(leafPath.base.syntheticID.contains("/embedded/0/embedded/0"))
    }

    func testEmbeddedImageRespectsMaxCount() throws {
        let payload = """
        <svg>
          <path id="payload-path" d="M0 0 L5 5"/>
        </svg>
        """

        let uri = makeDataURISource(from: payload)
        let source = "<svg><image href=\"\(uri)\"/><image href=\"\(uri)\"/></svg>"

        let document = try parser.parse(
            source: .string(source),
            options: SVGParserOptions(enableDataURI: true, maxEmbeddedImageCount: 1)
        )

        XCTAssertEqual(document.nodes.count, 1)
    }

    func testEmbeddedImageRespectsMaxDepth() throws {
        let leaf = "<svg><path d=\"M0 0 L1 1\"/></svg>"
        let nestedImage = """
        <svg>
          <image href="\(makeDataURISource(from: leaf))"/>
        </svg>
        """
        let source = """
        <svg>
          <image href="\(makeDataURISource(from: nestedImage))"/>
        </svg>
        """
        let document = try parser.parse(
            source: .string(source),
            options: SVGParserOptions(enableDataURI: true, maxEmbeddedImageDepth: 1)
        )

        XCTAssertEqual(document.nodes.count, 0)
    }

    func testParseSupportsMultiplePaintFormats() throws {
        let svg = """
        <svg>
          <path id="hex3" d="M0 0" fill="#0f0"/>
          <path id="rgb" d="M0 0" fill="rgb(255, 0, 0)"/>
          <path id="named" d="M0 0" fill="blue"/>
          <path id="none" d="M0 0" fill="none"/>
          <path id="current" d="M0 0" fill="currentColor"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        XCTAssertEqual(pathNode(id: "hex3", in: document)?.base.style.fill, .color(.init(red: 0, green: 1, blue: 0, alpha: 1)))
        XCTAssertEqual(pathNode(id: "rgb", in: document)?.base.style.fill, .color(.init(red: 1, green: 0, blue: 0, alpha: 1)))
        XCTAssertEqual(pathNode(id: "named", in: document)?.base.style.fill, .color(.init(red: 0, green: 0, blue: 1, alpha: 1)))
        XCTAssertEqual(pathNode(id: "none", in: document)?.base.style.fill, SVGPaint.none)
        XCTAssertEqual(pathNode(id: "current", in: document)?.base.style.fill, .currentColor)
    }

    func testParseTransformOperationsInOrder() throws {
        let svg = """
        <svg>
          <path id="t" d="M0 0" transform="translate(10,20) scale(2) rotate(90 1 2) matrix(1 0 0 1 3 4)"/>
        </svg>
        """
        let document = try parser.parse(source: .string(svg))
        let operations = pathNode(id: "t", in: document)?.base.transform.operations

        XCTAssertEqual(operations, [
            .translate(tx: 10, ty: 20),
            .scale(sx: 2, sy: 2),
            .rotate(angleDegrees: 90, cx: 1, cy: 2),
            .matrix(a: 1, b: 0, c: 0, d: 1, tx: 3, ty: 4),
        ])
    }

    func testParseSkewTransformOperations() throws {
        let svg = """
        <svg>
          <path id="t" d="M0 0" transform="skewX(30) skewY(-20)"/>
        </svg>
        """
        let operations = try parser.parse(source: .string(svg))
            .nodes
            .compactMap { node in
                if case .path(let path) = node { return path.base.transform.operations }
                return nil
            }

        XCTAssertEqual(operations, [[.skewX(angleDegrees: 30), .skewY(angleDegrees: -20)]])
    }

    func testParseRoundedRectRadii() throws {
        let document = try parser.parse(source: .string("<svg><rect id='r' x='1' y='2' width='10' height='20' rx='3' ry='4'/></svg>"))
        guard let rect = shapeNode(id: "r", in: document) else {
            return XCTFail("Expected rounded rect node")
        }

        XCTAssertEqual(rect.values["rx"], 3)
        XCTAssertEqual(rect.values["ry"], 4)
    }

    func testParseStrokeCapAndJoinStyles() throws {
        let document = try parser.parse(source: .string("""
        <svg>
          <path
            id="styled"
            d="M0 0"
            stroke-linecap="square"
            stroke-linejoin="bevel"
            style="stroke-linecap: round; stroke-linejoin: miter;"
          />
        </svg>
        """))
        guard case .path(let pathNode) = document.nodes.first else {
            return XCTFail("Expected path node")
        }

        XCTAssertEqual(pathNode.base.style.strokeLineCap, .round)
        XCTAssertEqual(pathNode.base.style.strokeLineJoin, .miter)
    }

    func testParseAdvancedStylingProperties() throws {
        let document = try parser.parse(source: .string("""
        <svg>
          <path
            id="attr-style"
            d="M0 0"
            fill-rule="evenodd"
            stroke-miterlimit="8"
            stroke-dasharray="6 4 2"
            stroke-dashoffset="1.25"
          />
          <path
            id="inline-style"
            d="M1 1"
            style="fill-rule: nonzero; stroke-dasharray: none; stroke-miterlimit: 2.75;"
          />
        </svg>
        """))

        guard let attrStylePath = pathNode(id: "attr-style", in: document) else {
            return XCTFail("Expected attr-style path node")
        }
        XCTAssertEqual(attrStylePath.base.style.fillRule, .evenOdd)
        XCTAssertEqual(attrStylePath.base.style.strokeMiterLimit, 8)
        XCTAssertEqual(attrStylePath.base.style.strokeDashArray, [6, 4, 2])
        XCTAssertEqual(attrStylePath.base.style.strokeDashOffset, 1.25)

        guard let inlineStylePath = pathNode(id: "inline-style", in: document) else {
            return XCTFail("Expected inline-style path node")
        }
        XCTAssertEqual(inlineStylePath.base.style.fillRule, .nonZero)
        XCTAssertEqual(inlineStylePath.base.style.strokeDashArray, [])
        XCTAssertEqual(inlineStylePath.base.style.strokeMiterLimit, 2.75)
    }

    func testParseFontPropertiesFromAttributesAndInlineStyle() throws {
        let document = try parser.parse(source: .string("""
        <svg>
          <text id="font-style" x="10" y="20" font-family=" 'Helvetica Neue' , Arial " font-style="italic" font-weight="bold">hello</text>
          <text id="font-inline" x="10" y="40" style='font-family: "Times New Roman", serif; font-style: oblique; font-weight: 500; font-size: 24px;'>world</text>
        </svg>
        """))

        guard case .text(let first) = document.nodes[0] else {
            return XCTFail("Expected first text node")
        }
        XCTAssertEqual(first.base.style.fontFamily, "Helvetica Neue")
        XCTAssertEqual(first.base.style.fontStyle, .italic)
        XCTAssertEqual(first.base.style.fontWeight, .bold)
        XCTAssertNil(first.base.style.fontSize)

        guard case .text(let second) = document.nodes[1] else {
            return XCTFail("Expected second text node")
        }
        XCTAssertEqual(second.base.style.fontFamily, "Times New Roman")
        XCTAssertEqual(second.base.style.fontStyle, .oblique)
        XCTAssertEqual(second.base.style.fontWeight, .numeric(500))
        XCTAssertEqual(second.base.style.fontSize, 24)
    }

    func testParsePathWithoutDUsesEmptyString() throws {
        let document = try parser.parse(source: .string("<svg><path id='empty'/></svg>"))
        XCTAssertEqual(pathNode(id: "empty", in: document)?.pathData, "")
        XCTAssertEqual(pathNode(id: "empty", in: document)?.commands, [])
    }

    func testParseThrowsMalformedDocumentForInvalidPathData() {
        let svg = "<svg><path d='R 10 10'/></svg>"
        XCTAssertThrowsError(try parser.parse(source: .string(svg))) { error in
            guard case .malformedDocument = (error as? SVGParserError) else {
                return XCTFail("Expected malformedDocument, got \(error)")
            }
        }
    }

    func testParseNumericAcceptsPxValuesForShapeAttributes() throws {
        let document = try parser.parse(source: .string("<svg><rect id='r' x='1px' y='2px' width='3px' height='4px'/></svg>"))
        guard let rect = shapeNode(id: "r", in: document) else {
            return XCTFail("Expected rect node")
        }
        XCTAssertEqual(rect.values["x"], 1)
        XCTAssertEqual(rect.values["y"], 2)
        XCTAssertEqual(rect.values["width"], 3)
        XCTAssertEqual(rect.values["height"], 4)
    }

    func testParsePolylinePoints() throws {
        let svg = """
        <svg width="24" height="24">
          <polyline points="0,0 10,10 20,5"/>
        </svg>
        """

        let document = try parser.parse(source: .string(svg))
        guard case .shape(let polyline) = document.nodes.first else {
            return XCTFail("Expected polyline node")
        }
        XCTAssertEqual(polyline.kind, .polyline)
        XCTAssertEqual(polyline.points, [
            .init(x: 0, y: 0),
            .init(x: 10, y: 10),
            .init(x: 20, y: 5),
        ])
    }

    func testParsePolygonDropsTrailingOddCoordinate() throws {
        let svg = """
        <svg width="24" height="24">
          <polygon id="pg" points="0,0 10,10 20"/>
        </svg>
        """
        let document = try parser.parse(source: .string(svg))
        guard let polygon = shapeNode(id: "pg", in: document) else {
            return XCTFail("Expected polygon node")
        }
        XCTAssertEqual(polygon.points, [
            .init(x: 0, y: 0),
            .init(x: 10, y: 10),
        ])
    }

    private func allNodes(in document: SVGDocument) -> [SVGNode] {
        flatten(document.nodes)
    }

    private func flatten(_ nodes: [SVGNode]) -> [SVGNode] {
        var output: [SVGNode] = []
        for node in nodes {
            output.append(node)
            if case .group(let group) = node {
                output.append(contentsOf: flatten(group.children))
            }
        }
        return output
    }

    private func pathNode(id: String, in document: SVGDocument) -> SVGPathNode? {
        for node in allNodes(in: document) {
            if case .path(let path) = node, path.base.id == id {
                return path
            }
        }
        return nil
    }

    private func animation(forTargetID targetID: String, in document: SVGDocument, kind: SVGSMILAnimationKind) -> SVGSMILAnimation? {
        for animation in document.animations {
            if animation.targetElementID == targetID && animation.kind == kind {
                return animation
            }
        }
        return nil
    }

    private func groupNode(id: String, in document: SVGDocument) -> SVGGroupNode? {
        for node in allNodes(in: document) {
            if case .group(let group) = node, group.base.id == id {
                return group
            }
        }
        return nil
    }

    private func shapeNode(id: String, in document: SVGDocument) -> SVGShapeNode? {
        for node in allNodes(in: document) {
            if case .shape(let shape) = node, shape.base.id == id {
                return shape
            }
        }
        return nil
    }

    private func makeDataURISource(from svgSource: String) -> String {
        let encoded: String = Data(svgSource.utf8).base64EncodedString()
        return "data:image/svg+xml;base64,\(encoded)"
    }

    private func tryUnwrap(_ rule: SVGStyleRule?) -> SVGStyleRule {
        guard let rule else {
            XCTFail("Expected style rule")
            return SVGStyleRule(selector: .any, declarations: [:])
        }
        return rule
    }
}
