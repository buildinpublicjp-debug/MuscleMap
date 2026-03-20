import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル — 実データ連動リデザイン）

struct PaywallView: View {
    var isHardPaywall: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showFreeOption = false

    private var localization: LocalizationManager { LocalizationManager.shared }

    private var isJapanese: Bool {
        localization.currentLanguage == .japanese
    }

    // MARK: - ルーティンデータ

    /// ルーティンから実データを取得
    private var routine: UserRoutine {
        RoutineManager.shared.routine
    }

    private var totalExercises: Int {
        routine.days.reduce(0) { $0 + $1.exercises.count }
    }

    /// 目標名を動的取得
    private var goalSubtitle: String? {
        guard let goalRaw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: goalRaw) else { return nil }
        return isJapanese
            ? "「\(goal.localizedName)」のために最適化"
            : "Optimized for \"\(goal.localizedName)\""
    }

    /// GIF付きプレビュー用の種目データ（最大4種目、exerciseId付き）
    private var previewExercises: [(id: String, name: String, detail: String)] {
        // ルーティンから種目を取得（重複除去）
        var exercises: [RoutineExercise] = []
        var seenIds: Set<String> = []
        for day in routine.days {
            for ex in day.exercises {
                if seenIds.insert(ex.exerciseId).inserted {
                    exercises.append(ex)
                }
                if exercises.count >= 4 { break }
            }
            if exercises.count >= 4 { break }
        }

        // フォールバック: ルーティンが空なら重点筋肉から取得
        if exercises.isEmpty {
            let priorityMuscles = AppState.shared.userProfile.goalPriorityMuscles
            var defs: [ExerciseDefinition] = []
            var addedIds: Set<String> = []
            for muscleId in priorityMuscles {
                if let muscle = Muscle(rawValue: muscleId) {
                    for ex in ExerciseStore.shared.exercises(targeting: muscle) {
                        if addedIds.insert(ex.id).inserted {
                            defs.append(ex)
                        }
                        if defs.count >= 4 { break }
                    }
                }
                if defs.count >= 4 { break }
            }
            if defs.isEmpty {
                defs = Array(ExerciseStore.shared.exercises.prefix(4))
            }
            return defs.prefix(4).map { ex in
                let name = isJapanese ? ex.nameJA : ex.nameEN
                return (id: ex.id, name: name, detail: sampleDetail(for: ex))
            }
        }

        return exercises.prefix(4).map { re in
            let def = ExerciseStore.shared.exercise(for: re.exerciseId)
            let name = def.map { isJapanese ? $0.nameJA : $0.nameEN } ?? re.exerciseId
            let detail = def.map { sampleDetail(for: $0) } ?? ""
            return (id: re.exerciseId, name: name, detail: detail)
        }
    }

    /// ルーティン内の残りの種目数（プレビュー4つ以降）
    private var remainingExerciseCount: Int {
        max(0, totalExercises - 4)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.mmBgSecondary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: isHardPaywall ? 24 : 40)

                    // 1. ヘッドライン（実データ駆動）
                    headlineSection

                    // 2. GIF付き2カラムグリッド
                    menuPreviewGrid

                    // 3. 価格セクション（ファーストビューに入るよう上に配置）
                    pricingSection

                    // 4. 機能リスト（3行に絞る）
                    featureListSection

                    // 5. 復元 + 無料オプション + 法的テキスト
                    footerSection
                }
                .padding(.bottom, 16)
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

    // MARK: - ヘッドライン（実データ駆動）

    private var headlineSection: some View {
        VStack(spacing: 8) {
            // 実データ駆動ヘッドライン
            if !routine.days.isEmpty && totalExercises > 0 {
                Text(isJapanese
                    ? "\(routine.days.count)日間 × \(totalExercises)種目の\nプログラムが待っています"
                    : "Your \(routine.days.count)-day, \(totalExercises)-exercise\nprogram is ready")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
                    .multilineTextAlignment(.center)
            } else {
                Text(isJapanese
                    ? "あなた専用のメニューを毎日届ける"
                    : "Your Personalized Menu, Every Day")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
                    .multilineTextAlignment(.center)
            }

            // 目標連動サブタイトル
            if let subtitle = goalSubtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmAccentPrimary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - GIF付き2カラムグリッド

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private var menuPreviewGrid: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(previewExercises.prefix(4).enumerated()), id: \.offset) { _, exercise in
                    ZStack(alignment: .bottom) {
                        // GIF or プレースホルダー
                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                            ExerciseGifView(exerciseId: exercise.id, size: .card)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.mmBgCard)
                                .aspectRatio(1, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                                )
                        }

                        // 種目名オーバーレイ
                        VStack(spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(exercise.detail)
                                .font(.system(size: 10).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // 「+他N種目」テキスト
            if remainingExerciseCount > 0 {
                Text(isJapanese
                    ? "+他\(remainingExerciseCount)種目"
                    : "+\(remainingExerciseCount) more exercises")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 価格セクション（コンパクト）

    private var pricingSection: some View {
        VStack(spacing: 8) {
            // 年額ボタン（推奨・大きく・31%OFFバッジ内蔵）
            Button {
                HapticManager.lightTap()
                purchase(productId: "yearly")
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isJapanese ? "7日間無料で始める" : "Start Free for 7 Days")
                            .font(.system(size: 18, weight: .bold))
                        Text("31%OFF")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmBgPrimary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(Color.mmBgPrimary)

                    Text(isJapanese ? "¥4,900/年（月¥408）" : "$39.99/year ($3.33/mo)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmBgPrimary.opacity(0.7))
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
                Text(isJapanese ? "¥590/月" : "$4.99/month")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
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
                .font(.system(size: 11))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Pro機能リスト（3行に絞る）

    private var featureListSection: some View {
        VStack(spacing: 10) {
            featureRow(
                icon: "sparkles",
                text: isJapanese ? "毎日のメニューを自動提案" : "Daily personalized workout suggestions"
            )
            featureRow(
                icon: "infinity",
                text: isJapanese ? "ワークアウト記録が無制限" : "Unlimited workout tracking"
            )
            featureRow(
                icon: "bell.badge.fill",
                text: isJapanese ? "筋肉が回復したら通知" : "Recovery notifications when muscles are ready"
            )
        }
        .padding(16)
        .background(Color.mmBgCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.mmTextPrimary)
            Spacer()
        }
    }

    // MARK: - フッター（復元 + 無料 + 法的テキスト）

    private var footerSection: some View {
        VStack(spacing: 8) {
            // 購入復元
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

            // 無料で続けるボタン（ハードPaywall用、3秒遅延表示）
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
            }

            // 法的リンク
            HStack(spacing: 16) {
                if let termsURL = URL(string: LegalURL.termsOfUse) {
                    Link(isJapanese ? "利用規約" : "Terms of Use", destination: termsURL)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                    Link(isJapanese ? "プライバシーポリシー" : "Privacy Policy", destination: privacyURL)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
            }

            // 法的テキスト
            Text(isJapanese
                ? "購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。"
                : "Payment will be charged to your Apple ID. Subscriptions automatically renew within 24 hours before expiration. You can turn off auto-renewal in your iTunes account settings.")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
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
        let equipment = exercise.equipment.lowercased()
        if equipment.contains("自重") || equipment.contains("bodyweight") {
            return isJapanese ? "自重 × 12 × 3" : "BW × 12 × 3"
        } else if equipment.contains("barbell") || equipment.contains("バーベル") {
            return "60kg × 8 × 3"
        } else if equipment.contains("dumbbell") || equipment.contains("ダンベル") {
            return "14kg × 10 × 3"
        } else {
            return "20kg × 12 × 3"
        }
    }
}

#Preview {
    PaywallView()
}
