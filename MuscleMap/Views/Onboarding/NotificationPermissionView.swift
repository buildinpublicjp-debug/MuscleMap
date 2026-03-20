import SwiftUI
import UserNotifications

// MARK: - 通知許可画面

struct NotificationPermissionView: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var isRequesting = false
    @State private var animationPhase: Int = 0
    @State private var animationTimer: Timer?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 回復デモに使う筋肉（胸・三角筋前部・三頭筋）
    private let demoMuscles: [Muscle] = [.chestUpper, .chestLower, .deltoidAnterior, .triceps]

    /// フェーズに応じた筋肉マップ状態
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if demoMuscles.contains(muscle) {
                switch animationPhase {
                case 0: states[muscle] = .recovering(progress: 0.05)  // 赤
                case 1: states[muscle] = .recovering(progress: 0.5)   // 黄
                case 2: states[muscle] = .recovering(progress: 0.95)  // 緑
                default: states[muscle] = .inactive                   // 暗い
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

            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // 筋肉マップ（回復アニメーション）
                MuscleMapView(muscleStates: muscleStates)
                    .frame(height: 180)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)

                Spacer().frame(height: 24)

                // タイトル
                Text(L10n.notificationTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer().frame(height: 8)

                // 説明
                Text(L10n.notificationDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer().frame(height: 20)

                // 通知プレビューカード
                notificationPreviewCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer()

                // 通知を許可ボタン
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
                        Text(L10n.allowNotifications)
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
                .buttonStyle(.plain)
                .disabled(isRequesting)
                .padding(.horizontal, 24)

                // あとでボタン
                Button {
                    HapticManager.lightTap()
                    onComplete()
                } label: {
                    Text(L10n.maybeLater)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .disabled(isRequesting)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            // 1.2秒ごとにフェーズ切替（赤→黄→緑→暗い→赤→...）
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.8)) {
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

    // MARK: - 通知プレビューカード

    private var notificationPreviewCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmOnboardingAccent)
                Text("MuscleMap")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(isJapanese ? "たった今" : "Just now")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            Text(isJapanese
                ? "💪 大胸筋・三角筋 回復完了！"
                : "💪 Chest & Shoulders Recovered!")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)

            Text(isJapanese
                ? "プッシュの日です。トレーニングしよう！"
                : "Time for Push day. Let's train!")
                .font(.system(size: 13))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmOnboardingAccent.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - 通知リクエスト

    private func requestNotificationPermission() {
        isRequesting = true
        HapticManager.lightTap()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                // 結果に関わらずAppStateに保存
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
