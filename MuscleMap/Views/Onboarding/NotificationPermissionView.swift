import SwiftUI
import UserNotifications

// MARK: - 通知許可画面（「回復したら、教える。」体験）

struct NotificationPermissionView: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var isRequesting = false
    @State private var animationPhase: Int = 0
    @State private var animationTimer: Timer?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 回復デモに使う筋肉（グループA: 胸・肩、グループB: 背中・腕）
    private let groupA: [Muscle] = [.chestUpper, .chestLower, .deltoidAnterior, .deltoidLateral]
    private let groupB: [Muscle] = [.lats, .trapsUpper, .biceps, .triceps]

    /// フェーズに応じた筋肉マップ状態（2グループが時間差で回復）
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if groupA.contains(muscle) {
                switch animationPhase {
                case 0: states[muscle] = .recovering(progress: 0.05)  // 赤
                case 1: states[muscle] = .recovering(progress: 0.5)   // 黄
                case 2: states[muscle] = .recovering(progress: 0.95)  // 緑
                default: states[muscle] = .inactive
                }
            } else if groupB.contains(muscle) {
                // グループBは1フェーズ遅れで回復
                switch animationPhase {
                case 0: states[muscle] = .inactive
                case 1: states[muscle] = .recovering(progress: 0.05)  // 赤
                case 2: states[muscle] = .recovering(progress: 0.5)   // 黄
                default: states[muscle] = .recovering(progress: 0.95) // 緑
                }
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            GeometryReader { geo in
                let h = geo.size.height
                let mapHeight = min(max(h * 0.36, 220), 380)

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)

                        // ヘッドライン
                        Text(L10n.notifHeadline)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingAccent)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        Spacer().frame(height: 4)

                        // サブテキスト（刺激→回復→成長）
                        Text(L10n.notifSubheadline)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        Spacer().frame(height: 8)

                        // 筋肉マップ（回復アニメーション）
                        MuscleMapView(muscleStates: muscleStates)
                            .frame(height: mapHeight)
                            .padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.9)

                        Spacer().frame(height: 8)

                        // 成長サイクル 3ステップバッジ
                        growthCycleSteps
                            .opacity(appeared ? 1 : 0)

                        Spacer().frame(height: 20)

                        // 通知プレビューカード（回復通知×2）
                        VStack(spacing: 12) {
                            notificationCard(
                                subtitle: isJapanese ? "大胸筋・三角筋 回復完了！" : "Chest & Delts Recovered!",
                                body: isJapanese ? "プッシュの日です。トレーニングしよう！" : "Push day. Time to train!",
                                time: L10n.notifMockTime1,
                                isMain: true
                            )

                            notificationCard(
                                subtitle: isJapanese ? "背中・腕 回復完了！" : "Back & Arms Recovered!",
                                body: isJapanese ? "プルの日です。トレーニングしよう！" : "Pull day. Time to train!",
                                time: isJapanese ? "2時間前" : "2h ago"
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                        Spacer().frame(height: 20)
                    }
                }

                // 「成長を見逃さない」ボタン（固定下部）
                VStack(spacing: 0) {
                    Button {
                        requestNotificationPermission()
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .tint(Color.mmOnboardingBg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Text(L10n.notifEnableButton)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(isRequesting)
                    .padding(.horizontal, 24)

                    // あとでボタン
                    Button {
                        HapticManager.mediumTap()
                        onComplete()
                    } label: {
                        Text(L10n.maybeLater)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }
                    .disabled(isRequesting)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            } // GeometryReader
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            // 1.2秒ごとにフェーズ切替（赤→黄→緑→暗い→赤→...）
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 1.2)) {
                        animationPhase = (animationPhase + 1) % 4
                    }
                }
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    // MARK: - 成長サイクル 3ステップ

    private var growthCycleSteps: some View {
        HStack(spacing: 0) {
            stepBadge(icon: "flame.fill", text: L10n.notifStepStimulate, color: .mmMuscleCoral)

            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmOnboardingTextSub)

            stepBadge(icon: "clock.arrow.circlepath", text: L10n.notifStepRecover, color: .mmOnboardingAccent, isHighlighted: true)

            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmOnboardingTextSub)

            stepBadge(icon: "arrow.up.circle.fill", text: L10n.notifStepGrow, color: .mmAccentPrimary)
        }
    }

    private func stepBadge(icon: String, text: String, color: Color, isHighlighted: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: isHighlighted ? 14 : 12))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: isHighlighted ? 14 : 12, weight: .heavy))
                .foregroundStyle(color)
        }
        .padding(.horizontal, isHighlighted ? 14 : 10)
        .padding(.vertical, isHighlighted ? 7 : 5)
        .background(color.opacity(isHighlighted ? 0.2 : 0.12))
        .clipShape(Capsule())
        .overlay(
            isHighlighted
                ? Capsule().stroke(color.opacity(0.4), lineWidth: 1)
                : nil
        )
    }

    // MARK: - 通知プレビューカード

    private func notificationCard(subtitle: String, body: String, time: String, isMain: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: isMain ? 15 : 13))
                    .foregroundStyle(Color.mmOnboardingAccent)
                Text("MuscleMap")
                    .font(.system(size: isMain ? 15 : 13, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(time)
                    .font(.system(size: isMain ? 13 : 11))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            Text(subtitle)
                .font(.system(size: isMain ? 17 : 15, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)

            Text(body)
                .font(.system(size: isMain ? 15 : 13))
                .foregroundStyle(Color.mmOnboardingTextSub)
                .lineLimit(1)
        }
        .padding(isMain ? 18 : 14)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmOnboardingAccent.opacity(isMain ? 0.3 : 0.15), lineWidth: isMain ? 1.5 : 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - 通知リクエスト

    private func requestNotificationPermission() {
        isRequesting = true
        HapticManager.mediumTap()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                AppState.shared.isNotificationEnabled = granted
                isRequesting = false
                onComplete()
            }
        }
    }
}

#Preview {
    NotificationPermissionView(onComplete: {})
}
