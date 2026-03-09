import SwiftUI

// MARK: - Avatar

struct AppAvatar<Content: View>: View {
    let content: Content
    var size: CGFloat = 40

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
}

// MARK: - Avatar Image (URL)

struct AppAvatarImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    init(url: URL?) {
        self.url = url
    }

    init(urlString: String?) {
        url = urlString.flatMap { URL(string: $0) }
    }

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure, .empty:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
        }
    }

    func contentMode(_ value: ContentMode) -> Self { configure { $0.contentMode = value } }
}

// MARK: - Avatar Local Image

struct AppAvatarLocalImage: View {
    let imageName: String
    var contentMode: ContentMode = .fill

    init(_ imageName: String) {
        self.imageName = imageName
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }

    func contentMode(_ value: ContentMode) -> Self { configure { $0.contentMode = value } }
}

// MARK: - Avatar System Image

struct AppAvatarSystemImage: View {
    let systemName: String
    var iconColor: Color = .white
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.secondarySystemBackground))

    init(_ systemName: String) {
        self.systemName = systemName
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(background)
                SafeIcon(systemName, size: geo.size.width * 0.5, color: iconColor)
            }
        }
    }

    func iconColor(_ value: Color) -> Self { configure { $0.iconColor = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
}

// MARK: - Avatar Fallback

struct AppAvatarFallback: View {
    let text: String
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.secondarySystemBackground))
    var textColor: Color = .primary
    var fontWeight: Font.Weight = .medium

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(background)
                Text(text.prefix(2).uppercased())
                    .font(.system(size: geo.size.width * 0.4, weight: fontWeight))
                    .foregroundColor(textColor)
            }
        }
    }

    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func fontWeight(_ value: Font.Weight) -> Self { configure { $0.fontWeight = value } }
}

// MARK: - Avatar With Fallback

struct AppAvatarWithFallback: View {
    let imageURL: String?
    let fallback: String
    var size: CGFloat = 40
    var fallbackBackgroundColor: Color = .init(UIColor.secondarySystemBackground)
    var fallbackTextColor: Color = .primary

    @State private var imageLoadFailed = false

    init(imageURL: String?, fallback: String) {
        self.imageURL = imageURL
        self.fallback = fallback
    }

    var body: some View {
        AppAvatar { fallbackContent }
            .size(size)
    }

    @ViewBuilder
    private var fallbackContent: some View {
        if let urlString = imageURL,
           let url = URL(string: urlString),
           !imageLoadFailed
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    AppAvatarFallback(fallback)
                        .background(fallbackBackgroundColor)
                        .textColor(fallbackTextColor)
                        .onAppear { imageLoadFailed = true }
                case .empty:
                    loadingView
                @unknown default:
                    AppAvatarFallback(fallback)
                        .background(fallbackBackgroundColor)
                        .textColor(fallbackTextColor)
                }
            }
        } else {
            AppAvatarFallback(fallback)
                .background(fallbackBackgroundColor)
                .textColor(fallbackTextColor)
        }
    }

    private var loadingView: some View {
        Circle().fill(Color.primary.opacity(0.1))
    }

    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func fallbackBackgroundColor(_ value: Color) -> Self { configure { $0.fallbackBackgroundColor = value } }
    func fallbackTextColor(_ value: Color) -> Self { configure { $0.fallbackTextColor = value } }
}

// MARK: - Avatar Group

struct AppAvatarGroup: View {
    let avatars: [AvatarData]
    var size: CGFloat = 40
    var overlap: CGFloat = 12
    var maxVisible: Int = 4
    var borderColor: Color = .init(UIColor.systemBackground)
    var borderWidth: CGFloat = 2

    struct AvatarData: Identifiable {
        let id = UUID()
        let imageURL: String?
        let fallback: String
    }

    init(avatars: [AvatarData]) {
        self.avatars = avatars
    }

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(avatars.prefix(maxVisible).enumerated()), id: \.element.id) { index, avatar in
                AppAvatarWithFallback(imageURL: avatar.imageURL, fallback: avatar.fallback)
                    .size(size)
                    .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
                    .zIndex(Double(avatars.count - index))
            }

            if avatars.count > maxVisible {
                AppAvatar {
                    AppAvatarFallback("+\(avatars.count - maxVisible)")
                        .background(Color.init(UIColor.tertiarySystemBackground))
                        .textColor(.secondary)
                }
                .size(size)
                .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
            }
        }
    }

    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func overlap(_ value: CGFloat) -> Self { configure { $0.overlap = value } }
    func maxVisible(_ value: Int) -> Self { configure { $0.maxVisible = value } }

    func border(color: Color, width: CGFloat = 2) -> Self {
        configure { $0.borderColor = color; $0.borderWidth = width }
    }
}
