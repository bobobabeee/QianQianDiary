import SwiftUI

struct MobileBottomNav: View {
    struct NavItem {
        let id: String
        let label: String
        let icon: String
        let destination: AppRouter.Destination
    }

    @EnvironmentObject private var router: AppRouter

    var activeDestination: AppRouter.Destination? = nil

    private let navItems: [NavItem] = [
        NavItem(id: "home", label: "首页", icon: "Home", destination: AppRouter.Destination.home),
        NavItem(id: "diary", label: "日记", icon: "BookOpen", destination: AppRouter.Destination.diaryCalendarView(date: nil)),
        NavItem(id: "virtue", label: "美德", icon: "Heart", destination: AppRouter.Destination.virtueGrowthStats),
        NavItem(id: "vision", label: "愿景", icon: "Sparkles", destination: AppRouter.Destination.visionBoardMain),
        NavItem(id: "stats", label: "统计", icon: "BarChart3", destination: AppRouter.Destination.successDiaryStats),
        NavItem(id: "profile", label: "我的", icon: "person.fill", destination: AppRouter.Destination.profile)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(AppTheme.colors.border)

            HStack(spacing: 0) {
                ForEach(navItems, id: \.id) { item in
                    NavItemButton(
                        item: item,
                        isActive: isActive(item.destination),
                        onTap: { router.navigate(to: item.destination, style: AppRouter.NavigationStyle.root) }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 64)
        }
        .background(AppTheme.colors.surface, ignoresSafeAreaEdges: .bottom)
    }

    private func isActive(_ destination: AppRouter.Destination) -> Bool {
        let current = activeDestination ?? router.root
        return destination == current
    }
}

private struct NavItemButton: View {
    let item: MobileBottomNav.NavItem
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                SafeIcon(item.icon, size: 20, color: iconColor)
                Text(item.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 60)
            .background(isActive ? AppTheme.colors.primary.opacity(0.10) : Color.clear)
            .cornerRadius(AppTheme.radius.standard)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.label))
    }

    private var iconColor: Color {
        isActive ? AppTheme.colors.primary : AppTheme.colors.onMuted
    }

    private var textColor: Color {
        isActive ? AppTheme.colors.primary : AppTheme.colors.onMuted
    }
}