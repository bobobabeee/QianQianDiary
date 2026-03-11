import SwiftUI

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
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: swiftUIContentMode)
            default:
                placeholder
            }
        }
        .frame(width: width, height: height)
        .background(placeholder)
        .cornerRadius(cornerRadius)
        .clipped()
    }

    private var aspectRatioImage: some View {
        let rawRatio = aspectRatio ?? 1.0
        let safeRatio = rawRatio > 0 ? rawRatio : 1.0

        return GeometryReader { geometry in
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: swiftUIContentMode)
                default:
                    placeholder
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.width * safeRatio
            )
            .background(placeholder)
            .clipped()
        }
        .aspectRatio(1.0 / safeRatio, contentMode: .fit)
        .cornerRadius(cornerRadius)
    }

    private var backgroundImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: swiftUIContentMode)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                default:
                    placeholder
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
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

