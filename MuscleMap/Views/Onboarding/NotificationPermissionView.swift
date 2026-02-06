import SwiftUI
import UserNotifications

// MARK: - 通知許可画面

struct NotificationPermissionView: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var bellBounce = false
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // アイコン
                ZStack {
                    // 外側のグロー
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.mmOnboardingAccent.opacity(0.3),
                                    Color.mmOnboardingAccent.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)

                    // 内側の円
                    Circle()
                        .fill(Color.mmOnboardingAccent.opacity(0.15))
                        .frame(width: 100, height: 100)

                    // ベルアイコン
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .offset(y: bellBounce ? -5 : 0)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

                Spacer().frame(height: 40)

                // タイトル
                Text(L10n.notificationTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer().frame(height: 12)

                // 説明
                Text(L10n.notificationDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
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
                            .background(Color.mmOnboardingAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text(L10n.allowNotifications)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.mmOnboardingAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
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
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            // Bell bounce animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.5)) {
                bellBounce = true
            }
        }
    }

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
