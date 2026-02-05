import SwiftUI
import SafariServices

// MARK: - 法的文書URL

@MainActor
enum LegalURL {
    static let privacyPolicyJA = "https://buildinpublicjp-debug.github.io/MuscleMap/privacy-policy-ja.html"
    static let privacyPolicyEN = "https://buildinpublicjp-debug.github.io/MuscleMap/privacy-policy-en.html"
    static let termsJA = "https://buildinpublicjp-debug.github.io/MuscleMap/terms-of-use-ja.html"
    static let termsEN = "https://buildinpublicjp-debug.github.io/MuscleMap/terms-of-use-en.html"

    static var privacyPolicy: String {
        LocalizationManager.shared.currentLanguage == .japanese ? privacyPolicyJA : privacyPolicyEN
    }

    static var termsOfUse: String {
        LocalizationManager.shared.currentLanguage == .japanese ? termsJA : termsEN
    }
}

// MARK: - SafariView（SFSafariViewControllerラッパー）

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
