import SwiftUI
import SwiftData

// MARK: - プログレスフォトギャラリー

struct ProgressPhotoGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.captureDate, order: .reverse)
    private var photos: [ProgressPhoto]

    @State private var selectedPhoto: ProgressPhoto?
    @State private var compareMode = false
    @State private var comparePhotos: [ProgressPhoto] = []
    @State private var showingDeleteAlert = false
    @State private var photoToDelete: ProgressPhoto?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            if photos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    // 比較モード切替
                    if photos.count >= 2 {
                        compareModeToggle
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // 3列グリッド
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photos) { photo in
                            photoThumbnail(photo)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle(isJapanese ? "体の記録" : "Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoFullScreenView(
                photos: photos,
                initialPhoto: photo,
                onDelete: { deleteTarget in
                    photoToDelete = deleteTarget
                    showingDeleteAlert = true
                }
            )
        }
        .sheet(isPresented: $compareMode) {
            if comparePhotos.count == 2 {
                BeforeAfterCompareView(
                    before: comparePhotos[0],
                    after: comparePhotos[1]
                )
            }
        }
        .alert(
            isJapanese ? "写真を削除" : "Delete Photo",
            isPresented: $showingDeleteAlert
        ) {
            Button(isJapanese ? "削除" : "Delete", role: .destructive) {
                if let photo = photoToDelete {
                    photo.deleteImageFile()
                    modelContext.delete(photo)
                    try? modelContext.save()
                    photoToDelete = nil
                }
            }
            Button(isJapanese ? "キャンセル" : "Cancel", role: .cancel) {
                photoToDelete = nil
            }
        } message: {
            Text(isJapanese ? "この写真を削除しますか？元に戻せません。" : "Delete this photo? This cannot be undone.")
        }
    }

    // MARK: - 空状態

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
            Text(isJapanese ? "まだ体の記録がありません" : "No progress photos yet")
                .font(.headline)
                .foregroundStyle(Color.mmTextSecondary)
            Text(isJapanese
                 ? "ワークアウト完了時に\n「体の記録を撮る」で撮影できます"
                 : "Take photos from the workout\ncompletion screen")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 比較モード切替

    private var compareModeToggle: some View {
        Button {
            HapticManager.lightTap()
            comparePhotos = []
            // 自動選択: 最新と最古
            if let oldest = photos.last, let newest = photos.first, oldest.id != newest.id {
                comparePhotos = [oldest, newest]
                compareMode = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.split.2x1")
                Text(isJapanese ? "Before / After 比較" : "Before / After Compare")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(Color.mmAccentPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.mmAccentPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - サムネイル

    private func photoThumbnail(_ photo: ProgressPhoto) -> some View {
        Button {
            selectedPhoto = photo
        } label: {
            GeometryReader { geo in
                if let url = photo.fullImageURL,
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.mmBgCard)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

// MARK: - フルスクリーン写真ビューア

struct PhotoFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [ProgressPhoto]
    let initialPhoto: ProgressPhoto
    let onDelete: (ProgressPhoto) -> Void

    @State private var currentIndex: Int = 0

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    photoPage(photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // オーバーレイUI
            VStack {
                // ヘッダー
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    // 日付
                    if currentIndex < photos.count {
                        Text(dateString(photos[currentIndex].captureDate))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // 削除
                    Button {
                        if currentIndex < photos.count {
                            let photo = photos[currentIndex]
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete(photo)
                            }
                        }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                // カウンター
                Text("\(currentIndex + 1) / \(photos.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            if let idx = photos.firstIndex(where: { $0.id == initialPhoto.id }) {
                currentIndex = idx
            }
        }
    }

    private func photoPage(_ photo: ProgressPhoto) -> some View {
        Group {
            if let url = photo.fullImageURL,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = isJapanese ? "yyyy年M月d日" : "MMM d, yyyy"
        fmt.locale = LocalizationManager.shared.currentLanguage.locale
        return fmt.string(from: date)
    }
}

// MARK: - Before / After 比較ビュー

struct BeforeAfterCompareView: View {
    @Environment(\.dismiss) private var dismiss
    let before: ProgressPhoto
    let after: ProgressPhoto

    @State private var sliderPosition: CGFloat = 0.5

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height

                    ZStack {
                        // After（右側 = 背景全体）
                        photoImage(after)
                            .frame(width: width, height: height)

                        // Before（左側 = スライダー位置でクリップ）
                        photoImage(before)
                            .frame(width: width, height: height)
                            .clipShape(
                                HorizontalClipShape(splitAt: sliderPosition * width)
                            )

                        // スライダーライン
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: height)
                            .position(x: sliderPosition * width, y: height / 2)
                            .shadow(color: .black.opacity(0.5), radius: 4)

                        // スライダーハンドル
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .position(x: sliderPosition * width, y: height / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        sliderPosition = min(max(value.location.x / width, 0.05), 0.95)
                                    }
                            )

                        // ラベル
                        VStack {
                            Spacer()
                            HStack {
                                Text("BEFORE")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding(.leading, 12)

                                Spacer()

                                Text("AFTER")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding(.trailing, 12)
                            }
                            .padding(.bottom, 24)
                        }

                        // 日付ラベル
                        VStack {
                            HStack {
                                dateLabel(before.captureDate)
                                    .padding(.leading, 12)
                                Spacer()
                                dateLabel(after.captureDate)
                                    .padding(.trailing, 12)
                            }
                            .padding(.top, 12)
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private func photoImage(_ photo: ProgressPhoto) -> some View {
        Group {
            if let url = photo.fullImageURL,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.mmBgCard
            }
        }
    }

    private func dateLabel(_ date: Date) -> some View {
        let fmt = DateFormatter()
        fmt.dateFormat = isJapanese ? "M/d" : "M/d"
        let text = fmt.string(from: date)
        return Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
    }
}

// MARK: - 水平クリップシェイプ

struct HorizontalClipShape: Shape {
    let splitAt: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: splitAt, height: rect.height))
        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProgressPhotoGalleryView()
    }
}
