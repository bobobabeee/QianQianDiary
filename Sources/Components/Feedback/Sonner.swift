import SwiftUI

// MARK: - Toast Type

enum ToastType: Equatable {
    case `default`
    case success
    case error
    case warning
    case info
}

// MARK: - Toast

struct AppToast: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let description: String?
    let duration: TimeInterval

    init(type: ToastType = .default, title: String, description: String? = nil, duration: TimeInterval = 3.0) {
        self.type = type
        self.title = title
        self.description = description
        self.duration = duration
    }

    static func == (lhs: AppToast, rhs: AppToast) -> Bool {
        lhs.id == rhs.id
    }

    static func success(_ title: String, description: String? = nil, duration: TimeInterval = 3.0) -> AppToast {
        AppToast(type: .success, title: title, description: description, duration: duration)
    }

    static func error(_ title: String, description: String? = nil, duration: TimeInterval = 3.0) -> AppToast {
        AppToast(type: .error, title: title, description: description, duration: duration)
    }

    static func warning(_ title: String, description: String? = nil, duration: TimeInterval = 3.0) -> AppToast {
        AppToast(type: .warning, title: title, description: description, duration: duration)
    }

    static func info(_ title: String, description: String? = nil, duration: TimeInterval = 3.0) -> AppToast {
        AppToast(type: .info, title: title, description: description, duration: duration)
    }
}

// MARK: - Toast Manager

class ToastManager: ObservableObject {
    @Published var toasts: [AppToast] = []

    func show(_ toast: AppToast) {
        toasts.append(toast)
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.toasts.removeAll { $0.id == toast.id }
        }
    }

    func dismiss(_ toast: AppToast) {
        toasts.removeAll { $0.id == toast.id }
    }
}

// MARK: - Toast View

struct AppToastView: View {
    let toast: AppToast
    let onDismiss: () -> Void
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 8
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .gray.opacity(0.2)
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 10
    var iconSize: CGFloat = 16
    var titleFontSize: CGFloat = 14
    var descriptionFontSize: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconForType
                .font(.system(size: iconSize))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.system(size: titleFontSize, weight: .semibold))
                    .foregroundColor(.primary)

                if let description = toast.description {
                    Text(description)
                        .font(.system(size: descriptionFontSize))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDismiss) {
                SafeIcon("X", size: 12, color: .secondary)
            }
        }
        .padding(padding)
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var iconForType: some View {
        switch toast.type {
        case .default, .info:
            SafeIcon("Info", size: iconSize, color: iconColor)
        case .success:
            SafeIcon("CheckCircle", size: iconSize, color: iconColor)
        case .error:
            SafeIcon("XCircle", size: iconSize, color: iconColor)
        case .warning:
            SafeIcon("AlertTriangle", size: iconSize, color: iconColor)
        }
    }

    private var iconColor: Color {
        switch toast.type {
        case .default, .info: .blue
        case .success: .green
        case .error: .red
        case .warning: .orange
        }
    }

    // MARK: - Chain Methods

    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }

    func shadow(color: Color = .black.opacity(0.1), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}

// MARK: - Toaster View

struct AppToasterView: View {
    @ObservedObject var manager: ToastManager

    var body: some View {
        VStack(spacing: 8) {
            ForEach(manager.toasts) { toast in
                AppToastView(toast: toast) {
                    withAnimation {
                        manager.dismiss(toast)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(), value: manager.toasts)
    }
}
