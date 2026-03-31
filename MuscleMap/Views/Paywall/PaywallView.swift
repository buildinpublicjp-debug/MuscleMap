import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル — 1画面完結 + マーキーGIF）

struct PaywallView: View {
    var isHardPaywall: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showFreeOption = false

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var purchaseManager: PurchaseManager { PurchaseManager.shared }

    // MARK: - ルーティンデータ

    private var routine: UserRoutine {
        RoutineManager.shared.routine
    }

    private var totalExercises: Int {
        routine.days.reduce(0) { $0 + $1.exercises.count }
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
            // プレミアム背景グラデーション（上部ダークグリーン→ダーク）
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.12, blue: 0.08),
                    Color.mmBgSecondary
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Color.clear.frame(height: isHardPaywall ? 16 : 40)
                    headlineSection
                    marqueeArea(cardSize: 140)
                        .frame(height: 140 * 2 + 8)
                    valuePropsSection
                    featureListSection
                    pricingSection
                    footerSection
                    Color.clear.frame(height: 16)
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
                        .disabled(purchaseManager.isLoading)
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }

            // 購入中オーバーレイ
            if purchaseManager.isLoading {
                ZStack {
                    Color.mmBgPrimary.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(Color.mmAccentPrimary)
                        Text(L10n.pwProcessing)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(32)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .alert(L10n.purchaseError, isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? L10n.unknownError)
        }
        .interactiveDismissDisabled(isHardPaywall)
        .onAppear {
            // 動的価格を取得
            Task { await purchaseManager.fetchOfferings() }

            if isHardPaywall {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showFreeOption = true
                    }
                }
            }
        }
    }

    // MARK: - ヘッドライン（ミニマル洗練型）

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text("MUSCLEMAP PRO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mmAccentPrimary)
                .tracking(3)

            Text(L10n.pwHeadlineRecord)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if !routine.days.isEmpty && totalExercises > 0 {
                Text(L10n.pwPersonalPlan(routine.days.count, totalExercises))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - バリュープロップストリップ

    private var valuePropsSection: some View {
        HStack(spacing: 0) {
            valuePropItem(
                value: "∞",
                label: L10n.pwUnlimited
            )
            valuePropItem(
                value: "92",
                label: L10n.pwExerciseGIFs
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.mmBorder.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 24)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.mmBorder.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 24)
        }
    }

    private func valuePropItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.mmAccentPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - マーキーセクション（2行、レスポンシブカードサイズ）

    private func marqueeArea(cardSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            PaywallMarqueeRow(exercises: marqueeRow1Exercises, cardSize: cardSize, speed: 25, reversed: false)
                .frame(height: cardSize)
            PaywallMarqueeRow(exercises: marqueeRow2Exercises, cardSize: cardSize, speed: 20, reversed: true)
                .frame(height: cardSize)
        }
    }

    // MARK: - Free vs Pro 比較テーブル

    private var featureListSection: some View {
        VStack(spacing: 0) {
            // ヘッダー行
            HStack(spacing: 0) {
                Text(L10n.pwFeature)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(L10n.pwFree)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 52)

                Text("Pro")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(width: 52)
                    .padding(.vertical, 3)
                    .background(Color.mmAccentPrimary)
                    .clipShape(Capsule())
                    .shadow(color: Color.mmAccentPrimary.opacity(0.5), radius: 6, y: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)

            // セパレーター
            Rectangle()
                .fill(Color.mmBorder.opacity(0.3))
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            // 比較行（セパレーター付き）
            comparisonRow(
                feature: L10n.pwRecoveryMap,
                freeValue: .check, proValue: .check
            )
            comparisonSeparator
            comparisonRow(
                feature: L10n.pwWorkoutLog,
                freeValue: .limited(L10n.pwTwicePerWeek), proValue: .check
            )
            // 下部パディング
            Color.clear.frame(height: 4)
        }
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mmBorder.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
    }

    private var comparisonSeparator: some View {
        Rectangle()
            .fill(Color.mmBorder.opacity(0.2))
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }

    private enum ComparisonValue {
        case check, cross, limited(String), custom(String), muted(String)
    }

    private func comparisonRow(feature: String, freeValue: ComparisonValue, proValue: ComparisonValue) -> some View {
        HStack(spacing: 0) {
            Text(feature)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            comparisonCell(value: freeValue)
                .frame(width: 52)

            comparisonCell(value: proValue)
                .frame(width: 52)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func comparisonCell(value: ComparisonValue) -> some View {
        switch value {
        case .check:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)
        case .cross:
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        case .limited(let text):
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.mmWarning)
        case .custom(let text):
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)
        case .muted(let text):
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        }
    }

    // MARK: - 価格セクション（動的価格 — RevenueCatから取得）

    private var pricingSection: some View {
        VStack(spacing: 8) {
            // 月額ボタン（メインCTA — プレミアムグラデーション）
            Button {
                HapticManager.lightTap()
                purchase(productId: "monthly")
            } label: {
                Text(purchaseManager.monthlyButtonText)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 1.0, blue: 0.8),
                                Color.mmAccentPrimary,
                                Color(red: 0, green: 0.75, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.mmAccentPrimary.opacity(0.3), radius: 8, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isLoading)

            // 年額ボタン（サブ — 割引バッジ付き控えめデザイン）
            Button {
                HapticManager.lightTap()
                purchase(productId: "yearly")
            } label: {
                HStack(spacing: 8) {
                    Text(purchaseManager.yearlyPriceText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mmTextPrimary)

                    Spacer()

                    if let discount = purchaseManager.yearlyDiscountPercent {
                        Text(discount)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.mmAccentPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mmAccentPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.mmBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isLoading)

            Text(L10n.pwCancelAnytime)
                .font(.system(size: 10))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - フッター

    private var footerSection: some View {
        VStack(spacing: 5) {
            // 復元 + 無料オプション
            HStack(spacing: 16) {
                Button {
                    HapticManager.lightTap()
                    Task {
                        do {
                            let restored = try await PurchaseManager.shared.restore()
                            if restored {
                                dismiss()
                            } else {
                                errorMessage = L10n.pwNoRestorableFound
                                showingError = true
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                } label: {
                    Text(L10n.pwRestorePurchase)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .disabled(purchaseManager.isLoading)

                if isHardPaywall && showFreeOption {
                    Button {
                        HapticManager.lightTap()
                        dismiss()
                    } label: {
                        Text(L10n.pwStartFreeNow)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                    }
                    .transition(.opacity)
                }
            }

            // 法的リンク
            HStack(spacing: 16) {
                if let termsURL = URL(string: LegalURL.termsOfUse) {
                    Link(L10n.pwTermsOfUse, destination: termsURL)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                    Link(L10n.pwPrivacyPolicy, destination: privacyURL)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
            }

            // 法的テキスト
            Text(L10n.pwLegalText)
                .font(.system(size: 8))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
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
            Text(exercise.localizedName)
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
