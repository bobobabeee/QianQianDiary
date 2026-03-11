import SwiftUI

// MARK: - ChaTin 风格：奶白底 + 亮黄主色 + 淡粉/淡绿点缀，圆角药丸形，简洁活泼

struct AppColors {
    // 奶白/米白背景
    let background = Color(hsl: 48, 0.18, 0.98)
    let onBackground = Color(hsl: 0, 0, 0.12)

    let surface = Color(hsl: 0, 0, 1.0)
    let onSurface = Color(hsl: 0, 0, 0.12)

    // 主色：亮黄，主按钮/CTA
    let primary = Color(hsl: 48, 0.95, 0.55)
    let onPrimary = Color(hsl: 0, 0, 0.10)

    // 次要：柔和暖色
    let secondary = Color(hsl: 48, 0.45, 0.92)
    let onSecondary = Color(hsl: 0, 0, 0.25)

    let muted = Color(hsl: 48, 0.10, 0.94)
    let onMuted = Color(hsl: 0, 0, 0.45)

    // 点缀：淡粉、淡绿（ChaTin 卡片色）
    let accent = Color(hsl: 350, 0.55, 0.85)
    let onAccent = Color(hsl: 0, 0, 0.25)
    let accentGreen = Color(hsl: 145, 0.40, 0.88)

    let error = Color(hsl: 0, 0.60, 0.55)
    let onError = Color(hsl: 0, 0, 1.0)

    let border = Color(hsl: 48, 0.12, 0.92)

    let chart1 = Color(hsl: 48, 0.95, 0.55)
    let chart2 = Color(hsl: 350, 0.55, 0.80)
    let chart3 = Color(hsl: 145, 0.45, 0.65)
    let chart4 = Color(hsl: 48, 0.6, 0.70)
    let chart5 = Color(hsl: 260, 0.35, 0.68)
}

struct AppColorsDark {
    let background = Color(hsl: 0, 0, 0.08)
    let onBackground = Color(hsl: 48, 0.1, 0.96)

    let surface = Color(hsl: 0, 0, 0.12)
    let onSurface = Color(hsl: 48, 0.1, 0.96)

    let primary = Color(hsl: 48, 0.9, 0.52)
    let onPrimary = Color(hsl: 0, 0, 0.06)

    let secondary = Color(hsl: 48, 0.3, 0.35)
    let onSecondary = Color(hsl: 0, 0, 0.98)

    let muted = Color(hsl: 0, 0, 0.20)
    let onMuted = Color(hsl: 48, 0.1, 0.75)

    let accent = Color(hsl: 350, 0.4, 0.55)
    let onAccent = Color(hsl: 0, 0, 0.98)
    let accentGreen = Color(hsl: 145, 0.35, 0.45)

    let error = Color(hsl: 0, 0.6, 0.55)
    let onError = Color(hsl: 0, 0, 0.98)

    let border = Color(hsl: 0, 0, 0.22)

    let chart1 = Color(hsl: 48, 0.9, 0.55)
    let chart2 = Color(hsl: 350, 0.5, 0.65)
    let chart3 = Color(hsl: 145, 0.4, 0.6)
    let chart4 = Color(hsl: 48, 0.55, 0.62)
    let chart5 = Color(hsl: 260, 0.35, 0.68)
}

struct AppTypography {
    let body = Font.system(size: 16, weight: .regular, design: .default)
    let title = Font.system(size: 26, weight: .bold, design: .default)
    let heading = Font.system(size: 18, weight: .semibold, design: .default)
    let caption = Font.system(size: 14, weight: .regular, design: .default)
}

struct AppRadius {
    let standard: CGFloat = 16
    let small: CGFloat = 10
    let medium: CGFloat = 16
    let large: CGFloat = 24
    /// 药丸形按钮
    let pill: CGFloat = 999
}

struct AppShadow {
    let soft = (color: Color.black.opacity(0.03), radius: 4.0, x: 0.0, y: 1.0)
    let card = (color: Color.black.opacity(0.05), radius: 8.0, x: 0.0, y: 2.0)
    let softDark = (color: Color.black.opacity(0.2), radius: 4.0, x: 0.0, y: 1.0)
    let cardDark = (color: Color.black.opacity(0.3), radius: 8.0, x: 0.0, y: 2.0)
}

struct AppSpacing {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
    let xl: CGFloat = 32
    /// 页面左右边距
    let screenHorizontal: CGFloat = 20
    /// 区块间垂直间距
    let sectionVertical: CGFloat = 32
    /// 内容最大宽度
    let contentMaxWidth: CGFloat = 400
}

struct AppTheme {
    static let colors = AppColors()
    static let colorsDark = AppColorsDark()
    static let typography = AppTypography()
    static let radius = AppRadius()
    static let shadow = AppShadow()
    static let spacing = AppSpacing()
}