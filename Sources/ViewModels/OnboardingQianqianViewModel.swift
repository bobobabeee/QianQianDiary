import SwiftUI

@MainActor
final class OnboardingQianqianViewModel: ObservableObject {
    @Published private(set) var steps: [DialogStepData] = []
    @Published var currentIndex: Int = 0

    private let service: OnboardingService

    init(service: OnboardingService = OnboardingService.shared) {
        self.service = service
        load()
    }

    var currentStep: DialogStepData {
        if currentIndex >= 0, currentIndex < steps.count {
            return steps[currentIndex]
        }
        return steps.first ?? service.getStep(id: 1)
    }

    var canGoNext: Bool {
        currentIndex < max(0, steps.count - 1)
    }

    var shouldShowDonutSection: Bool {
        guard !steps.isEmpty else { return false }
        return currentIndex == steps.count - 1
    }

    func goNext() {
        guard canGoNext else { return }
        currentIndex += 1
    }

    private func load() {
        let loaded = service.getOnboardingSteps()
        steps = loaded
        currentIndex = 0
    }
}