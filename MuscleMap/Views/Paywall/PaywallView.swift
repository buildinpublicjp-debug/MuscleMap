import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル — 実データ連動）

struct PaywallView: View {
    var isHardPaywall: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showFreeOption = false

    private var localization: LocalizationManager { LocalizationManager.shared }

    /// ユーザーの重点筋肉をハイライトした筋肉マッピング
    private var goalMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        for muscleId in AppState.shared.userProfile.goalPriorityMuscles {
            mapping[muscleId] = 80
        }
        return mapping
    }

    /// 目標名を動的取得
    private var goalSubtitle: String? {
        guard let goalRaw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: goalRaw) else { return nil }
        return isJapanese
            ? "\(goal.localizedName)のためのメニュー"
            : "A menu designed for your goal"
    }

    private var isJapanese: Bool {
        localization.currentLanguage == .japanese
    }

    /// メニュープレビュー用の種目データ（primaryMuscleGroup重複回避）
    private var previewExercises: [(name: String, detail: String)] {
        let priorityMuscles = AppState.shared.userProfile.goalPriorityMuscles
        var exercises: [ExerciseDefinition] = []
        var addedPrimaryGroups: Set<String> = []

        for muscleId in priorityMuscles {
            if let muscle = Muscle(rawValue: muscleId) {
                let targeting = ExerciseStore.shared.exercises(targeting: muscle)
                for ex in targeting {
                    let primaryMuscle = ex.muscleMapping.max(by: { $0.value < $1.value })?.key ?? ""
                    if !exercises.contains(where: { $0.id == ex.id }) && !addedPrimaryGroups.contains(primaryMuscle) {
                        exercises.append(ex)
                        addedPrimaryGroups.insert(primaryMuscle)
                        if exercises.count >= 3 { break }
                    }
                }
            }
            if exercises.count >= 3 { break }
        }

        // フォールバック: 重点筋肉がない場合は上位3種目
        if exercises.isEmpty {
            exercises = Array(ExerciseStore.shared.exercises.prefix(3))
        }

        return exercises.prefix(3).map { ex in
            let name = isJapanese ? ex.nameJA : ex.nameEN
            let sampleDetails = sampleDetail(for: ex)
            return (name: name, detail: sampleDetails)
        }
    }

    var body: some View {
        ZStack {
            Color.mmBgSecondary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    muscleMapSection
                    headlineSection
                    menuPreviewSection
                    featureListSection
                    pricingSection
                    restoreButton
                    freeOptionButton
                    legalLinks
                    legalText
                }
                .padding(.vertical)
            }

            // 閉じるボタン（右上固定、ハードペイウォール時は非表示）
            if !isHardPaywall {
                VStack {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .disabled(PurchaseManager.shared.isLoading)
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }

            // 購入中オーバーレイ
            if PurchaseManager.shared.isLoading {
                ZStack {
                    Color.mmBgPrimary.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(Color.mmAccentPrimary)
                        Text(isJapanese ? "処理中..." : "Processing...")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(32)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .alert(isJapanese ? "購入エラー" : "Purchase Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? (isJapanese ? "不明なエラーが発生しました。" : "An unknown error occurred."))
        }
        .interactiveDismissDisabled(isHardPaywall)
        .onAppear {
            if isHardPaywall {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showFreeOption = true
                    }
                }
            }
        }
    }

    // MARK: - 筋肉マップセクション

    private var muscleMapSection: some View {
        MiniMuscleMapView(muscleMapping: goalMuscleMapping)
            .frame(height: 160)
            .padding(.horizontal, 60)
            .padding(.top, 8)
    }

    // MARK: - ヘッドライン

    private var headlineText: String {
        if isHardPaywall {
            return isJapanese
                ? "あなた専用のプログラムを解放"
                : "Unlock Your Custom Program"
        } else {
            return isJapanese
                ? "あなた専用のメニューを毎日届ける"
                : "Your Personalized Menu, Every Day"
        }
    }

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text(headlineText)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            if let subtitle = goalSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - メニュープレビュー

    private var menuPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isJapanese ? "今日のメニュー例" : "Today's Menu Example")
                .font(.caption.bold())
                .foregroundStyle(Color.mmAccentPrimary)

            Divider()
                .background(Color.mmTextSecondary.opacity(0.3))

            ForEach(Array(previewExercises.enumerated()), id: \.offset) { _, exercise in
                HStack {
                    Text(exercise.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(exercise.detail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            Divider()
                .background(Color.mmTextSecondary.opacity(0.3))
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    // MARK: - Pro機能リスト（初心者に刺さる順）

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureCheckRow(isJapanese ? "ワークアウト記録が無制限" : "Unlimited workout tracking")
            featureCheckRow(isJapanese ? "今日のメニューを毎日自動提案" : "Daily personalized workout suggestions")
            featureCheckRow(isJapanese ? "筋肉が回復したらお知らせ" : "Recovery notifications when muscles are ready")
            featureCheckRow(isJapanese ? "種目・重量・セット数の自動最適化" : "Auto-optimized exercises, weight & sets")
            featureCheckRow(isJapanese ? "Strength Map — 筋力を可視化" : "Strength Map — Visualize your power")
        }
        .padding(.horizontal, 32)
    }

    private func featureCheckRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextPrimary)
        }
    }

    // MARK: - 価格セクション

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // 年額ボタン（推奨・大きく）
            Button {
                HapticManager.lightTap()
                purchase(productId: "yearly")
            } label: {
                VStack(spacing: 6) {
                    Text(isJapanese ? "7日間無料で始める" : "Start Free for 7 Days")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmBgPrimary)

                    Text(yearlyPriceText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(PurchaseManager.shared.isLoading)

            // 年額の割安感
            Text(isJapanese
                ? "月額\(monthlyPriceText)が月¥408に — 31%お得"
                : "Save 31% vs monthly")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)

            // 月額ボタン（小さく）
            Button {
                HapticManager.lightTap()
                purchase(productId: "monthly")
            } label: {
                Text(monthlyPriceText)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mmBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(PurchaseManager.shared.isLoading)

            // いつでもキャンセル可能
            Text(isJapanese ? "いつでもキャンセル可能" : "Cancel anytime")
                .font(.system(size: 12))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    /// 年額の表示テキスト
    private var yearlyPriceText: String {
        "¥4,900/年（月¥408）"
    }

    /// 月額の表示テキスト
    private var monthlyPriceText: String {
        "¥590/月"
    }

    // MARK: - 購入復元

    private var restoreButton: some View {
        Button {
            HapticManager.lightTap()
            Task {
                do {
                    let restored = try await PurchaseManager.shared.restore()
                    if restored {
                        dismiss()
                    } else {
                        errorMessage = isJapanese
                            ? "復元できる購入履歴が見つかりませんでした。"
                            : "No restorable purchases were found."
                        showingError = true
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        } label: {
            Text(isJapanese ? "購入を復元" : "Restore Purchase")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .disabled(PurchaseManager.shared.isLoading)
    }

    // MARK: - 無料で続けるボタン（ハードPaywall用、3秒遅延表示）

    @ViewBuilder
    private var freeOptionButton: some View {
        if isHardPaywall && showFreeOption {
            Button {
                HapticManager.lightTap()
                dismiss()
            } label: {
                Text(isJapanese ? "無料で今すぐ始める" : "Start Free Now")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
            }
            .transition(.opacity)
            .padding(.top, 8)
        }
    }

    // MARK: - 利用規約/プライバシーポリシーリンク

    private var legalLinks: some View {
        HStack(spacing: 16) {
            if let termsURL = URL(string: LegalURL.termsOfUse) {
                Link(isJapanese ? "利用規約" : "Terms of Use", destination: termsURL)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
            }
            if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                Link(isJapanese ? "プライバシーポリシー" : "Privacy Policy", destination: privacyURL)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - 法的表記

    private var legalText: some View {
        Text(isJapanese
            ? "購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。"
            : "Payment will be charged to your Apple ID. Subscriptions automatically renew within 24 hours before expiration. You can turn off auto-renewal in your iTunes account settings.")
            .font(.caption2)
            .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
    }

    // MARK: - ヘルパー

    private func purchase(productId: String) {
        Task {
            do {
                let purchased = try await PurchaseManager.shared.purchase(productId: productId)
                if purchased {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.error()
            }
        }
    }

    /// 種目ごとのサンプル重量・レップ・セット（プレビュー用）
    private func sampleDetail(for exercise: ExerciseDefinition) -> String {
        let category = exercise.category.lowercased()
        let equipment = exercise.equipment.lowercased()
        if equipment.contains("自重") || equipment.contains("bodyweight") {
            return isJapanese ? "自重 × 12 × 3" : "BW × 12 × 3"
        } else if category.contains("compound") || category.contains("barbell") {
            return "60kg × 8 × 3"
        } else if category.contains("dumbbell") {
            return "14kg × 10 × 3"
        } else {
            return "20kg × 12 × 3"
        }
    }
}

#Preview {
    PaywallView()
}
