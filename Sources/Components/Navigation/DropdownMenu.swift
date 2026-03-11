import Popovers
import SwiftUI

// MARK: - DropdownMenu

struct AppDropdownMenu<Trigger: View, Content: View>: View {
    @State private var isExpanded: Bool = false
    let trigger: Trigger
    let content: Content
    var minWidth: CGFloat = 192
    var maxHeight: CGFloat = 300

    init(@ViewBuilder trigger: () -> Trigger, @ViewBuilder content: () -> Content) {
        self.trigger = trigger()
        self.content = content()
    }

    var body: some View {
        trigger
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { isExpanded.toggle() })
            .appPopover(
                isPresented: $isExpanded,
                side: .auto,
                sideOffset: 4
            ) {
                AppMenuContent(minWidth: minWidth, maxHeight: maxHeight) {
                    content
                }
                .environment(\.menuDismiss) { isExpanded = false }
            }
    }

    func minWidth(_ value: CGFloat) -> Self { configure { $0.minWidth = value } }
    func maxHeight(_ value: CGFloat) -> Self { configure { $0.maxHeight = value } }
}

// MARK: - Type Aliases for DropdownMenu

typealias AppDropdownMenuItem = AppMenuItem
typealias AppDropdownMenuSubMenu = AppMenuSubMenu
typealias AppDropdownMenuCheckboxItem = AppMenuCheckboxItem
typealias AppDropdownMenuRadioGroup = AppMenuRadioGroup
typealias AppDropdownMenuRadioItem = AppMenuRadioItem
typealias AppDropdownMenuLabel = AppMenuLabel
typealias AppDropdownMenuSeparator = AppMenuSeparator
typealias AppDropdownMenuShortcut = AppMenuShortcut
