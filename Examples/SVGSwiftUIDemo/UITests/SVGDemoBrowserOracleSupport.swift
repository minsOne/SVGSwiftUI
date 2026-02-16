import Foundation
import CoreGraphics

struct DemoBrowserBaselineCase {
    let sampleID: String
    let baselineName: String
    let sourceSVGPath: String
    let expectedSize: CGSize?

    init(sampleID: String, baselineName: String, sourceSVGPath: String) {
        self.sampleID = sampleID
        self.baselineName = baselineName
        self.sourceSVGPath = sourceSVGPath
        self.expectedSize = nil
    }

    init(
        sampleID: String,
        baselineName: String,
        sourceSVGPath: String,
        expectedSize: CGSize?
    ) {
        self.sampleID = sampleID
        self.baselineName = baselineName
        self.sourceSVGPath = sourceSVGPath
        self.expectedSize = expectedSize
    }
}

struct BrowserOracleManifest: Decodable {
    let cases: [BrowserOracleManifestEntry]
}

struct BrowserOracleManifestEntry: Decodable {
    let name: String
    let svg: String
    let sampleID: String?
    let size: BrowserOracleManifestSize?
}

struct BrowserOracleManifestSize: Decodable {
    let width: Int?
    let height: Int?
}

extension SVGSwiftUIDemoUITests {
    func loadBrowserBaselineCases() throws -> [DemoBrowserBaselineCase] {
        guard let manifestURL = findBrowserOracleManifestURL() else {
            throw NSError(
                domain: "BrowserOracleManifest",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "브라우저 오라클 매니페스트를 찾을 수 없습니다. " +
                        "예상 파일: Scripts/browser-oracle/browser-oracle-manifest.json"
                ]
            )
        }

        let rawData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(BrowserOracleManifest.self, from: rawData)
        let manifestDirectory = manifestURL.deletingLastPathComponent().path

        return manifest.cases.map { entry in
            let svgPath = (manifestDirectory as NSString).appendingPathComponent(entry.svg)
            let svgURL = URL(fileURLWithPath: svgPath).standardized
            let sampleID = entry.sampleID ?? svgURL.deletingPathExtension().lastPathComponent
            let expectedSize = makeExpectedSize(from: entry.size)
            return DemoBrowserBaselineCase(
                sampleID: sampleID,
                baselineName: entry.name,
                sourceSVGPath: svgURL.path,
                expectedSize: expectedSize
            )
        }
    }

    func makeExpectedSize(from size: BrowserOracleManifestSize?) -> CGSize? {
        guard let size else {
            return nil
        }
        guard let widthValue = size.width, let heightValue = size.height else {
            return nil
        }
        if widthValue <= 0 || heightValue <= 0 {
            return nil
        }
        return CGSize(width: widthValue, height: heightValue)
    }
}

private func findBrowserOracleManifestURL() -> URL? {
    let manifestFileName = "browser-oracle-manifest.json"
    let fileManager = FileManager.default
    let processInfo = ProcessInfo.processInfo

    var candidateRoots = [URL]()
    let sourceFileURL = URL(fileURLWithPath: String(describing: #filePath))
    var scanningRoot = sourceFileURL.deletingLastPathComponent()
    for _ in 0..<12 {
        candidateRoots.append(scanningRoot)
        scanningRoot = scanningRoot.deletingLastPathComponent()
    }

    if let projectDir = processInfo.environment["PROJECT_DIR"] {
        candidateRoots.append(URL(fileURLWithPath: projectDir))
    }
    if let sourceRoot = processInfo.environment["SRCROOT"] {
        candidateRoots.append(URL(fileURLWithPath: sourceRoot))
    }
    if let currentWorkingDirectory = processInfo.environment["PWD"] {
        candidateRoots.append(URL(fileURLWithPath: currentWorkingDirectory))
    }
    candidateRoots.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))

    var seenRoots = Set<String>()
    for root in candidateRoots {
        let rootPath = root.standardized.path
        if seenRoots.contains(rootPath) {
            continue
        }
        seenRoots.insert(rootPath)

        var currentRoot = root
        for _ in 0..<12 {
            let manifestURL = currentRoot
                .appendingPathComponent("Scripts", isDirectory: true)
                .appendingPathComponent("browser-oracle", isDirectory: true)
                .appendingPathComponent(manifestFileName)
            if fileManager.fileExists(atPath: manifestURL.path) {
                return manifestURL.standardized
            }

            let parent = currentRoot.deletingLastPathComponent()
            if parent == currentRoot {
                break
            }
            currentRoot = parent
        }
    }

    return nil
}
