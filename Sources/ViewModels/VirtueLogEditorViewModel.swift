import SwiftUI
import Foundation

@MainActor
final class VirtueLogEditorViewModel: ObservableObject {
    @Published var isCompleted: Bool = false
    @Published var reflection: String = ""
    @Published var selectedVirtueType: VirtueTypeData = VirtueTypeData.friendly
    @Published private(set) var dateString: String = ""

    private let virtueService: VirtueService
    private let calendar: Calendar

    init(
        virtueService: VirtueService = VirtueService.shared,
        calendar: Calendar = Calendar.current
    ) {
        self.virtueService = virtueService
        self.calendar = calendar
        initializeForToday()
    }

    var currentDefinition: VirtueDefinitionData {
        virtueService.getVirtueDefinition(type: selectedVirtueType)
    }

    var virtueCardVirtue: VirtueCard.Virtue {
        VirtueCard.Virtue(
            name: currentDefinition.name,
            subtitle: currentDefinition.quote,
            principles: currentDefinition.guidelines,
            color: virtueColorHslString(for: selectedVirtueType)
        )
    }

    var reflectionCountText: String {
        "\(min(reflection.count, reflectionLimit))/\(reflectionLimit) 字"
    }

    var statusHintText: String {
        isCompleted ? "太棒了!继续保持这份美德!" : "标记后可以记录你的践行心得"
    }

    var statusHintIconName: String {
        isCompleted ? "CheckCircle2" : "AlertCircle"
    }

    var statusHintBackground: Color {
        isCompleted ? Color(red: 0.94, green: 0.98, blue: 0.95) : Color(red: 1.00, green: 0.98, blue: 0.92)
    }

    var statusHintForeground: Color {
        isCompleted ? Color(red: 0.12, green: 0.46, blue: 0.26) : Color(red: 0.69, green: 0.35, blue: 0.05)
    }

    var reflectionLimit: Int { 500 }

    func initializeForToday(date: Date = Date()) {
        dateString = makeDateString(from: date)
        let todayDefinition = virtueService.getTodayVirtueDefinition(date: date, calendar: calendar)
        selectedVirtueType = todayDefinition.type
        isCompleted = false
        reflection = ""
    }

    func setCompleted(_ value: Bool) {
        isCompleted = value
    }

    func toggleCompleted() {
        isCompleted.toggle()
    }

    func enforceReflectionLimit() {
        guard reflection.count > reflectionLimit else { return }
        reflection = String(reflection.prefix(reflectionLimit))
    }

    func save() {
        let updated = virtueService.setVirtueCompleted(
            date: dateString,
            virtueType: selectedVirtueType,
            isCompleted: isCompleted,
            reflection: reflection
        )
        isCompleted = updated.isCompleted
        reflection = updated.reflection
    }

    private func makeDateString(from date: Date) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func virtueColorHslString(for type: VirtueTypeData) -> String {
        switch type {
        case VirtueTypeData.friendly:
            return "15 85% 75%"
        case VirtueTypeData.responsible:
            return "35 100% 65%"
        case VirtueTypeData.kind:
            return "195 75% 70%"
        case VirtueTypeData.helpful:
            return "120 45% 65%"
        case VirtueTypeData.grateful:
            return "270 60% 70%"
        case VirtueTypeData.learning:
            return "35 100% 65%"
        case VirtueTypeData.reliable:
            return "15 85% 75%"
        }
    }
}