import SwiftUI
import UIKit

enum RemoteImageMode {
    case fixed
    case aspectRatio
    case background
}

enum RemoteImageContentMode {
    case fill
    case fit
}

struct RemoteImage: View {
    let url: String
    var mode: RemoteImageMode = .fixed
    var contentMode: RemoteImageContentMode = .fill
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var aspectRatio: CGFloat? = nil
    var placeholder: Color = AppTheme.colors.muted
    var cornerRadius: CGFloat = 0

    var body: some View {
        Group {
            switch mode {
            case .fixed:
                fixedSizeImage
            case .aspectRatio:
                aspectRatioImage
            case .background:
                backgroundImage
            }
        }
    }

    private var fixedSizeImage: some View {
        CachedRemoteImageView(
            url: url,
            contentMode: swiftUIContentMode,
            failureTint: placeholder
        )
        .frame(width: width, height: height)
        .background(Color.clear)
        .cornerRadius(cornerRadius)
        .clipped()
    }

    private var aspectRatioImage: some View {
        let rawRatio = aspectRatio ?? 1.0
        let safeRatio = rawRatio > 0 ? rawRatio : 1.0

        return GeometryReader { geometry in
            CachedRemoteImageView(
                url: url,
                contentMode: swiftUIContentMode,
                failureTint: placeholder
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.width * safeRatio
            )
            .background(Color.clear)
            .clipped()
        }
        .aspectRatio(1.0 / safeRatio, contentMode: .fit)
        .cornerRadius(cornerRadius)
    }

    private var backgroundImage: some View {
        GeometryReader { geometry in
            CachedRemoteImageView(
                url: url,
                contentMode: swiftUIContentMode,
                failureTint: placeholder
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .cornerRadius(cornerRadius)
    }

    private var swiftUIContentMode: ContentMode {
        switch contentMode {
        case .fill: .fill
        case .fit: .fit
        }
    }

    func mode(_ value: RemoteImageMode) -> Self { configure { $0.mode = value } }
    func contentMode(_ value: RemoteImageContentMode) -> Self { configure { $0.contentMode = value } }
    func width(_ value: CGFloat) -> Self { configure { $0.width = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func aspectRatio(_ value: CGFloat) -> Self { configure { $0.aspectRatio = value } }
    func placeholder(_ value: Color) -> Self { configure { $0.placeholder = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
}

extension RemoteImage {
    static func fixed(url: String, width: CGFloat, height: CGFloat) -> RemoteImage {
        RemoteImage(url: url, mode: .fixed, width: width, height: height)
    }

    static func avatar(url: String, size: CGFloat) -> RemoteImage {
        RemoteImage(url: url, mode: .fixed, width: size, height: size)
            .cornerRadius(size / 2)
    }

    static func card(url: String, aspectRatio ratio: CGFloat = 1.0) -> RemoteImage {
        RemoteImage(url: url, mode: .aspectRatio, aspectRatio: ratio)
    }

    static func banner(url: String) -> RemoteImage {
        RemoteImage(url: url, mode: .aspectRatio, aspectRatio: 9.0 / 16.0)
    }

    static func background(url: String) -> RemoteImage {
        RemoteImage(url: url, mode: .background)
    }
}

// MARK: - 本地缓存加载（内存 + 磁盘）

private struct CachedRemoteImageView: View {
    let url: String
    let contentMode: ContentMode
    let failureTint: Color

    @State private var uiImage: UIImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed {
                RemoteImageFailurePlaceholder(tint: failureTint)
            } else {
                RemoteImageLoadingPlaceholder()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url) {
            loadFailed = false
            // 先同步读内存/磁盘，避免每次进页都先闪「加载中」再等 async 调度
            if let cached = ImageURLCache.shared.synchronousCachedUIImage(for: url) {
                uiImage = cached
                return
            }
            // 无缓存时再显示加载态并走网络（不要先把 uiImage 置 nil，减少无意义闪屏）
            if let img = await ImageURLCache.shared.uiImage(for: url) {
                uiImage = img
                loadFailed = false
            } else {
                uiImage = nil
                loadFailed = true
            }
        }
    }
}

// MARK: - 加载 / 失败占位（避免纯灰块）

/// 网络图加载中：柔和渐变呼吸 + 转圈，与 ChaTin 主色协调
private struct RemoteImageLoadingPlaceholder: View {
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSince1970
            let wave = (sin(t * 2.2) + 1) * 0.5

            ZStack {
                AppTheme.colors.surface
                LinearGradient(
                    colors: [
                        AppTheme.colors.secondary.opacity(0.12 + wave * 0.14),
                        AppTheme.colors.primary.opacity(0.05 + wave * 0.10),
                        AppTheme.colors.secondary.opacity(0.12 + wave * 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                ProgressView()
                    .controlSize(.regular)
                    .tint(AppTheme.colors.primary.opacity(0.72))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(Text("图片加载中"))
    }
}

private struct RemoteImageFailurePlaceholder: View {
    var tint: Color

    var body: some View {
        ZStack {
            AppTheme.colors.secondary.opacity(0.22)
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(tint.opacity(0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(Text("图片加载失败"))
    }
}

