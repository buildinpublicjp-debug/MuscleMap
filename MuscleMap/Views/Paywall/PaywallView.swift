import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル — 実データ連動）

struct PaywallView: View {
    var isHardPaywall: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showingError = false

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
        return "\(goal.localizedName)のためのメニュー"
    }

    /// メニュープレビュー用の種目データ
    private var previewExercises: [(name: String, detail: String)] {
        // ExerciseStoreから重点筋肉に関連する種目を取得
        let priorityMuscles = AppState.shared.userProfile.goalPriorityMuscles
        var exercises: [ExerciseDefinition] = []

        for muscleId in priorityMuscles {
            if let muscle = Muscle(rawValue: muscleId) {
                let targeting = ExerciseStore.shared.exercises(targeting: muscle)
                for ex in targeting where !exercises.contains(where: { $0.id == ex.id }) {
                    exercises.append(ex)
                    if exercises.count >= 3 { break }
                }
            }
            if exercises.count >= 3 { break }
        }

        // フォールバック: 重点筋肉がない場合は上位3種目
        if exercises.isEmpty {
            exercises = Array(ExerciseStore.shared.exercises.prefix(3))
        }

        return exercises.prefix(3).map { ex in
            let name = localization.currentLanguage == .japanese ? ex.nameJA : ex.nameEN
            // サンプルの重量・セット（プレビュー用）
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
                        Text("処理中...")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(32)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .alert("購入エラー", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "不明なエラーが発生しました。")
        }
        .interactiveDismissDisabled(isHardPaywall)
    }

    // MARK: - 筋肉マップセクション

    private var muscleMapSection: some View {
        MiniMuscleMapView(muscleMapping: goalMuscleMapping)
            .frame(height: 160)
            .padding(.horizontal, 60)
            .padding(.top, 8)
    }

    // MARK: - ヘッドライン

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text(isHardPaywall ? "あなた専用のプログラムを解放" : "あなた専用のメニューを毎日届ける")
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
            Text("今日のメニュー例")
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

    // MARK: - Pro機能リスト（3つのみ）

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureCheckRow("種目・重量・セット数の自動提案")
            featureCheckRow("強さレベル & Strength Map")
            featureCheckRow("レベルアップまでの距離表示")
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
                    Text("7日間無料で始める")
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
                        errorMessage = "復元できる購入履歴が見つかりませんでした。"
                        showingError = true
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        } label: {
            Text("購入を復元")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .disabled(PurchaseManager.shared.isLoading)
    }

    // MARK: - 法的表記

    private var legalText: some View {
        Text("購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。")
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
        if category.contains("compound") || category.contains("barbell") {
            return "60kg × 8 × 3"
        } else if category.contains("dumbbell") {
            return "12kg × 12 × 3"
        } else {
            return "20kg × 15 × 3"
        }
    }
}

#Preview {
    PaywallView()
}
