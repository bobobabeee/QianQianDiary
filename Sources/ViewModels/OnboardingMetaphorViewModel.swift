import SwiftUI

@MainActor
final class OnboardingMetaphorViewModel: ObservableObject {
    @Published var isExpanded: Bool = false

    let title: String = "甜甜圈的寓意"

    let donutImageUrl: String = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/a5c896d8-7399-4f5e-9893-a285aeac0d94.png"
    let coupleImageUrl: String = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/d8e6b386-c0bd-4837-9d4e-8f6e8eec8573.png"

    let donutHintText: String = "点击甜甜圈,聆听汉内坎普夫妇的智慧"
    let collapsedHintText: String = "点击上方甜甜圈,聆听夫妇的对话"
    let enterHomeButtonTitle: String = "进入我的生活"

    var dialogs: [String] {
        [
            "甜甜圈中间的圆孔代表着人类的内心,可是这内心本身却是无形的。",
            "许多人并不关心自己的内心,就是因为看不到它。对于他们来说,只有看得见的成功才是重要的。",
            "但你如果想要变得幸福,就不能只重视物质上的成功,还必须培养自己具有优秀的内心。",
            "没有圆圈也就没有圆孔。对于人们来说,它则意味着:绝不能忽视圆圈,否则的话内心也无法彰显出来。",
            "完满而幸福的人都是两者兼备的。"
        ]
    }

    func toggleExpanded() {
        isExpanded.toggle()
    }
}