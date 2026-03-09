import SwiftUI

struct SafeIcon: View {
    let name: String
    var size: CGFloat = 24
    var color: Color = .primary

    var body: some View {
        Group {
            if Self.isSystemIcon(name) {
                Image(systemName: name)
                    .font(.system(size: size))
                    .imageScale(.medium)
            } else {
                Image(Self.resolveName(name))
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: size, height: size)
            }
        }
        .foregroundColor(color)
    }

    private static func isSystemIcon(_ name: String) -> Bool {
        name.contains(".")
    }

    private static func resolveName(_ name: String) -> String {
        var result = name

        if result.hasPrefix("Lucide") && result.count > 6 {
            let afterPrefix = result.dropFirst(6)
            if let first = afterPrefix.first, first.isUppercase {
                result = String(afterPrefix)
            }
        }

        if result.hasSuffix("Icon") && result.count > 4 {
            result = String(result.dropLast(4))
        }

        if result.contains("_") {
            return result.lowercased()
        }

        if result.contains("-") {
            result = result.replacingOccurrences(of: "-", with: "_")
        }

        var snake = ""
        var prev: Character? = nil
        for char in result {
            if let p = prev {
                if p.isLetter && char.isNumber {
                    snake += "_"
                } else if p.isNumber && char.isLetter {
                    snake += "_"
                } else if p.isLowercase && char.isUppercase {
                    snake += "_"
                }
            }
            snake += char.lowercased()
            prev = char
        }

        return snake
    }
}

extension SafeIcon {
    init(_ name: String) {
        self.name = name
    }

    init(_ name: String, size: CGFloat) {
        self.name = name
        self.size = size
    }

    init(_ name: String, size: CGFloat, color: Color) {
        self.name = name
        self.size = size
        self.color = color
    }
}
