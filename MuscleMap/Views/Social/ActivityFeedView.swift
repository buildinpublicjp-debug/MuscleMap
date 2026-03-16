import SwiftUI

// MARK: - アクティビティフィード画面

/// フレンドのアクティビティをタイムライン形式で表示
struct ActivityFeedView: View {
    @State private var activities: [FriendActivity] = MockFriendData.generateMockFeed()
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Coming Soonバナー
                comingSoonBanner

                // フレンドを招待バナー
                inviteBanner

                // アクティビティカード一覧
                feedContent
            }
            .padding(.bottom, 32)
        }
        .background(Color.mmBgPrimary)
        .navigationTitle(L10n.feed)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [L10n.feedInviteMessage(AppConstants.appStoreURL)])
        }
    }

    // MARK: - Coming Soonバナー

    private var comingSoonBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(Color.mmAccentSecondary)

            Text(L10n.feedComingSoon)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mmAccentSecondary.opacity(0.08))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - フレンドを招待バナー

    private var inviteBanner: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.mmAccentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.feedInviteFriends)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.mmTextPrimary)

                    Text(L10n.feedInviteSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mmBgCard)
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - フィードコンテンツ

    private var feedContent: some View {
        ForEach(activities) { activity in
            FriendActivityCard(activity: activity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
    }
}

// MARK: - Preview

#Preview {
    ActivityFeedView()
}
