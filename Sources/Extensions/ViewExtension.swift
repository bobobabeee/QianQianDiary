import SwiftUI

// MARK: - View Extension for Chain Methods

extension View {
    func configure(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
