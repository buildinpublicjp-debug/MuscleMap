import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル — 1画面完結 + マーキーGIF）

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

    private var routine: UserRoutine {
        RoutineManager.shared.routine
    }

    private var totalExercises: Int {
        routine.days.reduce(0) { $0 + $1.exercises.count }
    }

    private var goalSubtitle: String? {
        guard let goalRaw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: goalRaw) else { return nil }
        return isJapanese
            ? "「\(goal.localizedName)」のために最適化"
            : "Optimized for \"\(goal.localizedName)\""
    }

    /// マーキー用の種目リスト（全種目、重複除去）
    private var marqueeExercises: [ExerciseDefinition] {
        var result: [ExerciseDefinition] = []
        var seenIds: Set<String> = []
        for day in routine.days {
            for ex in day.exercises {
                if seenIds.insert(ex.exerciseId).inserted,
                   let def = ExerciseStore.shared.exercise(for: ex.exerciseId) {
                    result.append(def)
                }
            }
        }

        // フォールバック: ルーティンが空なら重点筋肉 or 全種目から
        if result.isEmpty {
            let priorityMuscles = AppState.shared.userProfile.goalPriorityMuscles
            var addedIds: Set<String> = []
            for muscleId in priorityMuscles {
                if let muscle = Muscle(rawValue: muscleId) {
                    for ex in ExerciseStore.shared.exercises(targeting: muscle) {
                        if addedIds.insert(ex.id).inserted {
                            result.append(ex)
                        }
                        if result.count >= 12 { break }
                    }
                }
                if result.count >= 12 { break }
            }
            if result.isEmpty {
                result = Array(ExerciseStore.shared.exercises.prefix(12))
            }
        }

        return result
    }

    /// マーキー行1用（前半）
    private var marqueeRow1Exercises: [ExerciseDefinition] {
        let all = marqueeExercises
        let mid = (all.count + 1) / 2
        return Array(all.prefix(max(mid, 1)))
    }

    /// マーキー行2用（後半）
    private var marqueeRow2Exercises: [ExerciseDefinition] {
        let all = marqueeExercises
        let mid = (all.count + 1) / 2
        let second = Array(all.dropFirst(mid))
        return second.isEmpty ? all : second
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.mmBgSecondary.ignoresSafeArea()

            GeometryReader { geo in
                let h = geo.size.height
                let cardSize = min(max(h * 0.15, 110), 160)

                VStack(spacing: 0) {
                    Spacer().frame(height: isHardPaywall ? 16 : 28)

                    // 1. ヘッドライン
                    headlineSection

                    Spacer().frame(height: 4)

                    // 2. マーキーGIF（2行）
                    marqueeArea(cardSize: cardSize)

                    Spacer().frame(height: 12)

                    // 3. 価格セクション
                    pricingSection

                    Spacer().frame(height: 8)

                    // 4. 機能リスト（コンパクト横並び）
                    featureListSection

                    Spacer(minLength: 4)

                    // 5. フッター
                    footerSection
                }
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

    // MARK: - ヘッドライン（コンパクト2行）

    private var headlineSection: some View {
        VStack(spacing: 2) {
            if !routine.days.isEmpty && totalExercises > 0 {
                Text(isJapanese
                    ? "\(routine.days.count)日間 × \(totalExercises)種目の"
                    : "Your \(routine.days.count)-day, \(totalExercises)-exercise")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
                Text(isJapanese
                    ? "プログラムが待っています"
                    : "program is ready")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
            } else {
                Text(isJapanese
                    ? "あなた専用のメニューを毎日届ける"
                    : "Your Personalized Menu, Every Day")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
                    .multilineTextAlignment(.center)
            }

            if let subtitle = goalSubtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmAccentPrimary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - マーキーセクション（2行、レスポンシブカードサイズ）

    private func marqueeArea(cardSize: CGFloat) -> some View {
        VStack(spacing: 6) {
            PaywallMarqueeRow(exercises: marqueeRow1Exercises, cardSize: cardSize, speed: 25, reversed: false)
            PaywallMarqueeRow(exercises: marqueeRow2Exercises, cardSize: cardSize, speed: 20, reversed: true)
        }
    }

    // MARK: - 価格セクション

    private var pricingSection: some View {
        VStack(spacing: 6) {
            // 年額ボタン（推奨、目立たせる）
            Button {
                HapticManager.lightTap()
                purchase(productId: "yearly")
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isJapanese ? "7日間無料で始める" : "Start Free for 7 Days")
                            .font(.system(size: 18, weight: .heavy))
                        Text("31%OFF")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
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
                .background(
                    LinearGradient(
                        colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.mmAccentPrimary.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(PurchaseManager.shared.isLoading)

            // 月額ボタン
            Button {
                HapticManager.lightTap()
                purchase(productId: "monthly")
            } label: {
                Text(isJapanese ? "¥590/月" : "$4.99/month")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mmBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(PurchaseManager.shared.isLoading)

            Text(isJapanese ? "いつでもキャンセル可能" : "Cancel anytime")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Pro機能リスト（コンパクト横並び）

    private var featureListSection: some View {
        HStack(spacing: 0) {
            featureItem(icon: "sparkles", text: isJapanese ? "パーソナライズ" : "Personalized")
            featureItem(icon: "infinity", text: isJapanese ? "無制限記録" : "Unlimited")
            featureItem(icon: "flame.fill", text: isJapanese ? "回復通知" : "Recovery")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.mmBgCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmAccentPrimary)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - フッター

    private var footerSection: some View {
        VStack(spacing: 6) {
            // 復元 + 無料オプション（横並び）
            HStack(spacing: 16) {
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
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .disabled(PurchaseManager.shared.isLoading)

                if isHardPaywall && showFreeOption {
                    Button {
                        HapticManager.lightTap()
                        dismiss()
                    } label: {
                        Text(isJapanese ? "無料で今すぐ始める" : "Start Free Now")
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                    }
                    .transition(.opacity)
                }
            }

            // 法的リンク
            HStack(spacing: 16) {
                if let termsURL = URL(string: LegalURL.termsOfUse) {
                    Link(isJapanese ? "利用規約" : "Terms of Use", destination: termsURL)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                    Link(isJapanese ? "プライバシーポリシー" : "Privacy Policy", destination: privacyURL)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
            }

            // 法的テキスト
            Text(isJapanese
                ? "購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。"
                : "Payment will be charged to your Apple ID. Subscriptions automatically renew within 24 hours before expiration. You can turn off auto-renewal in your iTunes account settings.")
                .font(.system(size: 8))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
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
}

// MARK: - マーキー行（種目GIF自動横スクロール、レスポンシブカードサイズ）

private struct PaywallMarqueeRow: View {
    let exercises: [ExerciseDefinition]
    let cardSize: CGFloat
    let speed: CGFloat       // px/sec
    let reversed: Bool       // trueなら左→右に流れる

    @State private var offset: CGFloat = 0

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 1セット分の幅
    private var setWidth: CGFloat {
        CGFloat(exercises.count) * (cardSize + 8)
    }

    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 8) {
                // 3セット分並べて無限ループ感を確保
                ForEach(0..<3, id: \.self) { batch in
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        marqueeCard(exercise: exercise)
                            .id("\(batch)-\(index)")
                    }
                }
            }
            .offset(x: offset)
            .onAppear {
                guard setWidth > 0 else { return }
                // 開始位置: reversed の場合は左端、通常は1セット分右
                offset = reversed ? -setWidth : 0
                let duration = setWidth / speed
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = reversed ? 0 : -setWidth
                }
            }
        }
        .frame(height: cardSize)
        .clipped()
    }

    private func marqueeCard(exercise: ExerciseDefinition) -> some View {
        ZStack(alignment: .bottom) {
            // GIF or プレースホルダー
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ExerciseGifView(exerciseId: exercise.id, size: .card)
                    .scaledToFill()
                    .frame(width: cardSize, height: cardSize)
                    .clipped()
            } else {
                Color.mmBgCard
                    .frame(width: cardSize, height: cardSize)
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                    )
            }

            // 種目名（グラデーション付き）
            Text(isJapanese ? exercise.nameJA : exercise.nameEN)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: cardSize, height: cardSize)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PaywallView()
}
