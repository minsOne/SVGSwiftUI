public struct SVGParserOptions: Sendable, Hashable {
    public var normalizeWhitespace: Bool
    public var parserSchemaVersion: Int
    public var enableStyleTag: Bool
    public var enableDataURI: Bool
    public var maxDataURIBytes: Int
    public var maxEmbeddedImageCount: Int

    public init(
        normalizeWhitespace: Bool = true,
        parserSchemaVersion: Int = 1,
        enableStyleTag: Bool = false,
        enableDataURI: Bool = false,
        maxDataURIBytes: Int = 10_000_000,
        maxEmbeddedImageCount: Int = 32
    ) {
        self.normalizeWhitespace = normalizeWhitespace
        self.parserSchemaVersion = parserSchemaVersion
        self.enableStyleTag = enableStyleTag
        self.enableDataURI = enableDataURI
        self.maxDataURIBytes = maxDataURIBytes
        self.maxEmbeddedImageCount = maxEmbeddedImageCount
    }
}
