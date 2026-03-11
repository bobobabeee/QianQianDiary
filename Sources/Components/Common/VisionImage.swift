import SwiftUI

/// 愿景图片：支持本地资源（asset:xxx）或网络 URL，与 RemoteImage 用法一致。
struct VisionImage: View {
    enum Mode {
        case fixed(width: CGFloat, height: CGFloat)
        case card(aspectRatio: CGFloat)
        case background
    }

    let urlOrAsset: String
    let mode: Mode
    var contentMode: RemoteImageContentMode = .fill
    var placeholder: Color = AppTheme.colors.muted
    var cornerRadius: CGFloat = 0

    private var isAsset: Bool { urlOrAsset.hasPrefix("asset:") }
    private var assetName: String {
        guard isAsset else { return "" }
        return String(urlOrAsset.dropFirst(6))
    }

    var body: some View {
        if isAsset {
            assetView
        } else {
            urlView
        }
    }

    @ViewBuilder
    private var assetView: some View {
        switch mode {
        case .fixed(let w, let h):
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                .frame(width: w, height: h)
                .clipped()
                .background(placeholder)
                .cornerRadius(cornerRadius)
        case .card(let ratio):
            let safeRatio = max(ratio, 0.1)
            GeometryReader { geometry in
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width * safeRatio)
                    .clipped()
            }
            .aspectRatio(1.0 / safeRatio, contentMode: .fit)
            .background(placeholder)
            .cornerRadius(cornerRadius)
        case .background:
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .background(placeholder)
                .cornerRadius(cornerRadius)
        }
    }

    @ViewBuilder
    private var urlView: some View {
        switch mode {
        case .fixed(let w, let h):
            RemoteImage.fixed(url: urlOrAsset, width: w, height: h)
                .contentMode(contentMode)
                .placeholder(placeholder)
                .cornerRadius(cornerRadius)
        case .card(let ratio):
            RemoteImage.card(url: urlOrAsset, aspectRatio: ratio)
                .contentMode(contentMode)
                .placeholder(placeholder)
                .cornerRadius(cornerRadius)
        case .background:
            RemoteImage.background(url: urlOrAsset)
                .contentMode(contentMode)
                .placeholder(placeholder)
                .cornerRadius(cornerRadius)
        }
    }
}

extension VisionImage {
    static func fixed(urlOrAsset: String, width: CGFloat, height: CGFloat) -> VisionImage {
        VisionImage(urlOrAsset: urlOrAsset, mode: .fixed(width: width, height: height))
    }

    static func card(urlOrAsset: String, aspectRatio ratio: CGFloat = 1.0) -> VisionImage {
        VisionImage(urlOrAsset: urlOrAsset, mode: .card(aspectRatio: ratio))
    }

    static func background(urlOrAsset: String) -> VisionImage {
        VisionImage(urlOrAsset: urlOrAsset, mode: .background)
    }

    func contentMode(_ value: RemoteImageContentMode) -> VisionImage {
        VisionImage(urlOrAsset: urlOrAsset, mode: mode, contentMode: value, placeholder: placeholder, cornerRadius: cornerRadius)
    }

    func placeholder(_ value: Color) -> VisionImage {
        VisionImage(urlOrAsset: urlOrAsset, mode: mode, contentMode: contentMode, placeholder: value, cornerRadius: cornerRadius)
    }
}
