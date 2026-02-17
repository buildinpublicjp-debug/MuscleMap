import SwiftUI

// MARK: - 週間ストリークバッジ

struct WeeklyStreakBadge: View {
    let weeks: Int
    let isCurrentWeekCompleted: Bool

    @State private var glowAnimation = false

    private var showBadge: Bool {
        weeks > 0 || !isCurrentWeekCompleted
    }

    var body: some View {
        if showBadge {
            HStack(spacing: 8) {
                // 炎アイコン
                Image(systemName: "flame.fill")
                    .foregroundStyle(isCurrentWeekCompleted ? .orange : Color.mmTextSecondary)
                    .shadow(color: isCurrentWeekCompleted ? .orange.opacity(glowAnimation ? 0.6 : 0.2) : .clear, radius: glowAnimation ? 8 : 4)

                // テキスト
                if weeks > 0 {
                    Text(L10n.weekStreak(weeks))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                } else {
                    Text(L10n.noWorkoutThisWeek)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.mmBgCard)
            .clipShape(Capsule())
            .onAppear {
                if isCurrentWeekCompleted {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowAnimation = true
                    }
                }
            }
        }
    }
}

// MARK: - マイルストーン祝福画面

struct MilestoneView: View {
    let milestone: StreakMilestone
    let streakWeeks: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // サブタイトル
                Text(L10n.streakCongrats(streakWeeks))
                    .font(.title3)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer()

                // シェアボタン
                Button {
                    generateShareImage()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.shareAchievement)
                    }
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                // 閉じるボタン
                Button {
                    onDismiss()
                } label: {
                    Text(L10n.close)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            HapticManager.workoutEnded()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [L10n.milestoneShareText(streakWeeks, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func generateShareImage() {
        let shareCard = MilestoneShareCard(milestone: milestone, streakWeeks: streakWeeks)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - マイルストーンシェアカード

struct MilestoneShareCard: View {
    let milestone: StreakMilestone
    let streakWeeks: Int

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 80))

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                // ストリーク数
                Text(L10n.weekStreak(streakWeeks))
                    .font(.title2)
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                // フッター
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 390, height: 693)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }
}
