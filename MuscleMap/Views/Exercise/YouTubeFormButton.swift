import SwiftUI

// MARK: - YouTube フォーム動画 独立行ボタン
//
// 種目詳細画面で「過去のあなた」セクションの直下、タグ行の直前に配置。
// 横幅は親の利用可能幅に追従、高さ 48pt の Capsule。

struct YouTubeFormButton: View {
    let exercise: ExerciseDefinition

    var body: some View {
        if let url = YouTubeSearchHelper.searchURL(for: exercise) {
            Button {
                HapticManager.lightTap()
                UIApplication.shared.open(url)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    Text(L10n.watchFormOnYouTube)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.mmDestructive)
                .clipShape(Capsule())
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.watchFormOnYouTube)
        }
    }
}
