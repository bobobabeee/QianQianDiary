import SwiftUI

struct StatsCard: View {
    enum Trend {
        case up
        case down
        case neutral
    }

    enum Variant {
        case `default`
        case large
    }

    let title: String
    let value: String
    var description: String? = nil
    var trend: Trend = Trend.neutral
    var trendValue: String? = nil
    var icon: String? = nil
    var variant: Variant = Variant.default

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                HeaderRow(title: title, icon: icon)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                ContentBlock(
                    value: value,
                    valueFont: valueFont,
                    description: description,
                    trend: trend,
                    trendValue: trendValue
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }

    private var valueFont: Font {
        switch variant {
        case Variant.large:
            return .system(size: 36, weight: .bold)
        case Variant.default:
            return .system(size: 24, weight: .bold)
        }
    }
}

private struct HeaderRow: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.colors.onMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
                .frame(minWidth: 0, alignment: .leading)

            Spacer(minLength: 8)

            if let icon {
                SafeIcon(icon, size: 18, color: AppTheme.colors.onMuted)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct ContentBlock: View {
    let value: String
    let valueFont: Font
    let description: String?
    let trend: StatsCard.Trend
    let trendValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(valueFont)
                .foregroundColor(AppTheme.colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if shouldShowFooter {
                HStack(spacing: 8) {
                    if let description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    if let trendValue, !trendValue.isEmpty {
                        TrendPill(trend: trend, trendValue: trendValue)
                    }
                }
            }
        }
    }

    private var shouldShowFooter: Bool {
        let hasDescription = (description?.isEmpty == false)
        let hasTrend = (trendValue?.isEmpty == false)
        return hasDescription || hasTrend
    }
}

private struct TrendPill: View {
    let trend: StatsCard.Trend
    let trendValue: String

    var body: some View {
        HStack(spacing: 4) {
            SafeIcon(iconName, size: 14, color: color)
            Text(trendValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var iconName: String {
        switch trend {
        case StatsCard.Trend.up: return "TrendingUp"
        case StatsCard.Trend.down: return "TrendingDown"
        case StatsCard.Trend.neutral: return "Minus"
        }
    }

    private var color: Color {
        switch trend {
        case StatsCard.Trend.up:
            return Color(red: 0.10, green: 0.65, blue: 0.30)
        case StatsCard.Trend.down:
            return AppTheme.colors.error
        case StatsCard.Trend.neutral:
            return AppTheme.colors.onMuted
        }
    }
}