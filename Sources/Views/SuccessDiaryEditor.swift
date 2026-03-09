import SwiftUI

struct SuccessDiaryEditor: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = SuccessDiaryEditorViewModel()

    @State private var isCategoryModalPresented: Bool = false
    @State private var isDateModalPresented: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "记录今日成功", showBack: true)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppTheme.spacing.sectionVertical) {
                    SuccessDiaryEditorPuppyHero()
                    SuccessDiaryEditorTipLine()

                    SuccessDiaryEditorForm(
                        content: $viewModel.content,
                        contentCountText: viewModel.contentCountText,
                        isSubmitting: viewModel.isSubmitting,
                        categoryText: viewModel.categoryDisplayText,
                        dateText: viewModel.dateDisplayText,
                        validationError: viewModel.validationError,
                        onCategoryTap: { isCategoryModalPresented = true },
                        onDateTap: { isDateModalPresented = true },
                        onCancel: handleCancel,
                        onSave: { viewModel.save(router: router) }
                    )

                    Color.clear.frame(height: AppTheme.spacing.md)
                }
                .padding(.horizontal, AppTheme.spacing.screenHorizontal)
                .padding(.vertical, AppTheme.spacing.lg)
                .frame(maxWidth: AppTheme.spacing.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background)
        .overlay {
            SuccessDiaryEditorSelectModal(
                isPresented: $isCategoryModalPresented,
                title: "事件分类",
                isDisabled: viewModel.isSubmitting,
                content: {
                    VStack(spacing: 0) {
                        ForEach(SuccessDiaryEditorViewModel.SuccessDiaryEditorCategory.allCases, id: \.rawValue) { cat in
                            SuccessDiaryEditorSelectRow(
                                isSelected: viewModel.selectedCategory == cat,
                                iconName: viewModel.categoryIconName(cat),
                                title: viewModel.categoryLabel(cat),
                                onTap: {
                                    viewModel.selectedCategory = cat
                                    isCategoryModalPresented = false
                                }
                            )
                        }
                    }
                }
            )
        }
        .overlay {
            SuccessDiaryEditorSelectModal(
                isPresented: $isDateModalPresented,
                title: "事件日期",
                isDisabled: viewModel.isSubmitting,
                content: {
                    VStack(spacing: 0) {
                        ForEach(viewModel.dateRange, id: \.self) { date in
                            SuccessDiaryEditorSelectRow(
                                isSelected: viewModel.selectedDate == date,
                                iconName: nil,
                                title: SuccessDiaryEditorViewModel.displayText(for: date),
                                onTap: {
                                    viewModel.selectedDate = date
                                    isDateModalPresented = false
                                }
                            )
                        }
                    }
                }
            )
        }
        .onAppear { viewModel.onAppearResetForm() }
        .navigationBarBackButtonHidden(true)
    }

    private func handleCancel() {
        router.dismiss()
    }
}

private struct SuccessDiaryEditorPuppyHero: View {
    var body: some View {
        Image("diary_puppy")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 120, maxHeight: 96)
            .accessibilityLabel(Text("钱钱与你一起记录"))
    }
}

private struct SuccessDiaryEditorTipLine: View {
    var body: some View {
        Text("任何小事都算数，记下来就好。")
            .font(.system(size: 14))
            .foregroundColor(AppTheme.colors.onMuted)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct SuccessDiaryEditorForm: View {
    @Binding var content: String
    let contentCountText: String
    let isSubmitting: Bool
    let categoryText: String
    let dateText: String
    let validationError: String

    let onCategoryTap: () -> Void
    let onDateTap: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing.lg) {
            SuccessDiaryEditorTextareaSection(
                content: $content,
                contentCountText: contentCountText,
                isSubmitting: isSubmitting
            )

            SuccessDiaryEditorSelectField(
                title: "事件分类",
                valueText: categoryText,
                isDisabled: isSubmitting,
                onTap: onCategoryTap
            )

            SuccessDiaryEditorSelectField(
                title: "事件日期",
                valueText: dateText,
                isDisabled: isSubmitting,
                onTap: onDateTap
            )

            if !validationError.isEmpty {
                SuccessDiaryEditorErrorBanner(text: validationError)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            SuccessDiaryEditorActionRow(
                isSubmitting: isSubmitting,
                onCancel: onCancel,
                onSave: onSave
            )
            .padding(.top, AppTheme.spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.25), value: validationError)
    }
}

private struct SuccessDiaryEditorTextareaSection: View {
    @Binding var content: String
    let contentCountText: String
    let isSubmitting: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel("今日成功事件")
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)

            AppTextarea(text: $content, placeholder: "描述你今天做成的事情...")
                .minHeight(128)
                .disabled(isSubmitting)
                .borderColor(AppTheme.colors.border)
                .focusRingColor(AppTheme.colors.primary)
                .cornerRadius(AppTheme.radius.small)
                .textColor(AppTheme.colors.onSurface)
                .placeholderColor(AppTheme.colors.onMuted.opacity(0.7))

            Text(contentCountText)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
        }
    }
}

private struct SuccessDiaryEditorSelectField: View {
    let title: String
    let valueText: String
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel(title)
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)

            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(valueText.isEmpty ? "请选择" : valueText)
                        .font(.system(size: 14))
                        .foregroundColor(isDisabled ? AppTheme.colors.onMuted : AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.7)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    SafeIcon("ChevronDown", size: 16, color: AppTheme.colors.onMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(AppTheme.colors.surface)
                .cornerRadius(AppTheme.radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radius.small, style: .continuous)
                        .stroke(AppTheme.colors.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text(valueText))
        }
    }
}

private struct SuccessDiaryEditorErrorBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            SafeIcon("AlertCircle", size: 16, color: AppTheme.colors.error)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.error)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppTheme.colors.error.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                .stroke(AppTheme.colors.error.opacity(0.30), lineWidth: 1)
        )
        .cornerRadius(AppTheme.radius.standard)
    }
}

private struct SuccessDiaryEditorActionRow: View {
    let isSubmitting: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppButton("取消", action: onCancel)
                .variant(ButtonVariant.outline)
                .cornerRadius(AppTheme.radius.small)
                .disabled(isSubmitting)
                .frame(maxWidth: .infinity)

            AppButton(action: onSave) {
                HStack(spacing: 8) {
                    if isSubmitting {
                        SuccessDiaryEditorSpinner(size: 16, color: AppTheme.colors.onPrimary)
                    }
                    Text(isSubmitting ? "保存中..." : "保存并查看足迹")
                }
            }
            .backgroundColor(AppTheme.colors.primary)
            .foregroundColor(AppTheme.colors.onPrimary)
            .cornerRadius(AppTheme.radius.small)
            .disabled(isSubmitting)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SuccessDiaryEditorSpinner: View {
    let size: CGFloat
    let color: Color

    @State private var isAnimating: Bool = false

    var body: some View {
        SafeIcon("Loader2", size: size, color: color)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear { isAnimating = true }
            .animation(
                .linear(duration: 1).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .accessibilityHidden(true)
    }
}

private struct SuccessDiaryEditorSelectModal<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let isDisabled: Bool
    let content: Content

    init(
        isPresented: Binding<Bool>,
        title: String,
        isDisabled: Bool,
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.title = title
        self.isDisabled = isDisabled
        self.content = content()
    }

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.colors.onSurface)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer(minLength: 8)

                            AppButton(icon: "X", action: { isPresented = false })
                                .variant(ButtonVariant.ghost)
                                .size(ButtonSize.icon)
                                .height(36)
                                .cornerRadius(8)
                                .disabled(isDisabled)
                                .accessibilityLabel(Text("关闭"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        Divider()
                            .overlay(AppTheme.colors.border)
                    }

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            content
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 360)
                }
                .background(AppTheme.colors.surface)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.colors.border.opacity(0.7), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isPresented)
        }
    }
}

private struct SuccessDiaryEditorSelectRow: View {
    let isSelected: Bool
    let iconName: String?
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let iconName, !iconName.isEmpty {
                    SafeIcon(iconName, size: 16, color: AppTheme.colors.onSurface)
                        .frame(width: 20, alignment: .center)
                } else {
                    Color.clear.frame(width: 20, height: 16)
                }

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    SafeIcon("Check", size: 14, color: AppTheme.colors.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.colors.primary.opacity(0.10) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isSelected ? "已选择" : "未选择"))
    }
}