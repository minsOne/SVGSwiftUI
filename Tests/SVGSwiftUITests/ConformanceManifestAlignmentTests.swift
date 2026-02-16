import Foundation
import XCTest

final class ConformanceManifestAlignmentTests: XCTestCase {
    private enum ConformanceSuite: String, CaseIterable {
        case w3c = "W3C"
        case webKit = "WebKit"

        var testManifestPath: String {
            switch self {
            case .w3c:
                return "W3C/w3c-manifest.json"
            case .webKit:
                return "WebKit/webkit-manifest.json"
            }
        }

        var demoManifestRelativePath: String {
            return testManifestPath
        }

        var demoFixtureDirectoryName: String {
            switch self {
            case .w3c:
                return "W3C/fixtures"
            case .webKit:
                return "WebKit/fixtures"
            }
        }
    }

    private enum FixtureMode: String, CaseIterable {
        case parse
        case render
    }

    private enum FixtureExpected: String, CaseIterable {
        case pass
        case fail
        case unsupported
    }

    private struct FixtureManifest: Decodable {
        let fixtures: [FixtureEntry]
    }

    private struct FixtureEntry: Decodable {
        let id: String
        let suite: String?
        let category: String?
        let mode: String
        let expected: String
        let svg: String
        let reference: String?
        let source: String?
    }

    func testConformanceManifestFixtureAlignment() throws {
        for suite in ConformanceSuite.allCases {
            try assertManifestAlignment(for: suite)
        }
    }

    private func assertManifestAlignment(for suite: ConformanceSuite) throws {
        let manifest = try loadManifest(from: suite.testManifestPath)
        let fixtureEntries = manifest.fixtures

        let manifestRelativePaths = Set(fixtureEntries.map { fixture in
            makeRelativeFixturePath(fixture.svg)
        })

        assertManifestMetadata(for: suite, entries: fixtureEntries)
        assertTestBundleFixtureExistence(for: suite, relativePaths: manifestRelativePaths)
        assertDemoBundleAlignment(for: suite, relativePaths: manifestRelativePaths)
    }

    private func assertManifestMetadata(for suite: ConformanceSuite, entries: [FixtureEntry]) {
        let allowedModes: Set<String> = Set(FixtureMode.allCases.map(\.rawValue))
        let allowedExpected: Set<String> = Set(FixtureExpected.allCases.map(\.rawValue))

        var seenIDs = Set<String>()
        var seenPaths = Set<String>()
        var duplicateIDs = Set<String>()
        var duplicatePaths = Set<String>()

        XCTAssertFalse(
            entries.isEmpty,
            "\(suite.rawValue) manifest가 비어 있습니다."
        )

        for entry in entries {
            let normalizedID = entry.id.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(
                normalizedID.isEmpty,
                "\(suite.rawValue) manifest에서 id가 빈 값입니다."
            )

            let normalizedSVGPath = makeRelativeFixturePath(entry.svg)
            XCTAssertFalse(
                normalizedSVGPath.isEmpty,
                "\(suite.rawValue) manifest에서 svg 경로가 빈 값입니다. (id: \(entry.id))"
            )
            XCTAssertTrue(
                normalizedSVGPath.hasSuffix(".svg"),
                "\(suite.rawValue) manifest의 svg가 .svg가 아닙니다. (id: \(entry.id), svg: \(normalizedSVGPath))"
            )

            XCTAssertTrue(
                allowedModes.contains(entry.mode),
                "\(suite.rawValue) manifest mode가 잘못되었습니다. (id: \(entry.id), mode: \(entry.mode))"
            )

            XCTAssertTrue(
                allowedExpected.contains(entry.expected),
                "\(suite.rawValue) manifest expected가 잘못되었습니다. (id: \(entry.id), expected: \(entry.expected))"
            )

            if !seenIDs.insert(normalizedID).inserted {
                duplicateIDs.insert(normalizedID)
            }

            if !seenPaths.insert(normalizedSVGPath).inserted {
                duplicatePaths.insert(normalizedSVGPath)
            }

            if let reference = entry.reference {
                let normalizedReference = normalizedRelativePath(reference)
                if !normalizedReference.isEmpty {
                    XCTAssertNotNil(
                        testBundleResourceURL(for: normalizedReference),
                        "\(suite.rawValue) reference 파일이 테스트 번들에 없습니다. (id: \(entry.id), reference: \(normalizedReference))"
                    )
                }
            }

            _ = suite
            _ = entry.suite
            _ = entry.category
            _ = entry.source
        }

        XCTAssertTrue(
            duplicateIDs.isEmpty,
            "\(suite.rawValue) manifest id 중복: \(duplicateIDs.sorted().joined(separator: ", "))"
        )
        XCTAssertTrue(
            duplicatePaths.isEmpty,
            "\(suite.rawValue) manifest svg 경로 중복: \(duplicatePaths.sorted().joined(separator: ", "))"
        )
    }

    private func assertTestBundleFixtureExistence(
        for suite: ConformanceSuite,
        relativePaths: Set<String>
    ) {
        var missing: [String] = []

        for relativePath in relativePaths {
            if testBundleResourceURL(for: relativePath) == nil {
                missing.append(relativePath)
            }
        }

        XCTAssertTrue(
            missing.isEmpty,
            "\(suite.rawValue) manifest의 fixture svg가 테스트 번들에서 누락되었습니다: \(missing.joined(separator: ", "))"
        )
    }

    private func assertDemoBundleAlignment(
        for suite: ConformanceSuite,
        relativePaths: Set<String>
    ) {
        let demoRoot = demoResourceRoot()
        let demoManifestPath = demoRoot.appendingPathComponent(suite.demoManifestRelativePath)
        let demoFixtureRoot = demoRoot.appendingPathComponent(suite.demoFixtureDirectoryName)

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: demoManifestPath.path),
            "Demo manifest 파일이 없습니다: \(demoManifestPath.path)"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: demoFixtureRoot.path),
            "\(suite.rawValue) Demo fixture 디렉터리가 없습니다: \(demoFixtureRoot.path)"
        )

        let enumerator = FileManager.default.enumerator(
            at: demoFixtureRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        XCTAssertNotNil(
            enumerator,
            "Demo fixture 탐색 실패: \(demoFixtureRoot.path)"
        )
        guard let fixtureEnumerator = enumerator else {
            return
        }

        var discoveredSet = Set<String>()
        let basePath = demoFixtureRoot.path.hasSuffix("/")
            ? demoFixtureRoot.path
            : demoFixtureRoot.path + "/"

        for case let fileURL as URL in fixtureEnumerator where fileURL.pathExtension == "svg" {
            let path = fileURL.path
            guard path.hasPrefix(basePath) else {
                continue
            }
            let relativePath = String(path.dropFirst(basePath.count))
            discoveredSet.insert(makeRelativeFixturePath(relativePath))
        }

        let missingInDemo = relativePaths.filter { path in
            !discoveredSet.contains(path)
        }

        let extraInDemo = discoveredSet.filter { path in
            !relativePaths.contains(path)
        }

        XCTAssertTrue(
            missingInDemo.isEmpty,
            "\(suite.rawValue) manifest에 등록된 Demo fixture 파일이 실제 Demo 폴더에서 빠졌습니다: \(missingInDemo.sorted().joined(separator: ", "))"
        )

        XCTAssertTrue(
            extraInDemo.isEmpty,
            "\(suite.rawValue) Demo 폴더에만 있고 conformance manifest에 없는 파일이 있습니다: \(extraInDemo.sorted().joined(separator: ", "))"
        )
    }

    private func loadManifest(from resourcePath: String) throws -> FixtureManifest {
        guard let url = testBundleResourceURL(for: resourcePath) else {
            throw NSError(
                domain: "ConformanceManifestAlignmentTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Manifest resource not found: \(resourcePath)"]
            )
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(FixtureManifest.self, from: data)
    }

    private func testBundleResourceURL(for resourcePath: String) -> URL? {
        let normalizedPath = normalizedRelativePath(resourcePath)
        guard !normalizedPath.isEmpty else {
            return nil
        }

        let components = normalizedPath.split(separator: "/").map(String.init)
        guard let resourceName = components.last else {
            return nil
        }

        let url = URL(fileURLWithPath: resourceName)
        let fileExtension = url.pathExtension
        let fileNameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let subdirectory = components.dropLast().joined(separator: "/")

        if let nestedURL = Bundle.module.url(
            forResource: fileNameWithoutExtension,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) {
            return nestedURL
        }

        if let flatURL = Bundle.module.url(forResource: resourceName, withExtension: nil) {
            return flatURL
        }

        if let fallbackURL = Bundle.module.url(forResource: fileNameWithoutExtension, withExtension: fileExtension) {
            return fallbackURL
        }

        return nil
    }

    private func normalizedRelativePath(_ path: String) -> String {
        let normalizedSeparators = path.replacingOccurrences(of: "\\", with: "/")
        return normalizedSeparators
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func makeRelativeFixturePath(_ rawPath: String) -> String {
        let normalized = normalizedRelativePath(rawPath)
        if normalized.hasPrefix("fixtures/") {
            return normalized
        }

        return "fixtures/\(normalized)"
    }

    private func demoResourceRoot() -> URL {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let testsDirectory = testFileURL.deletingLastPathComponent() // Tests/SVGSwiftUITests
        let repositoryRoot = testsDirectory.deletingLastPathComponent() // Tests

        return repositoryRoot
            .deletingLastPathComponent() // SVGSwiftUI
            .appendingPathComponent("Examples/SVGSwiftUIDemo/Resources")
    }
}
