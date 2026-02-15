import Foundation

enum SVGStyleSelector: Sendable, Equatable {
    case element(String)
    case id(String)
    case `class`(String)
    case any
}

struct SVGStyleRule: Sendable, Equatable {
    var selector: SVGStyleSelector
    var declarations: [String: String]

    init(selector: SVGStyleSelector, declarations: [String: String] = [:]) {
        self.selector = selector
        self.declarations = declarations
    }
}

