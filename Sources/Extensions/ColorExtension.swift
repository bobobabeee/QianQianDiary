import SwiftUI

extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    init(hex: UInt64) {
        self.init(hex: Int(hex & 0xFFFFFF))
    }

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(hex: value)
    }

    init(hsl h: Double, _ s: Double, _ l: Double) {
        let normalizedH = h.truncatingRemainder(dividingBy: 360)
        let hue = normalizedH < 0 ? normalizedH + 360 : normalizedH

        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2

        var r: Double = 0
        var g: Double = 0
        var b: Double = 0

        switch hue {
        case 0 ..< 60:
            r = c; g = x; b = 0
        case 60 ..< 120:
            r = x; g = c; b = 0
        case 120 ..< 180:
            r = 0; g = c; b = x
        case 180 ..< 240:
            r = 0; g = x; b = c
        case 240 ..< 300:
            r = x; g = 0; b = c
        default:
            r = c; g = 0; b = x
        }

        self.init(.sRGB, red: r + m, green: g + m, blue: b + m, opacity: 1.0)
    }

    init(oklch l: Double, _ c: Double, _ h: Double) {
        let hRad = h * .pi / 180
        let aAxis = c * cos(hRad)
        let bAxis = c * sin(hRad)

        let (r, g, b) = Self.oklabToSRGB(l: l, a: aAxis, b: bAxis)

        self.init(
            .sRGB,
            red: max(0, min(1, r)),
            green: max(0, min(1, g)),
            blue: max(0, min(1, b)),
            opacity: 1.0
        )
    }

    private static func oklabToSRGB(l: Double, a: Double, b: Double) -> (Double, Double, Double) {
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let lCubed = l_ * l_ * l_
        let mCubed = m_ * m_ * m_
        let sCubed = s_ * s_ * s_

        let rLinear = +4.0767416621 * lCubed - 3.3077115913 * mCubed + 0.2309699292 * sCubed
        let gLinear = -1.2684380046 * lCubed + 2.6097574011 * mCubed - 0.3413193965 * sCubed
        let bLinear = -0.0041960863 * lCubed - 0.7034186147 * mCubed + 1.7076147010 * sCubed

        return (
            linearToSRGB(rLinear),
            linearToSRGB(gLinear),
            linearToSRGB(bLinear)
        )
    }

    private static func linearToSRGB(_ x: Double) -> Double {
        if x <= 0.0031308 {
            12.92 * x
        } else {
            1.055 * pow(x, 1 / 2.4) - 0.055
        }
    }

}
