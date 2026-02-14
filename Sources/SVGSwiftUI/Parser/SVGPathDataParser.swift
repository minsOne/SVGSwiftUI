import Foundation

struct SVGPathCommand: Sendable, Equatable {
    var symbol: Character
    var values: [Double]

    init(symbol: Character, values: [Double]) {
        self.symbol = symbol
        self.values = values
    }
}

enum SVGPathDataParserError: Error, Sendable, Equatable {
    case missingCommand
    case unsupportedCommand(Character)
    case invalidParameterCount(command: Character, count: Int)
}

struct SVGPathDataParser: Sendable {
    init() {}

    func parse(_ pathData: String) throws -> [SVGPathCommand] {
        var commands: [SVGPathCommand] = []
        var currentSymbol: Character?
        var buffer = ""

        for char in pathData {
            if isSupportedCommand(char) {
                try flushCommand(symbol: currentSymbol, buffer: buffer, into: &commands)
                currentSymbol = char
                buffer.removeAll(keepingCapacity: true)
                continue
            }

            if char.isLetter {
                if char == "e" || char == "E" {
                    buffer.append(char)
                    continue
                }
                throw SVGPathDataParserError.unsupportedCommand(char)
            }

            if currentSymbol == nil && !char.isWhitespace && char != "," {
                throw SVGPathDataParserError.missingCommand
            }
            buffer.append(char)
        }

        try flushCommand(symbol: currentSymbol, buffer: buffer, into: &commands)
        return commands
    }

    private func flushCommand(symbol: Character?, buffer: String, into commands: inout [SVGPathCommand]) throws {
        let trimmedBuffer = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let symbol else {
            if trimmedBuffer.isEmpty {
                return
            }
            throw SVGPathDataParserError.missingCommand
        }

        let values = parseNumbers(trimmedBuffer)
        try validateArity(for: symbol, count: values.count)
        commands.append(SVGPathCommand(symbol: symbol, values: values))
    }

    private func parseNumbers(_ source: String) -> [Double] {
        guard !source.isEmpty else {
            return []
        }
        let pattern = #"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let nsRange = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, range: nsRange)
        return matches.compactMap { match -> Double? in
            guard let range = Range(match.range, in: source) else {
                return nil
            }
            return Double(source[range])
        }
    }

    private func validateArity(for symbol: Character, count: Int) throws {
        switch symbol {
        case "Z", "z":
            if count != 0 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        case "H", "h", "V", "v":
            if count < 1 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        case "M", "m", "L", "l", "T", "t":
            if count < 2 || count % 2 != 0 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        case "S", "s", "Q", "q":
            if count < 4 || count % 4 != 0 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        case "C", "c":
            if count < 6 || count % 6 != 0 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        case "A", "a":
            if count < 7 || count % 7 != 0 {
                throw SVGPathDataParserError.invalidParameterCount(command: symbol, count: count)
            }
        default:
            throw SVGPathDataParserError.unsupportedCommand(symbol)
        }
    }

    private func isSupportedCommand(_ char: Character) -> Bool {
        switch char {
        case "M", "m", "L", "l", "H", "h", "V", "v", "C", "c", "S", "s", "Q", "q", "T", "t", "A", "a", "Z", "z":
            return true
        default:
            return false
        }
    }
}
